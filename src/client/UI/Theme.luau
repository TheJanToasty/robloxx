--!strict
-- Colours, fonts and sizes shared by every screen, so the UI looks consistent.

return {
	Font = Enum.Font.FredokaOne,
	BodyFont = Enum.Font.GothamBold,

	Colors = {
		Panel = Color3.fromRGB(255, 255, 255),
		PanelAlt = Color3.fromRGB(240, 244, 252),
		Dark = Color3.fromRGB(38, 42, 64),
		Text = Color3.fromRGB(40, 44, 66),
		TextMuted = Color3.fromRGB(120, 128, 152),
		TextLight = Color3.fromRGB(255, 255, 255),
		Stroke = Color3.fromRGB(30, 34, 56),

		Primary = Color3.fromRGB(64, 156, 255),
		Success = Color3.fromRGB(76, 200, 110),
		Danger = Color3.fromRGB(240, 80, 80),
		Warning = Color3.fromRGB(255, 176, 50),
		Gold = Color3.fromRGB(255, 200, 40),
		Disabled = Color3.fromRGB(170, 176, 196),
	},

	-- Rounded corner radius for panels and buttons.
	Corner = UDim.new(0, 14),
	SmallCorner = UDim.new(0, 10),

	-- The UI is designed for this screen height and scaled to fit others.
	DesignHeight = 720,
}
