--!strict
--[[
	Builds a fishing rod Tool from a rod's config. The rod is made from parts so
	no uploaded models are needed. To use a custom model later, put a Tool named
	after the rod's Id in ReplicatedStorage.Assets.Rods; it must have a part named
	"Handle" containing an Attachment named "LineAttachment" at the rod tip.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(script.Parent.Catalog)

type Rod = Catalog.Rod

local RodModel = {}

local POLE_LENGTH = 7
-- Angle the rod is held at, above horizontal.
local HOLD_ANGLE = math.rad(50)
-- Distance from the butt of the rod to the hand.
local HAND_FROM_BUTT = 0.8

local function weld(part: BasePart, to: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = to
	constraint.Part1 = part
	constraint.Parent = part
end

local function decoration(properties: { [string]: any }): Part
	local part = Instance.new("Part")
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in properties do
		(part :: any)[key] = value
	end
	return part
end

local function findCustomModel(rod: Rod): Tool?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local rods = assets and assets:FindFirstChild("Rods")
	local custom = rods and rods:FindFirstChild(rod.Id)
	if custom and custom:IsA("Tool") then
		return custom:Clone()
	end
	return nil
end

local function buildTool(rod: Rod): Tool
	local look = rod.Look
	local tool = Instance.new("Tool")
	tool.Name = rod.Name
	tool.ToolTip = rod.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	-- The handle is the pole itself, running along its own Z axis.
	local handle = decoration({
		Name = "Handle",
		Size = Vector3.new(0.3, 0.3, POLE_LENGTH),
		Color = look.Pole,
		Material = look.Material or Enum.Material.SmoothPlastic,
	})
	handle.Parent = tool

	local half = POLE_LENGTH / 2

	local grip = decoration({
		Name = "Grip",
		Size = Vector3.new(0.45, 0.45, 1.6),
		Color = look.Accent,
		Material = Enum.Material.SmoothPlastic,
	})
	grip.CFrame = handle.CFrame * CFrame.new(0, 0, -half + 0.9)
	grip.Parent = tool
	weld(grip, handle)

	local reel = decoration({
		Name = "Reel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 0.9, 0.9),
		Color = look.Accent,
		Material = Enum.Material.SmoothPlastic,
	})
	reel.CFrame = handle.CFrame * CFrame.new(0.4, 0, -half + 2)
	reel.Parent = tool
	weld(reel, handle)

	local tip = decoration({
		Name = "Tip",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.35, 0.35, 0.35),
		Color = look.Accent,
		Material = look.Tip or Enum.Material.SmoothPlastic,
	})
	tip.CFrame = handle.CFrame * CFrame.new(0, 0, half)
	tip.Parent = tool
	weld(tip, handle)

	local lineAttachment = Instance.new("Attachment")
	lineAttachment.Name = "LineAttachment"
	lineAttachment.Position = Vector3.new(0, 0, half)
	lineAttachment.Parent = handle

	-- Hold the rod near its butt, pointing up and forward.
	-- In grip space +Y is up and -Z is forward, so the pole's +Z axis goes there.
	local pointing = Vector3.new(0, math.sin(HOLD_ANGLE), -math.cos(HOLD_ANGLE))
	local right = Vector3.new(1, 0, 0)
	local up = pointing:Cross(right)
	local handleInGrip = CFrame.fromMatrix(pointing * (half - HAND_FROM_BUTT), right, up, pointing)
	tool.Grip = handleInGrip:Inverse()

	return tool
end

-- A new Tool for this rod, tagged with its RodId attribute.
function RodModel.Build(rod: Rod): Tool
	local tool = findCustomModel(rod) or buildTool(rod)
	tool.Name = rod.Name
	tool:SetAttribute("RodId", rod.Id)
	return tool
end

return RodModel
