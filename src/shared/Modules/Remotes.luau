--!strict
--[[
	Every RemoteEvent and RemoteFunction in the game, declared in one place.

	The server creates them in ReplicatedStorage.Remotes the first time this module
	is required there. The client waits for them. Always get remotes through here:

		Remotes.Event("Notify"):FireClient(player, "Hello", "Info")
		Remotes.Function("Purchase"):InvokeServer("Rod", "SturdyRod")

	Asking for a name that isn't listed below errors straight away, so typos show up
	in Output instead of failing silently.

	Rule: the client only ever asks the server to do something. The server checks
	every request and decides the result.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local EVENTS = {
	-- Server -> one client
	"DataUpdated", -- (key: string, value: any) a top-level field of the player's data changed
	"Notify", -- (message: string, kind: "Info" | "Success" | "Error" | "Rare")
	"FishingEvent", -- (kind: string, payload: {}) the player's own fishing state changed

	-- Server -> all clients
	"FishingFx", -- (kind: string, payload: {}) splashes and catches everyone can see
}

local FUNCTIONS = {
	-- Client -> server. Each returns (ok: boolean, message: string?) unless noted.
	"GetData", -- () -> snapshot of the player's data
	"FishingAction", -- (action: "Cast" | "Reel")
	"Purchase", -- (category: "Rod" | "Upgrade", itemId: string)
	"EquipRod", -- (rodId: string)
}

local Remotes = {}

local folder: Instance
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end

	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	for _, name in EVENTS do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = newFolder
	end
	for _, name in FUNCTIONS do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = newFolder
	end
	-- Parent last so clients see every remote at once.
	newFolder.Parent = ReplicatedStorage
	folder = newFolder
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

function Remotes.Event(name: string): RemoteEvent
	local remote = events[name]
	if not remote then
		assert(table.find(EVENTS, name), `Unknown RemoteEvent "{name}". Add it to EVENTS in Remotes.luau.`)
		remote = folder:WaitForChild(name) :: RemoteEvent
		events[name] = remote
	end
	return remote
end

function Remotes.Function(name: string): RemoteFunction
	local remote = functions[name]
	if not remote then
		assert(table.find(FUNCTIONS, name), `Unknown RemoteFunction "{name}". Add it to FUNCTIONS in Remotes.luau.`)
		remote = folder:WaitForChild(name) :: RemoteFunction
		functions[name] = remote
	end
	return remote
end

return Remotes
