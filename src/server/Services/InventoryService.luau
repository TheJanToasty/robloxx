--!strict
--[[
	The backpack: caught creatures waiting to be sold. Capacity comes from the
	"Backpack" upgrade track.

	Each item has its own Id so future features (favourites, selling one at a
	time, pets) can point at a specific catch.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataTemplate = require(ReplicatedStorage.Shared.Data.PlayerDataTemplate)
local DataService = require(script.Parent.DataService)
local UpgradeService = require(script.Parent.UpgradeService)

type InventoryItem = PlayerDataTemplate.InventoryItem

local InventoryService = {}

function InventoryService:GetCapacity(player: Player): number
	return UpgradeService:GetValue(player, "Backpack")
end

function InventoryService:GetCount(player: Player): number
	local data = DataService:GetData(player)
	return if data then #data.Inventory.Items else 0
end

function InventoryService:IsFull(player: Player): boolean
	return InventoryService:GetCount(player) >= InventoryService:GetCapacity(player)
end

function InventoryService:GetItems(player: Player): { InventoryItem }
	local data = DataService:GetData(player)
	return if data then data.Inventory.Items else {}
end

-- Adds a caught creature. Returns the new item, or nil if the backpack is full.
function InventoryService:AddCreature(player: Player, creatureId: string, weight: number): InventoryItem?
	local data = DataService:GetData(player)
	if not data or InventoryService:IsFull(player) then
		return nil
	end
	local inventory = data.Inventory
	local item: InventoryItem = {
		Id = inventory.NextId,
		CreatureId = creatureId,
		Weight = weight,
	}
	inventory.NextId += 1
	table.insert(inventory.Items, item)
	DataService:Replicate(player, "Inventory")
	return item
end

-- Empties the backpack and returns everything that was in it.
function InventoryService:TakeAll(player: Player): { InventoryItem }
	local data = DataService:GetData(player)
	if not data then
		return {}
	end
	local items = data.Inventory.Items
	data.Inventory.Items = {}
	DataService:Replicate(player, "Inventory")
	return items
end

return InventoryService
