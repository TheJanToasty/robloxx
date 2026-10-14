--!strict
--[[
	Builds the whole world from code when the server starts, using the builders in
	src/server/World and the numbers in Config/Map. Nothing about the map needs
	to be made by hand in Studio.

	The map appears when you press Play. In edit mode, Studio still shows your
	place as it was saved.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)
local World = script.Parent.Parent.World
local Decor = require(World.Decor)
local Environment = require(World.Environment)
local Ground = require(World.Ground)
local Plots = require(World.Plots)
local Pond = require(World.Pond)

export type Plot = Plots.Plot

local MapService = {}

local plots: { Plot } = {}
local hubSpawn: SpawnLocation

-- Studio's Baseplate template adds a huge baseplate that would cover the pond.
local function removeTemplateParts()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local part = Workspace:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part:Destroy()
			print(
				`[MapService] Removed the template "{name}" for this play session. Delete it from your place to silence this.`
			)
		end
	end
end

function MapService:Init()
	removeTemplateParts()

	local existing = Workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Map"

	Environment.Apply()
	Ground.Build(map)
	Pond.Build(map)
	plots = Plots.Build(map)
	hubSpawn = Decor.Build(map)

	-- Folder for fishing bobbers and lines.
	local fishing = Instance.new("Folder")
	fishing.Name = "Fishing"
	fishing.Parent = map

	map.Parent = Workspace
end

function MapService:GetPlots(): { Plot }
	return plots
end

function MapService:GetHubSpawn(): SpawnLocation
	return hubSpawn
end

-- Where the pond's water surface is, at its centre.
function MapService:GetPondCenter(): Vector3
	return Vector3.new(0, MapConfig.WaterSurfaceY, 0)
end

function MapService:GetFishingFolder(): Folder
	return (Workspace :: any).Map.Fishing
end

return MapService
