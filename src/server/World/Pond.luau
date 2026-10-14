--!strict
--[[
	The central pond: Terrain water (so it has real waves and reflections) in a
	sandy basin, fishing docks facing each plot, lily pads and floating sparkles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)
local Build = require(script.Parent.Build)
local Layout = require(script.Parent.Layout)

local Pond = {}

local function buildWater()
	local terrain = Workspace.Terrain
	local radius = MapConfig.PondRadius
	local surface = MapConfig.WaterSurfaceY
	local depth = MapConfig.WaterDepth
	local groundBottom = -MapConfig.GroundThickness

	-- Clear any terrain under the map (e.g. from a terrain template), then dig the pond.
	local size = MapConfig.GroundSize + 16
	terrain:FillBlock(CFrame.new(0, -20, 0), Vector3.new(size, 48, size), Enum.Material.Air)

	-- Sandy basin under the ground and below the water.
	local basinBottom = surface - depth - 4
	local basinHeight = groundBottom - basinBottom
	terrain:FillCylinder(
		CFrame.new(0, basinBottom + basinHeight / 2, 0),
		basinHeight,
		radius + MapConfig.BeachWidth + 4,
		Enum.Material.Sand
	)

	terrain:FillCylinder(CFrame.new(0, surface - depth / 2, 0), depth, radius, Enum.Material.Water)

	terrain.WaterColor = MapConfig.Colors.Water
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.35
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 12
end

local function buildDock(parent: Instance, index: number)
	local angle = Layout.PlotAngle(index)
	local radius = MapConfig.PondRadius
	local length = MapConfig.DockLength
	local width = MapConfig.DockWidth
	local colors = MapConfig.Colors

	-- The dock starts a little on land and reaches `length` studs over the water.
	local outer = radius + 4
	local inner = radius - length
	local center = Layout.RingPoint(angle, (outer + inner) / 2, -0.3)
	local frame = Layout.FacingPond(center)

	local model = Build.Model(`Dock{index}`, parent)
	Build.Studded({
		Name = "Deck",
		Color = colors.Dock,
		Size = Vector3.new(width, 1, outer - inner),
		CFrame = frame,
		Parent = model,
	})

	-- Posts at the water end, sticking up a little like a railing.
	local postHeight = 8
	for _, side in { -1, 1 } do
		Build.Part({
			Name = "Post",
			Shape = Enum.PartType.Cylinder,
			Color = colors.DockPost,
			Size = Vector3.new(postHeight, 1.2, 1.2),
			CFrame = frame
				* CFrame.new(side * (width / 2 - 0.6), 1.5 - postHeight / 2, -(outer - inner) / 2 + 0.6)
				* CFrame.Angles(0, 0, math.pi / 2),
			Parent = model,
		})
	end
end

local function buildLilyPads(parent: Instance)
	local rng = Random.new(7)
	local radius = MapConfig.PondRadius
	local folder = Build.Folder("LilyPads", parent)
	for i = 1, 14 do
		local angle = rng:NextNumber(0, 2 * math.pi)
		-- Keep lily pads away from the docks so they don't block casting.
		local dockSpacing = 2 * math.pi / MapConfig.PlotCount
		local offset = (angle % dockSpacing) / dockSpacing
		if offset < 0.2 or offset > 0.8 then
			angle += dockSpacing * 0.5
		end
		local distance = rng:NextNumber(radius * 0.45, radius * 0.85)
		local size = rng:NextNumber(3, 5)
		Build.Decoration({
			Name = `LilyPad{i}`,
			Shape = Enum.PartType.Cylinder,
			Color = MapConfig.Colors.LilyPad,
			Size = Vector3.new(0.2, size, size),
			CFrame = CFrame.new(Layout.RingPoint(angle, distance, MapConfig.WaterSurfaceY + 0.1))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), math.pi / 2),
			Parent = folder,
		})
	end
end

local function buildSparkles(parent: Instance)
	-- An invisible slab over the water that gives off slow, floating sparkles.
	local span = MapConfig.PondRadius * 1.35
	local emitterPart = Build.Decoration({
		Name = "Sparkles",
		Transparency = 1,
		Size = Vector3.new(span, 0.2, span),
		Position = Vector3.new(0, MapConfig.WaterSurfaceY + 0.5, 0),
		Parent = parent,
	})

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 8
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(20, 20)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 250, 255))
	emitter.Parent = emitterPart
end

function Pond.Build(parent: Instance)
	local folder = Build.Folder("Pond", parent)
	buildWater()
	local docks = Build.Folder("Docks", folder)
	for index = 1, MapConfig.PlotCount do
		buildDock(docks, index)
	end
	buildLilyPads(folder)
	buildSparkles(folder)
end

return Pond
