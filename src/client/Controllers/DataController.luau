--!strict
--[[
	The client's read-only copy of the local player's data. The server sends a full
	copy on join and then each top-level field whenever it changes.

	Never change this data on the client to "give" things; the server ignores it.

		DataController:Observe("Currencies", function(currencies)
			coinsLabel.Text = currencies.Coins
		end)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Modules.Remotes)
local Signal = require(Shared.Modules.Signal)

local DataController = {}

-- Fires (key, value) whenever a field changes.
DataController.Changed = Signal.new()
-- Fires once when the first full copy arrives.
DataController.Loaded = Signal.new()
DataController.IsLoaded = false

local data: { [string]: any } = {}

function DataController:Get(key: string): any
	return data[key]
end

-- Calls `callback(value)` now (if loaded) and every time `key` changes.
function DataController:Observe(key: string, callback: (any) -> ())
	if self.IsLoaded then
		task.spawn(callback, data[key])
	end
	return self.Changed:Connect(function(changedKey: string, value: any)
		if changedKey == key then
			callback(value)
		end
	end)
end

-- Yields until the first copy of the data has arrived.
function DataController:WaitForData()
	if not self.IsLoaded then
		self.Loaded:Wait()
	end
end

function DataController:Start()
	Remotes.Event("DataUpdated").OnClientEvent:Connect(function(key: string, value: any)
		data[key] = value
		if self.IsLoaded then
			self.Changed:Fire(key, value)
		end
	end)

	local snapshot
	repeat
		local ok, result = pcall(function()
			return Remotes.Function("GetData"):InvokeServer()
		end)
		if ok and result then
			snapshot = result
		else
			task.wait(2)
		end
	until snapshot

	for key, value in snapshot do
		data[key] = value
	end
	self.IsLoaded = true
	self.Loaded:Fire()
	for key, value in data do
		self.Changed:Fire(key, value)
	end
end

return DataController
