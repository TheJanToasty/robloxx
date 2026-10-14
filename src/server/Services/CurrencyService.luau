--!strict
--[[
	The only place coins (and any future currencies) are added or spent.
	Amounts are always whole numbers and balances never go below zero.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Modules.Catalog)
local DataService = require(script.Parent.DataService)

local CurrencyService = {}

local function check(currency: string, amount: number)
	assert(Catalog.Currencies.ById[currency], `Unknown currency "{currency}"`)
	assert(amount >= 0 and amount == math.floor(amount), `Currency amounts must be whole and positive, got {amount}`)
end

function CurrencyService:Get(player: Player, currency: string): number
	local data = DataService:GetData(player)
	return if data then data.Currencies[currency] or 0 else 0
end

function CurrencyService:Add(player: Player, currency: string, amount: number): boolean
	check(currency, amount)
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	data.Currencies[currency] = (data.Currencies[currency] or 0) + amount
	if currency == "Coins" then
		data.Stats.CoinsEarned += amount
		DataService:Replicate(player, "Stats")
	end
	DataService:Replicate(player, "Currencies")
	return true
end

-- Takes `amount` if the player has enough. Returns false (and changes nothing) otherwise.
function CurrencyService:Spend(player: Player, currency: string, amount: number): boolean
	check(currency, amount)
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	local balance = data.Currencies[currency] or 0
	if balance < amount then
		return false
	end
	data.Currencies[currency] = balance - amount
	DataService:Replicate(player, "Currencies")
	return true
end

return CurrencyService
