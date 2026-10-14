--!strict
--[[
	Map layout. The map is built from code when the server starts (see
	src/server/World), so changing these numbers reshapes the world.

	The pond sits at the world origin. Plots are spaced evenly around it,
	Plot 1 to the north (-Z) and the rest going clockwise.
]]

return {
	-- Square of studded ground, centred on the pond.
	GroundSize = 380,
	GroundThickness = 4,
	-- The ground around the pond is built from strips this wide. Smaller = rounder shoreline.
	StripSize = 2,

	PondRadius = 62,
	BeachWidth = 8,
	WaterDepth = 12,
	-- Height of the water surface. The ground's top is at Y = 0.
	WaterSurfaceY = -1,

	PlotCount = 8,
	-- Distance from the pond centre to each plot's centre.
	PlotRingRadius = 124,
	PlotSize = 44,

	-- Each fishing dock reaches this far into the water.
	DockLength = 16,
	DockWidth = 8,

	Colors = {
		Grass = Color3.fromRGB(88, 170, 72),
		Sand = Color3.fromRGB(240, 214, 150),
		Path = Color3.fromRGB(196, 196, 204),
		Dock = Color3.fromRGB(160, 112, 70),
		DockPost = Color3.fromRGB(110, 76, 48),
		Hedge = Color3.fromRGB(52, 120, 56),
		Trunk = Color3.fromRGB(120, 84, 52),
		Leaves = {
			Color3.fromRGB(70, 160, 70),
			Color3.fromRGB(96, 186, 80),
			Color3.fromRGB(60, 140, 90),
		},
		Water = Color3.fromRGB(40, 176, 210),
		LilyPad = Color3.fromRGB(80, 180, 80),
		Lamp = Color3.fromRGB(255, 226, 150),
	},

	-- One colour per plot, in plot order.
	PlotColors = {
		Color3.fromRGB(255, 99, 99),
		Color3.fromRGB(255, 160, 64),
		Color3.fromRGB(255, 214, 64),
		Color3.fromRGB(110, 220, 140),
		Color3.fromRGB(80, 190, 230),
		Color3.fromRGB(100, 130, 240),
		Color3.fromRGB(170, 110, 235),
		Color3.fromRGB(250, 120, 190),
	},
}
