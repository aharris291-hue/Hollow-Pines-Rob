-- Minimal signal for in-process events (no Roblox instances, safe to unit test).

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(handler)
	local entry = { fn = handler, connected = true }
	table.insert(self._handlers, entry)
	return {
		Disconnect = function()
			entry.connected = false
			local index = table.find(self._handlers, entry)
			if index then
				table.remove(self._handlers, index)
			end
		end,
	}
end

function Signal:Fire(...)
	-- Copy so handlers can disconnect while we iterate.
	local handlers = table.clone(self._handlers)
	for _, entry in handlers do
		if entry.connected then
			local ok, err = pcall(entry.fn, ...)
			if not ok then
				warn("[Signal] handler error: " .. tostring(err))
			end
		end
	end
end

function Signal:Once(handler)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		handler(...)
	end)
	return connection
end

return Signal
