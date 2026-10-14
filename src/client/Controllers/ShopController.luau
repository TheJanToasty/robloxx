--!strict
--[[
	The shop window, opened from the SHOP stand on your plot. Lists every rod and
	every upgrade track from config, so new ones appear here automatically.
	Purchases are sent to the server, which checks and applies them.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Modules.Catalog)
local Format = require(Shared.Modules.Format)
local Remotes = require(Shared.Modules.Remotes)
local RodModel = require(Shared.Modules.RodModel)
local SoundPlayer = require(script.Parent.Parent.Modules.SoundPlayer)
local Kit = require(script.Parent.Parent.UI.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Viewport = require(script.Parent.Parent.UI.Viewport)
local Window = require(script.Parent.Parent.UI.Window)
local DataController = require(script.Parent.DataController)
local NotificationController = require(script.Parent.NotificationController)

local player = Players.LocalPlayer

-- Close the shop if the player walks this far from the stand.
local CLOSE_DISTANCE = 20

local ShopController = {}

type Tab = "Rods" | "Upgrades"

local window: Window.Window
local list: ScrollingFrame
local coinsLabel: TextLabel
local tabButtons: { [Tab]: TextButton } = {}
local currentTab: Tab = "Rods"
local standPart: BasePart? = nil
local busy = false

local function coins(): number
	local currencies = DataController:Get("Currencies")
	return if currencies then currencies.Coins or 0 else 0
end

local function statLine(rod: Catalog.Rod): string
	local luck = math.floor(rod.Luck * 100 + 0.5)
	return `Power {rod.Power}  ·  Luck +{luck}%  ·  Speed {rod.Speed}x`
end

local function request(remoteName: string, ...: any)
	if busy then
		return
	end
	busy = true
	local ok, message = Remotes.Function(remoteName):InvokeServer(...)
	busy = false
	if message then
		NotificationController:Show(message, if ok then "Success" else "Error")
	end
	if ok and remoteName == "Purchase" then
		SoundPlayer.Play("Purchase")
	end
end

local function clearList()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- One row in the list: an icon on the left, text in the middle, a button on the right.
local function row(order: number, accent: Color3): (Frame, Frame)
	local frame = Kit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 96),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		Parent = list,
	}, { Kit.Corner(UDim.new(0, 14)) })
	local icon = Kit.new("Frame", {
		Name = "Icon",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(76, 76),
		BackgroundColor3 = Theme.Colors.Panel,
		Parent = frame,
	}, { Kit.Corner(UDim.new(0, 12)), Kit.Stroke(accent, 3) })
	return frame, icon
end

local function rowText(
	frame: Frame,
	title: string,
	titleColor: Color3?,
	subtitle: string,
	subtitleColor: Color3?,
	body: string
)
	Kit.Label({
		Position = UDim2.fromOffset(98, 8),
		Size = UDim2.new(1, -260, 0, 28),
		Text = title,
		TextColor3 = titleColor or Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 24,
		Parent = frame,
	})
	Kit.Label({
		Position = UDim2.fromOffset(98, 36),
		Size = UDim2.new(1, -260, 0, 20),
		Text = subtitle,
		TextColor3 = subtitleColor or Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 17,
		Parent = frame,
	})
	Kit.Label({
		Position = UDim2.fromOffset(98, 58),
		Size = UDim2.new(1, -260, 0, 32),
		Text = body,
		Font = Theme.BodyFont,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextSize = 14,
		Parent = frame,
	})
end

local function rowButton(frame: Frame, text: string, color: Color3, onClick: (() -> ())?)
	local button = Kit.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(140, 50),
		BackgroundColor3 = color,
		Text = text,
		TextSize = 20,
		Parent = frame,
	}, onClick)
	if not onClick then
		button.AutoButtonColor = false
		button.Selectable = false
	end
end

