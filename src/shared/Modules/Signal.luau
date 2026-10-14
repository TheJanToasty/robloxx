--!strict
-- Lightweight event for communication between modules on the same side (server or client).

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Once: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Wait: (self: Signal) -> ...any,
	DisconnectAll: (self: Signal) -> (),
}

type ConnectionImpl = {
	Connected: boolean,
	Disconnect: (self: ConnectionImpl) -> (),
	_callback: (...any) -> (),
	_signal: SignalImpl,
}

type SignalImpl = {
	_connections: { ConnectionImpl },
}

local function disconnect(self: ConnectionImpl)
	if not self.Connected then
		return
	end
	self.Connected = false
	local connections = self._signal._connections
	local index = table.find(connections, self)
	if index then
		table.remove(connections, index)
	end
end

function Signal.new(): Signal
	local self: SignalImpl = { _connections = {} }
	return setmetatable(self, Signal) :: any
end

function Signal.Connect(self: SignalImpl, callback: (...any) -> ()): Connection
	local connection: ConnectionImpl = {
		Connected = true,
		Disconnect = disconnect,
		_callback = callback,
		_signal = self,
	}
	table.insert(self._connections, connection)
	return connection :: any
end

function Signal.Once(self: SignalImpl, callback: (...any) -> ()): Connection
	local connection: Connection
	connection = Signal.Connect(self, function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal.Fire(self: SignalImpl, ...: any)
	-- Copy so handlers can disconnect while we iterate.
	for _, connection in table.clone(self._connections) do
		if connection.Connected then
			task.spawn(connection._callback, ...)
		end
	end
end

function Signal.Wait(self: SignalImpl): ...any
	local thread = coroutine.running()
	Signal.Once(self, function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal.DisconnectAll(self: SignalImpl)
	for _, connection in table.clone(self._connections) do
		connection.Connected = false
	end
	table.clear(self._connections)
end

return Signal
