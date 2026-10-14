--!strict
--[[
	Loads, saves and replicates player data. Every other service reads and changes
	player data through here; nothing else touches DataStores.

	Safety:
	- Each save is locked to the server using it (SessionLock), so a player
	  hopping servers can't load stale data or duplicate items. A lock left by a
	  crashed server expires after LOCK_EXPIRES seconds.
	- Saves never overwrite data that another server has taken over.
	- Missing fields are filled in from PlayerDataTemplate on load, so new fields
	  never break old saves.
	- In Studio without API access (or in an unpublished place), players get
	  temporary data that is never saved, so the game is still playable.

	Usage from another service:
		local data = DataService:GetData(player)   -- nil until loaded
		data.Currencies.Coins += 10
		DataService:Replicate(player, "Currencies") -- tell their client
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Catalog = require(Shared.Modules.Catalog)
local PlayerDataTemplate = require(Shared.Data.PlayerDataTemplate)
local Remotes = require(Shared.Modules.Remotes)
local Signal = require(Shared.Modules.Signal)
local TableUtil = require(Shared.Modules.TableUtil)

type PlayerData = PlayerDataTemplate.PlayerData

local STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 120
local LOCK_EXPIRES = 600
local LOAD_ATTEMPTS = 6
local RETRY_DELAY = 5

type Profile = {
	Data: PlayerData,
	-- False when the data is temporary (Studio without API access) or another server took over.
	Saveable: boolean,
}

local DataService = {}

-- Fires (player, data) once a player's data has loaded.
DataService.Loaded = Signal.new()

local profiles: { [Player]: Profile } = {}
local waiting: { [Player]: { thread } } = {}
local store: DataStore? = nil

local function getKey(userId: number): string
	return `Player_{userId}`
end

local function snapshot(data: PlayerData): { [string]: any }
	local result = {}
	for _, key in PlayerDataTemplate.ReplicatedKeys do
		result[key] = (data :: any)[key]
	end
	return result
end

-- Fixes anything in a save that no longer matches the config (e.g. a rod that was removed).
local function sanitize(data: PlayerData)
	TableUtil.Reconcile(data :: any, PlayerDataTemplate.New() :: any)

	for rodId in data.OwnedRods do
		if not Catalog.Rods.ById[rodId] then
			data.OwnedRods[rodId] = nil
		end
	end
	data.OwnedRods[Catalog.Rods.Starter.Id] = true
	if not data.OwnedRods[data.EquippedRod] then
		data.EquippedRod = Catalog.Rods.Starter.Id
	end

	for trackId, level in data.Upgrades do
		local track = Catalog.Upgrades.ById[trackId]
		if track then
			data.Upgrades[trackId] = math.clamp(math.floor(level), 1, #track.Levels)
		end
	end

	local items = data.Inventory.Items
	for i = #items, 1, -1 do
		if not Catalog.Creatures.ById[items[i].CreatureId] then
			warn(`[DataService] Removed unknown creature "{items[i].CreatureId}" from a backpack`)
			table.remove(items, i)
		end
	end

	data.DataVersion = PlayerDataTemplate.Version
end

local function isStudioAccessError(message: string): boolean
	return message:find("StudioAccessToApisNotAllowed") ~= nil
		or message:find("API Services") ~= nil
		or message:find("publish this place") ~= nil
end

-- Returns the player's data and whether it can be saved, or nil if loading failed.
local function fetch(userId: number): (PlayerData?, boolean)
	local dataStore = store
	if not dataStore then
		return PlayerDataTemplate.New(), false
	end

	local key = getKey(userId)
	for attempt = 1, LOAD_ATTEMPTS do
		local loaded: PlayerData? = nil
		local lockedElsewhere = false

		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, function(stored: any)
				loaded = nil
				lockedElsewhere = false

				local data: PlayerData = if type(stored) == "table" then stored else PlayerDataTemplate.New()
				local lock = data.SessionLock
				local lockIsFresh = lock ~= nil and os.time() - lock.Time < LOCK_EXPIRES
				-- On the last attempt, take the lock anyway. The old server's saves are
				-- refused once it sees the lock has moved, so nothing gets duplicated.
				if lock and lock.JobId ~= game.JobId and lockIsFresh and attempt < LOAD_ATTEMPTS then
					lockedElsewhere = true
					return nil
				end

				data.SessionLock = { JobId = game.JobId, Time = os.time() }
				loaded = data
				return data
			end)
		end)

		if ok and loaded then
			return loaded, true
		elseif not ok then
			local message = tostring(err)
			warn(`[DataService] Load attempt {attempt} for {userId} failed: {message}`)
			if RunService:IsStudio() and isStudioAccessError(message) then
				break
			end
		elseif lockedElsewhere then
			warn(`[DataService] {userId}'s data is in use by another server, retrying...`)
		end

		task.wait(RETRY_DELAY)
	end

	if RunService:IsStudio() then
		return PlayerDataTemplate.New(), false
	end
	return nil, false
end

local function save(player: Player, profile: Profile, release: boolean)
	local dataStore = store
	if not profile.Saveable or not dataStore then
		return
	end

	local data = profile.Data
	local lostLock = false
	local ok, err = pcall(function()
		dataStore:UpdateAsync(getKey(player.UserId), function(stored: any)
			lostLock = false
			-- An autosave that finishes after the player left must not re-take the released lock.
			if not release and profiles[player] ~= profile then
				return nil
			end
			local lock = if type(stored) == "table" then stored.SessionLock else nil
			if lock and lock.JobId ~= game.JobId then
				lostLock = true
				return nil
			end
			data.SessionLock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return data
		end)
	end)

	if not ok then
		warn(`[DataService] Saving {player.Name} failed: {err}`)
	elseif lostLock then
		-- Another server has this player's data now. Stop saving here so we never overwrite it.
		profile.Saveable = false
		warn(`[DataService] {player.Name}'s data was taken over by another server; not saving here`)
		if player.Parent then
			player:Kick("You joined from another server. Please rejoin.")
		end
	end
end

local function resumeWaiting(player: Player)
	local threads = waiting[player]
	waiting[player] = nil
	if threads then
		for _, thread in threads do
			task.spawn(thread)
		end
	end
end

local function onPlayerAdded(player: Player)
	local data, saveable = fetch(player.UserId)

	if not player.Parent then
		-- Left while loading: release the lock we just took.
		if data and saveable then
			save(player, { Data = data, Saveable = true }, true)
		end
		resumeWaiting(player)
		return
	end

	if not data then
		resumeWaiting(player)
		player:Kick("We couldn't load your data. Please rejoin in a moment.")
		return
	end

	sanitize(data)
	profiles[player] = { Data = data, Saveable = saveable }
	player:SetAttribute("DataLoaded", true)
	resumeWaiting(player)
	DataService.Loaded:Fire(player, data)

	if not saveable then
		warn(`[DataService] {player.Name} is using temporary data that will NOT be saved.`)
		warn(
			"[DataService] To test saving: publish the place, then Game Settings > Security > Enable Studio Access to API Services."
		)
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	profiles[player] = nil
	if profile then
		save(player, profile, true)
	end
	resumeWaiting(player)
end

-- Public API -----------------------------------------------------------------

-- The player's live data table, or nil if it hasn't loaded (or the player left).
function DataService:GetData(player: Player): PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Yields until the player's data has loaded. Returns nil if they leave first.
function DataService:WaitForData(player: Player): PlayerData?
	while player.Parent and not profiles[player] do
		local threads = waiting[player]
		if not threads then
			threads = {}
			waiting[player] = threads
		end
		table.insert(threads, coroutine.running())
		coroutine.yield()
	end
	return self:GetData(player)
end

-- Sends one top-level field to the player's client after you change it.
function DataService:Replicate(player: Player, key: string)
	local data = self:GetData(player)
	if data and table.find(PlayerDataTemplate.ReplicatedKeys, key) then
		Remotes.Event("DataUpdated"):FireClient(player, key, (data :: any)[key])
	end
end

-- Lifecycle ------------------------------------------------------------------

function DataService:Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`[DataService] DataStores unavailable ({result}). Player data will not be saved.`)
	end

	Remotes.Function("GetData").OnServerInvoke = function(player: Player)
		local data = self:WaitForData(player)
		return if data then snapshot(data) else nil
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		local pending = 0
		for player, profile in profiles do
			pending += 1
			task.spawn(function()
				save(player, profile, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player, profile in table.clone(profiles) do
			if profiles[player] == profile then
				task.spawn(save, player, profile, false)
			end
			-- Spread saves out so a full server doesn't hit DataStore limits all at once.
			task.wait(1)
		end
	end
end

return DataService
