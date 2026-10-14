--!strict
--[[
	Typed, indexed access to everything in Config. Also checks the config when the
	game starts, so a typo like Rarity = "Rarre" shows a clear error in Output
	instead of breaking fishing later.

		Catalog.Creatures.ById["Twiggle"]
		Catalog.Rods.List[1]
		Catalog.Rarities.ByName["Epic"].Tier
]]

local Config = script.Parent.Parent.Config

export type Rarity = {
	Name: string,
	Color: Color3,
	Announce: boolean?,
	Tier: number,
}

export type CreatureLook = {
	Body: Color3,
	Snout: Color3,
	Scale: number?,
	Material: Enum.Material?,
	Glow: Color3?,
	Crown: boolean?,
	Sparkles: boolean?,
}

export type Creature = {
	Id: string,
	Name: string,
	Rarity: string,
	SellValue: number,
	CatchWeight: number,
	Weight: { Min: number, Max: number },
	RequiredPower: number?,
	RequiredLevel: number?,
	Model: string?,
	Look: CreatureLook,
	Description: string?,
}

export type RodLook = {
	Pole: Color3,
	Accent: Color3,
	Material: Enum.Material?,
	Tip: Enum.Material?,
}

export type Rod = {
	Id: string,
	Name: string,
	Rarity: string,
	Cost: number,
	Currency: string?,
	Power: number,
	Luck: number,
	Speed: number,
	CastDistance: number,
	Look: RodLook,
	Description: string?,
	Order: number,
}

export type UpgradeLevel = {
	Value: number,
	Cost: number,
	Currency: string?,
	Name: string?,
}

export type UpgradeTrack = {
	Id: string,
	Name: string,
	Description: string?,
	Unit: string?,
	Levels: { UpgradeLevel },
}

export type Currency = {
	Id: string,
	Name: string,
	Color: Color3,
	Default: number,
}

local function index<T>(list: { T }, label: string): { [string]: T }
	local byId = {}
	for position, entry in list do
		local id = (entry :: any).Id
		assert(type(id) == "string" and id ~= "", `{label} #{position} is missing an Id`)
		assert(byId[id] == nil, `{label} Id "{id}" is used twice`)
		byId[id] = entry
	end
	return byId
end

-- Rarities ------------------------------------------------------------------

local rarityList: { Rarity } = require(Config.Rarities) :: any
local raritiesByName: { [string]: Rarity } = {}
for tier, rarity in rarityList do
	rarity.Tier = tier
	raritiesByName[rarity.Name] = rarity
end

-- Currencies ----------------------------------------------------------------

local currencyList: { Currency } = require(Config.Currencies) :: any
local currenciesById = index(currencyList, "Currency")

local function checkCurrency(currency: string?, label: string)
	if currency ~= nil then
		assert(currenciesById[currency], `{label} uses unknown currency "{currency}"`)
	end
end

-- Creatures -----------------------------------------------------------------

local creatureList: { Creature } = require(Config.Creatures) :: any
local creaturesById = index(creatureList, "Creature")
for _, creature in creatureList do
	local label = `Creature "{creature.Id}"`
	assert(raritiesByName[creature.Rarity], `{label} has unknown rarity "{creature.Rarity}"`)
	assert(creature.SellValue >= 0, `{label} has a negative SellValue`)
	assert(creature.CatchWeight > 0, `{label} needs a CatchWeight above 0`)
	assert(creature.Weight.Max >= creature.Weight.Min, `{label} has Weight.Max below Weight.Min`)
	assert(creature.Look and creature.Look.Body and creature.Look.Snout, `{label} needs Look.Body and Look.Snout`)
end

-- Rods ----------------------------------------------------------------------

local rodList: { Rod } = require(Config.Rods) :: any
local rodsById = index(rodList, "Rod")
for order, rod in rodList do
	rod.Order = order
	local label = `Rod "{rod.Id}"`
	assert(raritiesByName[rod.Rarity], `{label} has unknown rarity "{rod.Rarity}"`)
	assert(rod.Speed > 0, `{label} needs a Speed above 0`)
	checkCurrency(rod.Currency, label)
end
assert(
	rodList[1] and rodList[1].Cost == 0,
	"The first rod in Config/Rods must be free (Cost = 0); it is the starter rod"
)

-- Upgrades ------------------------------------------------------------------

local upgradeList: { UpgradeTrack } = require(Config.Upgrades) :: any
local upgradesById = index(upgradeList, "Upgrade")
for _, track in upgradeList do
	assert(#track.Levels >= 1, `Upgrade "{track.Id}" needs at least one level`)
	for level, info in track.Levels do
		checkCurrency(info.Currency, `Upgrade "{track.Id}" level {level}`)
	end
end

return {
	Rarities = { List = rarityList, ByName = raritiesByName },
	Currencies = { List = currencyList, ById = currenciesById },
	Creatures = { List = creatureList, ById = creaturesById },
	Rods = { List = rodList, ById = rodsById, Starter = rodList[1] },
	Upgrades = { List = upgradeList, ById = upgradesById },
}
