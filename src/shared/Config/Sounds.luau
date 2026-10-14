--!strict
--[[
	Sound effects. These use sounds that ship with the Roblox client
	(rbxasset://), so they're free to use and need no uploading.

	To use your own, upload a sound (or pick a Roblox-made one from the Creator
	Store) and replace the Id with "rbxassetid://<number>". Only use audio you
	have the rights to.
]]

return {
	Cast = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.5 },
	Splash = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.6 },
	Bite = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
	Catch = { Id = "rbxasset://sounds/action_swim.mp3", Volume = 0.8 },
	Escape = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.4, Pitch = 0.7 },
	Coins = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 1.4 },
	Purchase = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 1.2 },
	Error = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Pitch = 0.6 },
	Click = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.4 },
}
