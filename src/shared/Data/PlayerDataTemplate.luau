--!strict
--[[
	The shape of every player's saved data, and the values a new player starts with.

	Adding a field: add it to the PlayerData type and to New() below. Existing saves
	get the new field automatically the next time they load (DataService fills in
	anything missing). Never rename or remove a field once the game is live; old
	saves still have it.
]]

local Catalog = require(script.Parent.Parent.Modules.Catalog)

export type InventoryItem = {
	Id: number,
	CreatureId: string,
	Weight: number,
}

export type IndexEntry = {
	Caught: number,
	FirstCaught: number,
	Heaviest: number,
}

export type PlayerData = {
	DataVersion: number,
	Currencies: { [string]: number },
	Level: number,
	XP: number,
	EquippedRod: string,
	OwnedRods: { [string]: boolean },
	RodUpgrades: { [string]: number },
	Upgrades: { [string]: number },
	Inventory: {
		NextId: number,
		Items: { InventoryItem },
	},
	Index: { [string]: IndexEntry },
	Rebirths: number,
	Stats: {
		TotalCaught: number,
		CoinsEarned: number,
	},
	-- Set by DataService while a server is using this save. Never sent to clients.
	SessionLock: { JobId: string, Time: number }?,
}

local PlayerDataTemplate = {}

-- Bump this and add a migration in DataService if a field ever has to change meaning.
PlayerDataTemplate.Version = 1

-- Only these top-level fields are sent to the owning player's client.
PlayerDataTemplate.ReplicatedKeys = {
	"Currencies",
	"Level",
	"XP",
	"EquippedRod",
	"OwnedRods",
	"RodUpgrades",
	"Upgrades",
	"Inventory",
	"Index",
	"Rebirths",
	"Stats",
}

function PlayerDataTemplate.New(): PlayerData
	local currencies = {}
	for _, currency in Catalog.Currencies.List do
		currencies[currency.Id] = currency.Default
	end

	local upgrades = {}
	for _, track in Catalog.Upgrades.List do
		upgrades[track.Id] = 1
	end

	local starterRod = Catalog.Rods.Starter.Id

	return {
		DataVersion = PlayerDataTemplate.Version,
		Currencies = currencies,
		Level = 1,
		XP = 0,
		EquippedRod = starterRod,
		OwnedRods = { [starterRod] = true },
		RodUpgrades = {},
		Upgrades = upgrades,
		Inventory = {
			NextId = 1,
			Items = {},
		},
		Index = {},
		Rebirths = 0,
		Stats = {
			TotalCaught = 0,
			CoinsEarned = 0,
		},
	}
end

return PlayerDataTemplate
