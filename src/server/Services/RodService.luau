--!strict
--[[
	Gives players their equipped fishing rod as a Tool (on every spawn) and swaps
	it when they equip a different one.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Modules.Catalog)
local Remotes = require(Shared.Modules.Remotes)
local RodModel = require(Shared.Modules.RodModel)
local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)

type Rod = Catalog.Rod

local RodService = {}

local function removeRodTools(container: Instance?)
	if not container then
		return
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("RodId") then
			child:Destroy()
		end
	end
end

-- Replaces whatever rod the player has with their equipped one.
local function giveRod(player: Player)
	local data = DataService:GetData(player)
	if not data then
		return
	end
	local rod = Catalog.Rods.ById[data.EquippedRod]

	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	local wasHolding = character ~= nil and character:FindFirstChildOfClass("Tool") ~= nil

	removeRodTools(backpack)
	removeRodTools(character)

	if backpack then
		local tool = RodModel.Build(rod)
		tool.Parent = backpack
		-- Keep the new rod in hand if they were holding the old one.
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if wasHolding and humanoid then
			humanoid:EquipTool(tool)
		end
	end
end

-- The rod config for the player's equipped rod.
function RodService:GetEquippedRod(player: Player): Rod?
	local data = DataService:GetData(player)
	return if data then Catalog.Rods.ById[data.EquippedRod] else nil
end

-- Gives the player a rod they've just bought and equips it.
function RodService:Grant(player: Player, rodId: string)
	local data = DataService:GetData(player)
	if not data or not Catalog.Rods.ById[rodId] then
		return
	end
	data.OwnedRods[rodId] = true
	DataService:Replicate(player, "OwnedRods")
	self:Equip(player, rodId)
end

function RodService:Equip(player: Player, rodId: string): (boolean, string?)
	local data = DataService:GetData(player)
	if not data then
		return false, "Still loading..."
	end
	if not data.OwnedRods[rodId] then
		return false, "You don't own that rod"
	end
	if data.EquippedRod ~= rodId then
		data.EquippedRod = rodId
		DataService:Replicate(player, "EquippedRod")
		giveRod(player)
	end
	return true, nil
end

function RodService:Init()
	Remotes.Function("EquipRod").OnServerInvoke = function(player: Player, rodId: unknown)
		if type(rodId) ~= "string" or not Catalog.Rods.ById[rodId] then
			return false, "Unknown rod"
		end
		local ok, message = self:Equip(player, rodId)
		if ok then
			NotificationService:Send(player, `Equipped {Catalog.Rods.ById[rodId].Name}`, "Success")
		end
		return ok, message
	end
end

function RodService:Start()
	DataService.Loaded:Connect(function(player: Player)
		giveRod(player)
	end)

	-- Each spawn gets a fresh backpack, so give the rod again. If data hasn't
	-- loaded yet, the Loaded handler above gives it instead.
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			player:WaitForChild("Backpack", 10)
			task.defer(giveRod, player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return RodService
