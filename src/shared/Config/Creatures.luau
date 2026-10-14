--!strict
--[[
	Every creature that can be caught. To add one, copy an entry and change it.
	The fishing system reads this list, nothing else needs editing.

	Id            Unique key saved in player data. Never rename an Id once the game is live.
	Name          Display name.
	Rarity        One of the names in Config/Rarities.
	SellValue     Coins for an average-weight catch. Heavier catches are worth more.
	CatchWeight   Relative chance. 20 is twice as likely as 10. Rod Luck boosts rarer tiers.
	Weight        Min/Max weight in kg, rolled on each catch.
	RequiredPower Optional. The rod's Power must be at least this to catch it.
	RequiredLevel Optional. Player level needed (levels arrive in Phase 2).
	Model         Optional. Name of a model in ReplicatedStorage.Assets.Creatures to use
	              instead of the generated one, once you make custom models.
	Look          Colours and extras for the generated weevil model.
	Description   Flavour text for the Index.
]]

return {
	-- Common ---------------------------------------------------------------
	{
		Id = "MudnoseWeevil",
		Name = "Mudnose Weevil",
		Rarity = "Common",
		SellValue = 5,
		CatchWeight = 40,
		Weight = { Min = 0.3, Max = 0.9 },
		Look = { Body = Color3.fromRGB(141, 96, 62), Snout = Color3.fromRGB(96, 64, 42) },
		Description = "Loves rolling in the muddy shallows.",
	},
	{
		Id = "PebbleSnout",
		Name = "Pebble Snout",
		Rarity = "Common",
		SellValue = 6,
		CatchWeight = 35,
		Weight = { Min = 0.4, Max = 1.1 },
		Look = { Body = Color3.fromRGB(150, 154, 166), Snout = Color3.fromRGB(104, 108, 120) },
		Description = "Often mistaken for a very confused rock.",
	},
	{
		Id = "Twiggle",
		Name = "Twiggle",
		Rarity = "Common",
		SellValue = 8,
		CatchWeight = 30,
		Weight = { Min = 0.2, Max = 0.6 },
		Look = { Body = Color3.fromRGB(176, 204, 92), Snout = Color3.fromRGB(122, 150, 58), Scale = 0.85 },
		Description = "Thin as a twig and twice as wiggly.",
	},

	-- Uncommon -------------------------------------------------------------
	{
		Id = "Bubblebeak",
		Name = "Bubblebeak",
		Rarity = "Uncommon",
		SellValue = 18,
		CatchWeight = 14,
		Weight = { Min = 0.6, Max = 1.6 },
		Look = { Body = Color3.fromRGB(122, 204, 244), Snout = Color3.fromRGB(70, 150, 210) },
		Description = "Blows bubbles when it's happy. It's always happy.",
	},
	{
		Id = "MossbackWeevil",
		Name = "Mossback Weevil",
		Rarity = "Uncommon",
		SellValue = 22,
		CatchWeight = 12,
		Weight = { Min = 0.8, Max = 2.0 },
		Look = { Body = Color3.fromRGB(78, 140, 70), Snout = Color3.fromRGB(120, 92, 60), Scale = 1.1 },
		Description = "Grows a tiny garden on its back.",
	},
	{
		Id = "PuddleHopper",
		Name = "Puddle Hopper",
		Rarity = "Uncommon",
		SellValue = 25,
		CatchWeight = 10,
		Weight = { Min = 0.5, Max = 1.4 },
		Look = { Body = Color3.fromRGB(255, 150, 90), Snout = Color3.fromRGB(220, 100, 60) },
		Description = "Can jump three lily pads in a single bound.",
	},

	-- Rare -----------------------------------------------------------------
	{
		Id = "LilypadLurker",
		Name = "Lilypad Lurker",
		Rarity = "Rare",
		SellValue = 70,
		CatchWeight = 6,
		Weight = { Min = 1.2, Max = 3.0 },
		RequiredPower = 2,
		Look = { Body = Color3.fromRGB(56, 172, 96), Snout = Color3.fromRGB(255, 130, 180), Scale = 1.15 },
		Description = "Hides under lily pads and waits for snacks.",
	},
	{
		Id = "SapphireSnoot",
		Name = "Sapphire Snoot",
		Rarity = "Rare",
		SellValue = 90,
		CatchWeight = 4.5,
		Weight = { Min = 1.0, Max = 2.6 },
		RequiredPower = 2,
		Look = {
			Body = Color3.fromRGB(40, 92, 226),
			Snout = Color3.fromRGB(120, 200, 255),
			Material = Enum.Material.Glass,
		},
		Description = "Its shell sparkles like a gemstone in the sun.",
	},

	-- Epic -----------------------------------------------------------------
	{
		Id = "Thunderhorn",
		Name = "Thunderhorn",
		Rarity = "Epic",
		SellValue = 300,
		CatchWeight = 1.6,
		Weight = { Min = 2.0, Max = 5.0 },
		RequiredPower = 3,
		Look = {
			Body = Color3.fromRGB(252, 222, 60),
			Snout = Color3.fromRGB(60, 60, 80),
			Glow = Color3.fromRGB(255, 240, 120),
			Scale = 1.25,
		},
		Description = "Crackles with static. Do not pet during storms.",
	},
	{
		Id = "Glimmerwing",
		Name = "Glimmerwing",
		Rarity = "Epic",
		SellValue = 380,
		CatchWeight = 1.2,
		Weight = { Min = 1.5, Max = 4.0 },
		RequiredPower = 3,
		Look = {
			Body = Color3.fromRGB(170, 92, 255),
			Snout = Color3.fromRGB(255, 180, 255),
			Glow = Color3.fromRGB(220, 160, 255),
		},
		Description = "Leaves a trail of shimmering bubbles.",
	},

	-- Legendary ------------------------------------------------------------
	{
		Id = "GoldenGrubking",
		Name = "Golden Grubking",
		Rarity = "Legendary",
		SellValue = 1500,
		CatchWeight = 0.35,
		Weight = { Min = 4.0, Max = 9.0 },
		RequiredPower = 4,
		Look = {
			Body = Color3.fromRGB(255, 196, 40),
			Snout = Color3.fromRGB(230, 150, 20),
			Material = Enum.Material.Foil,
			Crown = true,
			Scale = 1.4,
		},
		Description = "Ruler of the pond. Expects to be bowed to.",
	},
	{
		Id = "EmberSnout",
		Name = "Ember Snout",
		Rarity = "Legendary",
		SellValue = 1800,
		CatchWeight = 0.25,
		Weight = { Min = 3.0, Max = 8.0 },
		RequiredPower = 4,
		Look = {
			Body = Color3.fromRGB(230, 70, 40),
			Snout = Color3.fromRGB(255, 170, 40),
			Glow = Color3.fromRGB(255, 120, 40),
			Scale = 1.3,
		},
		Description = "Somehow warm, even underwater.",
	},

	-- Mythic ---------------------------------------------------------------
	{
		Id = "StarlightWeevil",
		Name = "Starlight Weevil",
		Rarity = "Mythic",
		SellValue = 8000,
		CatchWeight = 0.05,
		Weight = { Min = 6.0, Max = 14.0 },
		RequiredPower = 5,
		Look = {
			Body = Color3.fromRGB(34, 30, 90),
			Snout = Color3.fromRGB(130, 220, 255),
			Glow = Color3.fromRGB(140, 200, 255),
			Sparkles = true,
			Crown = true,
			Scale = 1.5,
		},
		Description = "Said to have fallen from the night sky into the pond.",
	},
}
