--!strict
--[[
	Builds the 8 player plots around the pond. Each plot has a studded base, a
	low border, an entrance arch with the owner's name, a spawn pad, a Sell stand
	and a Shop stand, plus a path towards the pond.

	Plot-local space: origin at the centre of the plot's top surface, -Z (forward)
	points at the pond.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)
local Build = require(script.Parent.Build)
local Layout = require(script.Parent.Layout)

export type Plot = {
	Index: number,
	Model: Model,
	-- Centre of the plot's top surface, facing the pond.
	CFrame: CFrame,
	Spawn: SpawnLocation,
	SellPrompt: ProximityPrompt,
	ShopPrompt: ProximityPrompt,
	SignLabel: TextLabel,
}

local Plots = {}

local BASE_HEIGHT = 1

local function buildStall(
	parent: Instance,
	frame: CFrame,
	name: string,
	label: string,
	accent: Color3,
	actionText: string
): ProximityPrompt
	local model = Build.Model(name, parent)
	local wood = Color3.fromRGB(186, 134, 86)

	local counter = Build.Studded({
		Name = "Counter",
		Color = wood,
		Size = Vector3.new(8, 3, 3),
		CFrame = frame * CFrame.new(0, 1.5, 0),
		Parent = model,
	})
	Build.Studded({
		Name = "CounterTop",
		Color = accent,
		Size = Vector3.new(8.6, 0.4, 3.6),
		CFrame = frame * CFrame.new(0, 3.2, 0),
		Parent = model,
	})
	for _, side in { -1, 1 } do
		Build.Part({
			Name = "Post",
			Color = Build.Shade(wood, 0.2),
			Size = Vector3.new(0.6, 6, 0.6),
			CFrame = frame * CFrame.new(side * 3.9, 6.4, 1.2),
			Parent = model,
		})
	end
	Build.Studded({
		Name = "Roof",
		Color = accent,
		Size = Vector3.new(9.6, 0.8, 5),
		CFrame = frame * CFrame.new(0, 9.8, 0.4),
		Parent = model,
	})
	local sign = Build.Part({
		Name = "Sign",
		Color = Build.Shade(accent, 0.25),
		Size = Vector3.new(7, 1.8, 0.3),
		CFrame = frame * CFrame.new(0, 8.3, -1.9),
		Parent = model,
	})
	Build.SignText(sign, Enum.NormalId.Front, label)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	return prompt
end

local function buildPlot(parent: Instance, index: number): Plot
	local angle = Layout.PlotAngle(index)
	local size = MapConfig.PlotSize
	local half = size / 2
	local color = MapConfig.PlotColors[(index - 1) % #MapConfig.PlotColors + 1]
	local trim = Build.Shade(color, 0.25)

	local center = Layout.RingPoint(angle, MapConfig.PlotRingRadius, BASE_HEIGHT)
	local frame = Layout.FacingPond(center)

	local model = Build.Model(`Plot{index}`, parent)
	model:SetAttribute("PlotIndex", index)
	model:SetAttribute("OwnerUserId", 0)

	local base = Build.Studded({
		Name = "Base",
		Color = color,
		Size = Vector3.new(size, BASE_HEIGHT, size),
		CFrame = frame * CFrame.new(0, -BASE_HEIGHT / 2, 0),
		Parent = model,
	})
	model.PrimaryPart = base

	-- Low border, with a gap at the front for the entrance.
	local border = 1.6
	local gap = 12
	local function borderPart(x: number, z: number, sx: number, sz: number)
		Build.Studded({
			Name = "Border",
			Color = trim,
			Size = Vector3.new(sx, 0.8, sz),
			CFrame = frame * CFrame.new(x, 0.4, z),
			Parent = model,
		})
	end
	borderPart(0, half - border / 2, size, border)
	borderPart(-half + border / 2, 0, border, size - border * 2)
	borderPart(half - border / 2, 0, border, size - border * 2)
	local frontPiece = (size - gap) / 2
	borderPart(-half + frontPiece / 2, -half + border / 2, frontPiece, border)
	borderPart(half - frontPiece / 2, -half + border / 2, frontPiece, border)

	-- Entrance arch with the owner's name.
	for _, side in { -1, 1 } do
		Build.Studded({
			Name = "ArchPost",
			Color = Color3.fromRGB(245, 245, 245),
			Size = Vector3.new(1.4, 10, 1.4),
			CFrame = frame * CFrame.new(side * (gap / 2 + 0.7), 5, -half + border / 2),
			Parent = model,
		})
	end
	local signBoard = Build.Studded({
		Name = "Sign",
		Color = trim,
		Size = Vector3.new(gap + 4.4, 3, 1),
		CFrame = frame * CFrame.new(0, 11.5, -half + border / 2),
		Parent = model,
	})
	local signLabel = Build.SignText(signBoard, Enum.NormalId.Front, "Free Plot")
	-- The back of the sign mirrors the front so it reads from inside the plot too.
	local backLabel = Build.SignText(signBoard, Enum.NormalId.Back, "Free Plot")
	signLabel:GetPropertyChangedSignal("Text"):Connect(function()
		backLabel.Text = signLabel.Text
	end)

	-- Spawn pad near the back, facing the pond.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Plastic
	spawn.Color = Color3.fromRGB(250, 250, 250)
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = frame * CFrame.new(0, 0.2, half - 10)
	spawn.Parent = model

	local sellPrompt = buildStall(
		model,
		frame * CFrame.new(-11, 0, -half + 9),
		"SellStand",
		"SELL",
		Color3.fromRGB(76, 200, 110),
		"Sell All"
	)
	sellPrompt:SetAttribute("Action", "Sell")
	local shopPrompt = buildStall(
		model,
		frame * CFrame.new(11, 0, -half + 9),
		"ShopStand",
		"SHOP",
		Color3.fromRGB(64, 156, 255),
		"Open Shop"
	)
	shopPrompt:SetAttribute("Action", "Shop")

	-- Stone path from the entrance towards the beach.
	local pathStart = MapConfig.PlotRingRadius - half
	local pathEnd = MapConfig.PondRadius + MapConfig.BeachWidth
	local pathLength = pathStart - pathEnd
	Build.Studded({
		Name = "Path",
		Color = MapConfig.Colors.Path,
		Size = Vector3.new(gap - 2, 0.4, pathLength),
		CFrame = Layout.FacingPond(Layout.RingPoint(angle, pathEnd + pathLength / 2, 0.2)),
		Parent = model,
	})

	return {
		Index = index,
		Model = model,
		CFrame = frame,
		Spawn = spawn,
		SellPrompt = sellPrompt,
		ShopPrompt = shopPrompt,
		SignLabel = signLabel,
	}
end

function Plots.Build(parent: Instance): { Plot }
	local folder = Build.Folder("Plots", parent)
	local plots = {}
	for index = 1, MapConfig.PlotCount do
		plots[index] = buildPlot(folder, index)
	end
	return plots
end

return Plots
