--!strict
-- Always-visible stats on the left of the screen: coins and backpack space.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Modules.Catalog)
local Format = require(Shared.Modules.Format)
local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local Kit = require(script.Parent.Parent.UI.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local BackpackController = require(script.Parent.BackpackController)
local DataController = require(script.Parent.DataController)

local HudController = {}

local coinsLabel: TextLabel
local coinsPill: GuiObject
local backpackLabel: TextLabel
local backpackFill: Frame
local backpackPill: GuiObject
local lastCoins: number? = nil

local function pill(parent: Instance, name: string, order: number, isButton: boolean): GuiObject
	return Kit.new(if isButton then "TextButton" else "Frame", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(210, 54),
		BackgroundColor3 = Theme.Colors.Panel,
		AutoButtonColor = if isButton then false else nil,
		Text = if isButton then "" else nil,
		Parent = parent,
	}, { Kit.Corner(UDim.new(1, 0)), Kit.Stroke(Theme.Colors.Stroke, 3), Kit.new("UIScale") })
end

local function icon(parent: Instance, color: Color3, text: string)
	Kit.new("TextLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -6, 0.5, 0),
		Size = UDim2.fromOffset(58, 58),
		BackgroundColor3 = color,
		Font = Theme.Font,
		Text = text,
		TextSize = 28,
		TextColor3 = Theme.Colors.TextLight,
		ZIndex = 3,
		Parent = parent,
	}, { Kit.Corner(UDim.new(1, 0)), Kit.Stroke(Theme.Colors.Stroke, 3), Kit.TextStroke(Theme.Colors.Stroke, 2) })
end

local function valueLabel(parent: Instance): TextLabel
	return Kit.new("TextLabel", {
		Name = "Value",
		Position = UDim2.fromOffset(60, 0),
		Size = UDim2.new(1, -72, 1, 0),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.Text,
		ZIndex = 2,
		Parent = parent,
	})
end

local function bump(target: GuiObject)
	local scale = target:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 1.15
		Kit.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

-- A "+25" that floats up from the coins counter.
local function floatGain(amount: number)
	local label = Kit.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 8, 0.5, 0),
		Size = UDim2.fromOffset(120, 30),
		BackgroundTransparency = 1,
		Font = Theme.Font,
		Text = `+{Format.Short(amount)}`,
		TextSize = 28,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.Gold,
		Parent = coinsPill,
	}, { Kit.TextStroke(Theme.Colors.Stroke, 2) })
	Kit.Tween(label, 1.1, { Position = UDim2.new(1, 8, 0.5, -40), TextTransparency = 1 })
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		Kit.Tween(stroke, 1.1, { Transparency = 1 })
	end
	task.delay(1.2, function()
		label:Destroy()
	end)
end

local function updateCoins(currencies: { [string]: number }?)
	local coins = if currencies then currencies.Coins or 0 else 0
	coinsLabel.Text = Format.Short(coins)
	if lastCoins and coins > lastCoins then
		bump(coinsPill)
		floatGain(coins - lastCoins)
		SoundPlayer.Play("Coins")
	end
	lastCoins = coins
end

local function updateBackpack()
	local inventory = DataController:Get("Inventory")
	local upgrades = DataController:Get("Upgrades")
	local count = if inventory then #inventory.Items else 0
	local track = Catalog.Upgrades.ById.Backpack
	local level = if upgrades then upgrades.Backpack or 1 else 1
	local capacity = track.Levels[math.clamp(level, 1, #track.Levels)].Value

	local full = count >= capacity
	backpackLabel.Text = `{count}/{capacity}`
	backpackLabel.TextColor3 = if full then Theme.Colors.Danger else Theme.Colors.Text
	backpackFill.Size = UDim2.fromScale(math.clamp(count / capacity, 0, 1), 1)
	backpackFill.BackgroundColor3 = if full then Color3.fromRGB(255, 205, 205) else Color3.fromRGB(255, 236, 200)
	bump(backpackPill)
end

function HudController:Init()
	local screen = Kit.Screen("Hud", 1)

	local stack = Kit.new("Frame", {
		Name = "Stats",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 22, 0.42, 0),
		Size = UDim2.fromOffset(220, 130),
		BackgroundTransparency = 1,
		Parent = screen,
	}, { Kit.List(Enum.FillDirection.Vertical, 14) })

	coinsPill = pill(stack, "Coins", 1, false)
	icon(coinsPill, Theme.Colors.Gold, "$")
	coinsLabel = valueLabel(coinsPill)
	coinsLabel.Text = "0"

	backpackPill = pill(stack, "Backpack", 2, true)
	icon(backpackPill, Color3.fromRGB(186, 120, 60), "B")
	-- Fill behind the text shows how full the backpack is.
	local fillClip = Kit.new("Frame", {
		Name = "FillClip",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = backpackPill,
	}, { Kit.Corner(UDim.new(1, 0)) })
	backpackFill = Kit.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 236, 200),
		BorderSizePixel = 0,
		Parent = fillClip,
	}, { Kit.Corner(UDim.new(1, 0)) })
	backpackLabel = valueLabel(backpackPill)
	backpackLabel.Text = "0/10";
	(backpackPill :: TextButton).Activated:Connect(function()
		SoundPlayer.Play("Click")
		BackpackController:Toggle()
	end)
end

function HudController:Start()
	DataController:Observe("Currencies", updateCoins)
	DataController:Observe("Inventory", updateBackpack)
	DataController:Observe("Upgrades", updateBackpack)
end

return HudController
