--!strict
--[[
	Rarity tiers, from most common to rarest. The order of this list is the tier
	order: rod Luck boosts each tier more than the one before it.

	Announce = true tells every player in the server when someone catches one.
]]

return {
	{ Name = "Common", Color = Color3.fromRGB(178, 190, 204) },
	{ Name = "Uncommon", Color = Color3.fromRGB(98, 210, 108) },
	{ Name = "Rare", Color = Color3.fromRGB(64, 156, 255) },
	{ Name = "Epic", Color = Color3.fromRGB(178, 96, 255), Announce = true },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 186, 30), Announce = true },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 72, 146), Announce = true },
}
