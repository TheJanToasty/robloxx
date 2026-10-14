--!strict
--[[
	The studded ground: a square of grass with a sandy beach ring and a round hole
	for the pond. The round parts are made of thin strips, which gives a blocky,
	classic-Roblox shoreline. Every strip edge is on a whole-stud boundary so the
	studs line up across parts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapConfig = require(ReplicatedStorage.Shared.Config.Map)
local Build = require(script.Parent.Build)

local Ground = {}

function Ground.Build(parent: Instance)
	local folder = Build.Folder("Ground", parent)

	local half = MapConfig.GroundSize / 2
	local thickness = MapConfig.GroundThickness
	local strip = MapConfig.StripSize
	local pondRadius = MapConfig.PondRadius
	local beachRadius = pondRadius + MapConfig.BeachWidth
	local colors = MapConfig.Colors

	local function slab(name: string, color: Color3, x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 <= 0 or z1 - z0 <= 0 then
			return
		end
		Build.Studded({
			Name = name,
			Color = color,
			Size = Vector3.new(x1 - x0, thickness, z1 - z0),
			Position = Vector3.new((x0 + x1) / 2, -thickness / 2, (z0 + z1) / 2),
			Parent = folder,
		})
	end

	-- Half-width of a circle at a strip, measured at the strip's outer edge so the
	-- ground slightly overhangs the circle rather than leaving gaps.
	local function halfWidth(radius: number, z0: number, z1: number): number
		local far = math.max(math.abs(z0), math.abs(z1))
		if far >= radius then
			return 0
		end
		return math.sqrt(radius * radius - far * far)
	end

	local band = math.ceil(beachRadius / strip) * strip

	-- Plain grass north and south of the pond.
	slab("Grass", colors.Grass, -half, half, -half, -band)
	slab("Grass", colors.Grass, -half, half, band, half)

	-- Strips across the pond: grass | sand | water | sand | grass
	for z0 = -band, band - strip, strip do
		local z1 = z0 + strip
		local hole = math.floor(halfWidth(pondRadius, z0, z1) / strip) * strip
		local beach = math.max(math.floor(halfWidth(beachRadius, z0, z1) / strip + 0.5) * strip, hole)

		if beach == 0 then
			slab("Grass", colors.Grass, -half, half, z0, z1)
		else
			slab("Grass", colors.Grass, -half, -beach, z0, z1)
			slab("Grass", colors.Grass, beach, half, z0, z1)
			if hole == 0 then
				slab("Sand", colors.Sand, -beach, beach, z0, z1)
			else
				slab("Sand", colors.Sand, -beach, -hole, z0, z1)
				slab("Sand", colors.Sand, hole, beach, z0, z1)
			end
		end
	end
end

return Ground
