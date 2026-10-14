--!strict
-- The card that pops up after a catch: the creature, its rarity, weight and value.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Modules.Catalog)
local CreatureModel = require(Shared.Modules.CreatureModel)
local Format = require(Shared.Modules.Format)
local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Viewport = require(script.Parent.Viewport)

local CatchCard = {}

local SHOW_TIME = 2.8

local card: Frame
local scale: UIScale
local viewport: ViewportFrame
local nameLabel: TextLabel
local rarityLabel: TextLabel
local detailLabel: TextLabel
local newBadge: TextLabel
local glow: UIStroke
local showId = 0

function CatchCard.Create(parent: Instance)
	scale = Kit.new("UIScale", { Scale = 0 })
	glow = Kit.Stroke(Theme.Colors.Stroke, 4)

	card = Kit.new("Frame", {
		Name = "CatchCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromOffset(400, 150),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = parent,
	}, { Kit.Corner(UDim.new(0, 18)), scale, glow })

	viewport = Kit.new("ViewportFrame", {
		Name = "Creature",
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(126, 126),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -1, -1),
		Parent = card,
	}, { Kit.Corner(UDim.new(0, 14)) })

	rarityLabel = Kit.Label({
		Position = UDim2.fromOffset(152, 16),
		Size = UDim2.new(1, -164, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 20,
		Parent = card,
	})
	nameLabel = Kit.Label({
		Position = UDim2.fromOffset(152, 40),
		Size = UDim2.new(1, -164, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		Parent = card,
	})
	detailLabel = Kit.Label({
		Position = UDim2.fromOffset(152, 86),
		Size = UDim2.new(1, -164, 0, 48),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Theme.BodyFont,
		TextSize = 18,
		TextColor3 = Theme.Colors.TextMuted,
		RichText = true,
		Parent = card,
	})
	newBadge = Kit.new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 10, 0, -12),
		Size = UDim2.fromOffset(70, 30),
		Rotation = 8,
		BackgroundColor3 = Theme.Colors.Danger,
		Font = Theme.Font,
		Text = "NEW!",
		TextSize = 20,
		TextColor3 = Theme.Colors.TextLight,
		Visible = false,
		Parent = card,
	}, { Kit.Corner(UDim.new(0, 8)), Kit.Stroke(Theme.Colors.Stroke, 2) })
end

function CatchCard.Show(creatureId: string, weight: number, value: number, isNew: boolean)
	local creature = Catalog.Creatures.ById[creatureId]
	if not creature then
		return
	end
	local rarity = Catalog.Rarities.ByName[creature.Rarity]

	showId += 1
	local myId = showId

	rarityLabel.Text = string.upper(rarity.Name)
	rarityLabel.TextColor3 = rarity.Color
	nameLabel.Text = creature.Name
	detailLabel.Text = `{Format.Weight(weight)}\n<font color="#E0A800">+{Format.Commas(value)} coins</font> in backpack`
	newBadge.Visible = isNew
	glow.Color = if rarity.Tier >= 4 then rarity.Color else Theme.Colors.Stroke
	glow.Thickness = if rarity.Tier >= 4 then 6 else 4

	Viewport.Show(viewport, CreatureModel.Build(creature))

	card.Visible = true
	scale.Scale = 0.3
	Kit.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)

	task.delay(SHOW_TIME + (if rarity.Tier >= 4 then 1.5 else 0), function()
		if showId ~= myId then
			return
		end
		local tween = Kit.Tween(scale, 0.2, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween.Completed:Wait()
		if showId == myId then
			card.Visible = false
		end
	end)
end

return CatchCard
