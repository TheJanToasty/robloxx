--!strict
--[[
	Handles every purchase. The client only says what it wants to buy; the server
	checks the item exists, the player is at their own SHOP stand, can afford it
	and doesn't already own it, then charges them and hands it over.

	Categories:
		"Rod"     - itemId is a rod Id from Config/Rods
		"Upgrade" - itemId is an upgrade track Id from Config/Upgrades (buys the next level)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Modules.Catalog)
local Format = require(Shared.Modules.Format)
local Remotes = require(Shared.Modules.Remotes)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local RodService = require(script.Parent.RodService)
local UpgradeService = require(script.Parent.UpgradeService)

-- How close to their SHOP stand a player must be to buy (a little more than the prompt range).
local SHOP_RANGE = 24

local ShopService = {}

local function isAtOwnShop(player: Player): boolean
	local plot = PlotService:GetPlot(player)
	local stand = plot and plot.ShopPrompt.Parent
	return stand ~= nil and stand:IsA("BasePart") and PlotService:IsNear(player, stand, SHOP_RANGE)
end

local function charge(player: Player, cost: number, currency: string?): (boolean, string?)
	local currencyId = currency or "Coins"
	if not CurrencyService:Spend(player, currencyId, cost) then
		local name = Catalog.Currencies.ById[currencyId].Name
		local missing = cost - CurrencyService:Get(player, currencyId)
		return false, `You need {Format.Commas(missing)} more {string.lower(name)}!`
	end
	return true, nil
end

local function buyRod(player: Player, rodId: string): (boolean, string?)
	local rod = Catalog.Rods.ById[rodId]
	local data = DataService:GetData(player)
	if not rod or not data then
		return false, "That rod doesn't exist."
	end
	if data.OwnedRods[rodId] then
		return false, "You already own that rod."
	end
	local ok, message = charge(player, rod.Cost, rod.Currency)
	if not ok then
		return false, message
	end
	RodService:Grant(player, rodId)
	return true, `You bought the {rod.Name}!`
end

local function buyUpgrade(player: Player, trackId: string): (boolean, string?)
	local track = Catalog.Upgrades.ById[trackId]
	if not track then
		return false, "That upgrade doesn't exist."
	end
	local _, nextInfo = UpgradeService:GetNextLevel(player, trackId)
	if not nextInfo then
		return false, `Your {track.Name} is already maxed out!`
	end
	local ok, message = charge(player, nextInfo.Cost, nextInfo.Currency)
	if not ok then
		return false, message
	end
	UpgradeService:Raise(player, trackId)
	local unit = if track.Unit then ` {track.Unit}` else ""
	return true, `{track.Name} upgraded to {Format.Commas(nextInfo.Value)}{unit}!`
end

function ShopService:Purchase(player: Player, category: string, itemId: string): (boolean, string?)
	if not DataService:GetData(player) then
		return false, "Still loading your data..."
	end
	if not isAtOwnShop(player) then
		return false, "Visit the SHOP stand on your plot to buy things."
	end
	if category == "Rod" then
		return buyRod(player, itemId)
	elseif category == "Upgrade" then
		return buyUpgrade(player, itemId)
	end
	return false, "Unknown item."
end

function ShopService:Init()
	Remotes.Function("Purchase").OnServerInvoke = function(player: Player, category: unknown, itemId: unknown)
		if type(category) ~= "string" or type(itemId) ~= "string" then
			return false, "Unknown item."
		end
		return self:Purchase(player, category, itemId)
	end
end

return ShopService
