--!strict
--[[
	The creature Index: every species a player has ever caught, saved for good.
	Phase 2 adds the Index screen; for now catches are recorded so nothing is lost.
]]

local DataService = require(script.Parent.DataService)

local IndexService = {}

-- Records a catch. Returns true if this is the first time the player caught this creature.
function IndexService:Record(player: Player, creatureId: string, weight: number): boolean
	local data = DataService:GetData(player)
	if not data then
		return false
	end

	local entry = data.Index[creatureId]
	local isNew = entry == nil
	if entry then
		entry.Caught += 1
		entry.Heaviest = math.max(entry.Heaviest, weight)
	else
		data.Index[creatureId] = {
			Caught = 1,
			FirstCaught = os.time(),
			Heaviest = weight,
		}
	end
	DataService:Replicate(player, "Index")
	return isNew
end

function IndexService:HasDiscovered(player: Player, creatureId: string): boolean
	local data = DataService:GetData(player)
	return data ~= nil and data.Index[creatureId] ~= nil
end

return IndexService
