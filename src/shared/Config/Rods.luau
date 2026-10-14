--!strict
--[[
	Fishing rods, in shop order. To add a rod, copy an entry and change it.

	Id            Unique key saved in player data. Never rename an Id once the game is live.
	Name          Display name.
	Rarity        One of the names in Config/Rarities (for colour in the shop).
	Cost          Price in Currency (Coins if Currency is left out). 0 = starter rod.
	Power         Unlocks creatures whose RequiredPower is at or below this.
	Luck          Boosts rarer tiers. Each tier's chance is multiplied by (1 + Luck) per tier
	              above Common, so Luck 0.5 makes Rare (2 tiers up) 2.25x more likely.
	Speed         Bites come this many times faster. 1 = normal.
	CastDistance  How far the bobber lands in front of you, in studs.
	Look          Colours for the generated rod model.
]]

return {
	{
		Id = "BasicRod",
		Name = "Basic Rod",
		Rarity = "Common",
		Cost = 0,
		Power = 1,
		Luck = 0,
		Speed = 1,
		CastDistance = 20,
		Look = { Pole = Color3.fromRGB(160, 110, 70), Accent = Color3.fromRGB(70, 70, 80) },
		Description = "Trusty and a little wobbly.",
	},
	{
		Id = "SturdyRod",
		Name = "Sturdy Rod",
		Rarity = "Uncommon",
		Cost = 300,
		Power = 2,
		Luck = 0.25,
		Speed = 1.1,
		CastDistance = 22,
		Look = { Pole = Color3.fromRGB(90, 170, 90), Accent = Color3.fromRGB(240, 240, 240) },
		Description = "Strong enough to land Rare creatures.",
	},
	{
		Id = "CoralRod",
		Name = "Coral Rod",
		Rarity = "Rare",
		Cost = 2000,
		Power = 3,
		Luck = 0.5,
		Speed = 1.2,
		CastDistance = 24,
		Look = { Pole = Color3.fromRGB(255, 120, 120), Accent = Color3.fromRGB(70, 180, 255) },
		Description = "Unlocks Epic creatures.",
	},
	{
		Id = "StormRod",
		Name = "Storm Rod",
		Rarity = "Epic",
		Cost = 12000,
		Power = 4,
		Luck = 0.9,
		Speed = 1.35,
		CastDistance = 26,
		Look = {
			Pole = Color3.fromRGB(60, 64, 90),
			Accent = Color3.fromRGB(255, 230, 80),
			Tip = Enum.Material.Neon,
		},
		Description = "Unlocks Legendary creatures.",
	},
	{
		Id = "GoldenRod",
		Name = "Golden Rod",
		Rarity = "Legendary",
		Cost = 60000,
		Power = 5,
		Luck = 1.4,
		Speed = 1.5,
		CastDistance = 28,
		Look = {
			Pole = Color3.fromRGB(255, 196, 40),
			Accent = Color3.fromRGB(255, 255, 255),
			Material = Enum.Material.Foil,
			Tip = Enum.Material.Neon,
		},
		Description = "Unlocks Mythic creatures.",
	},
	{
		Id = "CosmicRod",
		Name = "Cosmic Rod",
		Rarity = "Mythic",
		Cost = 300000,
		Power = 5,
		Luck = 2.2,
		Speed = 1.75,
		CastDistance = 30,
		Look = {
			Pole = Color3.fromRGB(40, 30, 100),
			Accent = Color3.fromRGB(140, 220, 255),
			Tip = Enum.Material.Neon,
		},
		Description = "Hums with starlight. The luckiest rod there is.",
	},
}
