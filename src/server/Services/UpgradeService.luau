--!strict
--[[
	Reads and raises upgrade levels defined in Config/Upgrades.

		UpgradeService:GetValue(player, "Backpack") --> 10, 20, 35...

	Buying goes through ShopService, which charges the player and then calls Raise.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Modules.Catalog)
local DataService = require(script.Parent.DataService)

type UpgradeLevel = Catalog.UpgradeLevel

local UpgradeService = {}

function UpgradeService:GetLevel(player: Player, trackId: string): number
	local data = DataService:GetData(player)
	return if data then data.Upgrades[trackId] or 1 else 1
end

-- The value of the player's current level. Falls back to level 1 before data loads.
function UpgradeService:GetValue(player: Player, trackId: string): number
	local track = Catalog.Upgrades.ById[trackId]
	assert(track, `Unknown upgrade "{trackId}"`)
	local level = math.clamp(UpgradeService:GetLevel(player, trackId), 1, #track.Levels)
	return track.Levels[level].Value
end

-- The next level to buy, or nil if the track is maxed.
function UpgradeService:GetNextLevel(player: Player, trackId: string): (number?, UpgradeLevel?)
	local track = Catalog.Upgrades.ById[trackId]
	if not track then
		return nil, nil
	end
	local nextLevel = UpgradeService:GetLevel(player, trackId) + 1
	local info = track.Levels[nextLevel]
	if not info then
		return nil, nil
	end
	return nextLevel, info
end

-- Moves the player up one level. Does not charge them; ShopService does that first.
function UpgradeService:Raise(player: Player, trackId: string): boolean
	local data = DataService:GetData(player)
	local nextLevel = UpgradeService:GetNextLevel(player, trackId)
	if not data or not nextLevel then
		return false
	end
	data.Upgrades[trackId] = nextLevel
	DataService:Replicate(player, "Upgrades")
	return true
end

return UpgradeService
