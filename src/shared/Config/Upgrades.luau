--!strict
--[[
	Upgrade tracks. Each track has levels the player buys one at a time.
	Level 1 is what every player starts with (its Cost is ignored).

	The game reads a track's current Value through UpgradeService:GetValue(player, Id),
	so adding a new track (Luck, Speed, CoinMultiplier...) is: add it here, then read
	its value where it matters. The shop lists every track automatically.

	Id          Unique key saved in player data. Never rename once live.
	Name        Display name in the shop.
	Description Shown under the name.
	Unit        Text after the value, e.g. "slots".
	Levels      { Value, Cost, Currency? (default Coins), Name? }
]]

return {
	{
		Id = "Backpack",
		Name = "Backpack",
		Description = "Carry more creatures before you have to sell.",
		Unit = "slots",
		Levels = {
			{ Name = "Pouch", Value = 10, Cost = 0 },
			{ Name = "Satchel", Value = 20, Cost = 250 },
			{ Name = "Backpack", Value = 35, Cost = 1200 },
			{ Name = "Big Backpack", Value = 50, Cost = 5000 },
			{ Name = "Huge Backpack", Value = 75, Cost = 20000 },
			{ Name = "Giant Backpack", Value = 100, Cost = 80000 },
			{ Name = "Bottomless Bag", Value = 150, Cost = 250000 },
		},
	},
}
