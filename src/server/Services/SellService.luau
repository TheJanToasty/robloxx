--!strict
--[[
	Selling at the SELL stand on your own plot: empties the backpack and pays out
	coins. The value of each catch is worked out here on the server from the
	config, never sent by the client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Modules.Catalog)
local CatchMath = require(Shared.Modules.CatchMath)
local Format = require(Shared.Modules.Format)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local MapService = require(script.Parent.MapService)
local NotificationService = require(script.Parent.NotificationService)
local PlotService = require(script.Parent.PlotService)

local SELL_RANGE = 16

local SellService = {}

-- Sells everything in the player's backpack. Returns how many were sold and for how much.
function SellService:SellAll(player: Player): (number, number)
	local items = InventoryService:TakeAll(player)
	local total = 0
	for _, item in items do
		local creature = Catalog.Creatures.ById[item.CreatureId]
		if creature then
			total += CatchMath.GetValue(creature, item.Weight)
		end
	end
	if total > 0 then
		CurrencyService:Add(player, "Coins", total)
	end
	return #items, total
end

local function onSellTriggered(player: Player, plot: MapService.Plot)
	if PlotService:GetPlot(player) ~= plot then
		NotificationService:Send(player, "Sell at the stand on your own plot!", "Error")
		return
	end
	local stand = plot.SellPrompt.Parent
	if not stand or not stand:IsA("BasePart") or not PlotService:IsNear(player, stand, SELL_RANGE) then
		return
	end
	if InventoryService:GetCount(player) == 0 then
		NotificationService:Send(player, "Your backpack is empty. Go catch some creatures!", "Info")
		return
	end

	local count, coins = SellService:SellAll(player)
	local noun = if count == 1 then "creature" else "creatures"
	NotificationService:Send(player, `Sold {count} {noun} for {Format.Commas(coins)} coins!`, "Success")
end

function SellService:Start()
	for _, plot in MapService:GetPlots() do
		plot.SellPrompt.Triggered:Connect(function(player)
			onSellTriggered(player, plot)
		end)
	end
end

return SellService
