--!strict
-- Trees, lamp posts, the hedge around the edge of the map, and the fallback spawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)
local Build = require(script.Parent.Build)
local Layout = require(script.Parent.Layout)

local Decor = {}

local function buildTree(parent: Instance, position: Vector3, rng: Random)
	local colors = MapConfig.Colors
	local scale = rng:NextNumber(0.85, 1.3)
	local leaves = colors.Leaves[rng:NextInteger(1, #colors.Leaves)]
	local trunkHeight = math.floor(7 * scale + 0.5)
	local spin = CFrame.Angles(0, rng:NextNumber(0, math.pi / 2), 0)
	local base = CFrame.new(position) * spin

	local model = Build.Model("Tree", parent)
	Build.Studded({
		Name = "Trunk",
		Color = colors.Trunk,
		Size = Vector3.new(2, trunkHeight, 2),
		CFrame = base * CFrame.new(0, trunkHeight / 2, 0),
		Parent = model,
	})
	local lowerSize = math.floor(9 * scale + 0.5)
	Build.Studded({
		Name = "Leaves",
		Color = leaves,
		Size = Vector3.new(lowerSize, 5, lowerSize),
		CFrame = base * CFrame.new(0, trunkHeight + 2.5, 0),
		Parent = model,
	})
	local upperSize = math.max(lowerSize - 4, 3)
	Build.Studded({
		Name = "Leaves",
		Color = Build.Shade(leaves, -0.12),
		Size = Vector3.new(upperSize, 3, upperSize),
		CFrame = base * CFrame.new(0, trunkHeight + 6.5, 0),
		Parent = model,
	})
end

local function buildTrees(parent: Instance)
	local folder = Build.Folder("Trees", parent)
	local rng = Random.new(2024)
	local half = MapConfig.GroundSize / 2
	local plotOuter = MapConfig.PlotRingRadius + MapConfig.PlotSize / 2 * math.sqrt(2) + 8

	-- A jittered grid of trees in the outer area, beyond the plots.
	local spacing = 26
	for x = -half + 14, half - 14, spacing do
		for z = -half + 14, half - 14, spacing do
			local position = Vector3.new(x + rng:NextNumber(-6, 6), 0, z + rng:NextNumber(-6, 6))
			local distance = Layout.HorizontalDistance(position, Vector3.zero)
			local inBounds = math.abs(position.X) < half - 8 and math.abs(position.Z) < half - 8
			if distance > plotOuter and inBounds then
				buildTree(folder, position, rng)
			end
		end
	end

	-- One tree between each pair of plots.
	local step = 2 * math.pi / MapConfig.PlotCount
	for index = 1, MapConfig.PlotCount do
		local angle = Layout.PlotAngle(index) + step / 2
		buildTree(folder, Layout.RingPoint(angle, MapConfig.PlotRingRadius, 0), rng)
	end
end

local function buildLamps(parent: Instance)
	local folder = Build.Folder("Lamps", parent)
	local radius = MapConfig.PondRadius + MapConfig.BeachWidth + 3
	local step = 2 * math.pi / MapConfig.PlotCount
	for index = 1, MapConfig.PlotCount do
		local angle = Layout.PlotAngle(index) + step / 2
		local position = Layout.RingPoint(angle, radius, 0)
		local model = Build.Model("Lamp", folder)
		Build.Studded({
			Name = "Base",
			Color = Color3.fromRGB(70, 70, 84),
			Size = Vector3.new(2, 1, 2),
			Position = position + Vector3.new(0, 0.5, 0),
			Parent = model,
		})
		Build.Part({
			Name = "Pole",
			Color = Color3.fromRGB(70, 70, 84),
			Size = Vector3.new(0.6, 8, 0.6),
			Position = position + Vector3.new(0, 5, 0),
			Parent = model,
		})
		local bulb = Build.Part({
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = MapConfig.Colors.Lamp,
			Size = Vector3.new(1.8, 1.8, 1.8),
			Position = position + Vector3.new(0, 9.6, 0),
			CanCollide = false,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 1.2
		light.Color = MapConfig.Colors.Lamp
		light.Parent = bulb
	end
end

local function buildHedge(parent: Instance)
	local folder = Build.Folder("Hedge", parent)
	local half = MapConfig.GroundSize / 2
	local thickness = 4
	local height = 5
	local wallHeight = 60
	local sides = {
		{ Vector3.new(0, 0, -half + thickness / 2), Vector3.new(MapConfig.GroundSize, 0, thickness) },
		{ Vector3.new(0, 0, half - thickness / 2), Vector3.new(MapConfig.GroundSize, 0, thickness) },
		{ Vector3.new(-half + thickness / 2, 0, 0), Vector3.new(thickness, 0, MapConfig.GroundSize - thickness * 2) },
		{ Vector3.new(half - thickness / 2, 0, 0), Vector3.new(thickness, 0, MapConfig.GroundSize - thickness * 2) },
	}
	for _, side in sides do
		local center, size = side[1], side[2]
		Build.Studded({
			Name = "Hedge",
			Color = MapConfig.Colors.Hedge,
			Size = Vector3.new(size.X, height, size.Z),
			Position = center + Vector3.new(0, height / 2, 0),
			Parent = folder,
		})
		-- Invisible wall above the hedge so nobody can jump off the map.
		Build.Part({
			Name = "Barrier",
			Transparency = 1,
			CanQuery = false,
			Size = Vector3.new(size.X, wallHeight, size.Z),
			Position = center + Vector3.new(0, height + wallHeight / 2, 0),
			Parent = folder,
		})
	end
end

-- Used when every plot is taken.
local function buildHubSpawn(parent: Instance): SpawnLocation
	local step = 2 * math.pi / MapConfig.PlotCount
	local position = Layout.RingPoint(step / 2, MapConfig.PondRadius + MapConfig.BeachWidth + 12, 0.2)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Plastic
	spawn.Color = Color3.fromRGB(250, 250, 250)
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Size = Vector3.new(8, 0.4, 8)
	spawn.CFrame = Layout.FacingPond(position)
	spawn.Parent = parent
	return spawn
end

function Decor.Build(parent: Instance): SpawnLocation
	local folder = Build.Folder("Decor", parent)
	buildTrees(folder)
	buildLamps(folder)
	buildHedge(folder)
	return buildHubSpawn(folder)
end

return Decor
