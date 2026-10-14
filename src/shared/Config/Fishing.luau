--!strict
-- Timing and distance rules for fishing. All times are in seconds, distances in studs.

return {
	-- How long the bobber takes to fly out after casting.
	CastTime = 0.55,

	-- Random wait for a bite, before the rod's Speed is applied.
	BiteTime = { Min = 2.5, Max = 6 },

	-- How long the player has to reel in after a bite.
	ReelWindow = 1.6,

	-- Extra time allowed on the server for network delay when the player reels in.
	LatencyGrace = 0.35,

	-- Pause after each catch or miss before the player can cast again.
	Cooldown = 0.35,

	-- The player must be within this distance of the water's edge to cast.
	MaxShoreDistance = 14,

	-- The bobber must land at least this far inside the water's edge.
	EdgePadding = 4,

	-- The line is reeled in if the player walks this much farther away than their cast.
	MaxLineSlack = 12,
}
