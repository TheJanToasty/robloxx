--!strict
--[[
	The maths of catching: which creatures a rod can catch, how likely each one is,
	and what a catch weighs and is worth.

	The server uses this to roll catches. The client can use the same functions to
	show odds in the UI, but the client never decides what was caught.
]]

local Catalog = require(script.Parent.Catalog)

type Creature = Catalog.Creature
type Rod = Catalog.Rod

export type PoolEntry = {
	Creature: Creature,
	Weight: number,
}

local CatchMath = {}

-- Every creature this rod can catch at this player level, with its boosted weight.
function CatchMath.GetPool(rod: Rod, playerLevel: number): ({ PoolEntry }, number)
	local pool: { PoolEntry } = {}
	local total = 0
	for _, creature in Catalog.Creatures.List do
		if (creature.RequiredPower or 0) > rod.Power then
			continue
		end
		if (creature.RequiredLevel or 0) > playerLevel then
			continue
		end
		local tier = Catalog.Rarities.ByName[creature.Rarity].Tier
		local weight = creature.CatchWeight * (1 + rod.Luck) ^ (tier - 1)
		table.insert(pool, { Creature = creature, Weight = weight })
		total += weight
	end
	return pool, total
end

-- Picks one creature from the pool. Returns nil only if the pool is empty.
function CatchMath.Roll(rod: Rod, playerLevel: number, rng: Random): Creature?
	local pool, total = CatchMath.GetPool(rod, playerLevel)
	if total <= 0 then
		return nil
	end
	local pick = rng:NextNumber() * total
	for _, entry in pool do
		pick -= entry.Weight
		if pick <= 0 then
			return entry.Creature
		end
	end
	return pool[#pool].Creature
end

-- Heavier catches are rarer: the roll leans towards the minimum weight.
function CatchMath.RollWeight(creature: Creature, rng: Random): number
	local range = creature.Weight
	local t = rng:NextNumber() ^ 1.6
	local weight = range.Min + (range.Max - range.Min) * t
	return math.floor(weight * 100 + 0.5) / 100
end

-- Coins for one catch: 75% of SellValue at minimum weight up to 125% at maximum.
function CatchMath.GetValue(creature: Creature, weight: number): number
	local range = creature.Weight
	local t = if range.Max > range.Min then math.clamp((weight - range.Min) / (range.Max - range.Min), 0, 1) else 0.5
	return math.max(1, math.floor(creature.SellValue * (0.75 + 0.5 * t) + 0.5))
end

return CatchMath
