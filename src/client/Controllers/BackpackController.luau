--!strict
-- The backpack window: what you've caught and what it's worth. Open it from the HUD or with B.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Modules.Catalog)
local CatchMath = require(Shared.Modules.CatchMath)
local Format = require(Shared.Modules.Format)
local Kit = require(script.Parent.Parent.UI.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)
local DataController = require(script.Parent.DataController)

local BackpackController = {}

local window: Window.Window
local list: ScrollingFrame
local emptyLabel: TextLabel
local totalLabel: TextLabel

local function capacity(): number
	local upgrades = DataController:Get("Upgrades")
	local track = Catalog.Upgrades.ById.Backpack
	local level = if upgrades then upgrades.Backpack or 1 else 1
	return track.Levels[math.clamp(level, 1, #track.Levels)].Value
end

local function refresh()
	local inventory = DataController:Get("Inventory")
	local items = if inventory then inventory.Items else {}

	-- Group catches by creature.
	local groups: { [string]: { Count: number, Value: number } } = {}
	local total = 0
	for _, item in items do
		local creature = Catalog.Creatures.ById[item.CreatureId]
		if creature then
			local value = CatchMath.GetValue(creature, item.Weight)
			local group = groups[item.CreatureId]
			if not group then
				group = { Count = 0, Value = 0 }
				groups[item.CreatureId] = group
			end
			group.Count += 1
			group.Value += value
			total += value
		end
	end

	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for creatureId, group in groups do
		local creature = Catalog.Creatures.ById[creatureId]
		local rarity = Catalog.Rarities.ByName[creature.Rarity]
		Kit.new("Frame", {
			Name = creature.Name,
			-- Rarest first.
			LayoutOrder = -rarity.Tier * 100000 - creature.SellValue,
			Size = UDim2.new(1, -8, 0, 52),
			BackgroundColor3 = Theme.Colors.PanelAlt,
			Parent = list,
		}, {
			Kit.Corner(UDim.new(0, 12)),
			Kit.new("Frame", {
				Name = "RarityBar",
				Size = UDim2.new(0, 8, 1, 0),
				BackgroundColor3 = rarity.Color,
			}, { Kit.Corner(UDim.new(0, 4)) }),
			Kit.Label({
				Position = UDim2.fromOffset(18, 2),
				Size = UDim2.new(0.6, -18, 0, 28),
				Text = `{creature.Name}  <font color="#7880A0">x{group.Count}</font>`,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 22,
			}),
			Kit.Label({
				Position = UDim2.fromOffset(18, 28),
				Size = UDim2.new(0.6, -18, 0, 20),
				Text = rarity.Name,
				TextColor3 = rarity.Color,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 16,
			}),
			Kit.Label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 0),
				Size = UDim2.new(0.4, 0, 1, 0),
				Text = `{Format.Commas(group.Value)} coins`,
				TextColor3 = Color3.fromRGB(214, 150, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextSize = 20,
			}),
		})
	end

	emptyLabel.Visible = #items == 0
	window.Title.Text = `Backpack  {#items}/{capacity()}`
	totalLabel.Text = `Worth {Format.Commas(total)} coins. Sell at the SELL stand on your plot!`
end

function BackpackController:Toggle()
	window:Toggle()
end

function BackpackController:Init()
	local screen = Kit.Screen("Backpack", 10)
	window = Window.new(screen, "Backpack", Vector2.new(480, 440), Color3.fromRGB(186, 120, 60))

	list = Kit.new("ScrollingFrame", {
		Name = "List",
		Size = UDim2.new(1, 0, 1, -52),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window.Content,
	}, { Kit.List(Enum.FillDirection.Vertical, 8) })

	emptyLabel = Kit.Label({
		Size = UDim2.new(1, 0, 1, -52),
		Text = "Nothing here yet.\nGo catch something at the pond!",
		TextColor3 = Theme.Colors.TextMuted,
		TextSize = 22,
		Parent = window.Content,
	})

	totalLabel = Kit.Label({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 44),
		Font = Theme.BodyFont,
		TextSize = 17,
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted,
		Parent = window.Content,
	})

	window.OnOpened = refresh
end

function BackpackController:Start()
	DataController:Observe("Inventory", function()
		if window.IsOpen then
			refresh()
		end
	end)
	DataController:Observe("Upgrades", function()
		if window.IsOpen then
			refresh()
		end
	end)

	ContextActionService:BindAction("ToggleBackpack", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:Toggle()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.B)
end

return BackpackController