local function showRods()
	local owned = DataController:Get("OwnedRods") or {}
	local equipped = DataController:Get("EquippedRod")
	local balance = coins()

	for _, rod in Catalog.Rods.List do
		local rarity = Catalog.Rarities.ByName[rod.Rarity]
		local frame, icon = row(rod.Order, rarity.Color)

		local viewport = Kit.new("ViewportFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Ambient = Color3.fromRGB(200, 200, 210),
			Parent = icon,
		})
		local tool = RodModel.Build(rod)
		local model = Instance.new("Model")
		for _, child in tool:GetChildren() do
			if child:IsA("BasePart") then
				child.Parent = model
			end
		end
		tool:Destroy()
		Viewport.Show(viewport, model, Vector3.new(1, 0.6, 0.15))

		rowText(frame, rod.Name, nil, rarity.Name, rarity.Color, `{statLine(rod)}\n{rod.Description or ""}`)

		if rod.Id == equipped then
			rowButton(frame, "Equipped", Theme.Colors.Disabled, nil)
		elseif owned[rod.Id] then
			rowButton(frame, "Equip", Theme.Colors.Primary, function()
				request("EquipRod", rod.Id)
			end)
		else
			local affordable = balance >= rod.Cost
			rowButton(
				frame,
				`Buy {Format.Short(rod.Cost)}`,
				if affordable then Theme.Colors.Success else Theme.Colors.Disabled,
				function()
					request("Purchase", "Rod", rod.Id)
				end
			)
		end
	end
end

local function showUpgrades()
	local levels = DataController:Get("Upgrades") or {}
	local balance = coins()

	for order, track in Catalog.Upgrades.List do
		local level = math.clamp(levels[track.Id] or 1, 1, #track.Levels)
		local current = track.Levels[level]
		local nextInfo = track.Levels[level + 1]
		local unit = if track.Unit then ` {track.Unit}` else ""
		local frame, icon = row(order, Theme.Colors.Warning)

		Kit.Label({
			Size = UDim2.fromScale(1, 1),
			Text = Format.Short(current.Value),
			TextSize = 30,
			Parent = icon,
		})

		local subtitle = `Level {level}/{#track.Levels}: {current.Name or ""} ({Format.Commas(current.Value)}{unit})`
		local body = track.Description or ""
		if nextInfo then
			body = `Next: {nextInfo.Name or ""} ({Format.Commas(nextInfo.Value)}{unit})\n{body}`
		end
		rowText(frame, track.Name, nil, subtitle, nil, body)

		if nextInfo then
			local affordable = balance >= nextInfo.Cost
			rowButton(
				frame,
				`Upgrade {Format.Short(nextInfo.Cost)}`,
				if affordable then Theme.Colors.Success else Theme.Colors.Disabled,
				function()
					request("Purchase", "Upgrade", track.Id)
				end
			)
		else
			rowButton(frame, "MAX", Theme.Colors.Disabled, nil)
		end
	end
end

local function refresh()
	if not window.IsOpen then
		return
	end
	coinsLabel.Text = `{Format.Commas(coins())} coins`
	for tab, button in tabButtons do
		button.BackgroundColor3 = if tab == currentTab then Theme.Colors.Primary else Theme.Colors.Disabled
	end
	clearList()
	if currentTab == "Rods" then
		showRods()
	else
		showUpgrades()
	end
end

function ShopController:Open(stand: BasePart?)
	standPart = stand
	window:Open()
	refresh()
end

function ShopController:Init()
	local screen = Kit.Screen("Shop", 10)
	window = Window.new(screen, "Shop", Vector2.new(640, 480), Theme.Colors.Primary)

	local topBar = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = window.Content,
	}, { Kit.List(Enum.FillDirection.Horizontal, 10, { VerticalAlignment = Enum.VerticalAlignment.Center }) })

	for order, tab: Tab in { "Rods", "Upgrades" } :: { Tab } do
		local button = Kit.Button({
			LayoutOrder = order,
			Size = UDim2.fromOffset(140, 40),
			Text = tab,
			TextSize = 20,
			Parent = topBar,
		}, function()
			currentTab = tab
			refresh()
		end)
		tabButtons[tab] = button
	end

	coinsLabel = Kit.Label({
		LayoutOrder = 3,
		Size = UDim2.new(1, -310, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(214, 150, 0),
		TextSize = 24,
		Parent = topBar,
	})

	list = Kit.new("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = window.Content,
	}, { Kit.List(Enum.FillDirection.Vertical, 10) })
end

function ShopController:Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeredBy: Player)
		if triggeredBy ~= player or prompt:GetAttribute("Action") ~= "Shop" then
			return
		end
		local stand = prompt.Parent
		self:Open(if stand and stand:IsA("BasePart") then stand else nil)
	end)

	for _, key in { "Currencies", "OwnedRods", "EquippedRod", "Upgrades" } do
		DataController:Observe(key, refresh)
	end

	-- Close the shop when the player walks away from the stand.
	while true do
		task.wait(0.5)
		local stand = standPart
		if window.IsOpen and stand then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root or (root.Position - stand.Position).Magnitude > CLOSE_DISTANCE then
				window:Close()
			end
		end
	end
end

return ShopController
