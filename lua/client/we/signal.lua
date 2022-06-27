local M = {}

function M:init()
	self._sender = setmetatable({}, {
		__mode = "k"
	})
end

function M:subscribe(sender, signal, func)
	assert(sender and signal, tostring(signal))
    assert(type(func) == "function")

    local invalid = false
    local function call(...)
        if invalid then
            return 0
        end

		if func(...) == 0 then
			invalid = true
			return 0
		end
    end
    
    local function cancel()
        invalid = true
    end

	self._sender[sender] = self._sender[sender] or {}
	self._sender[sender][signal] = self._sender[sender][signal] or {}
	table.insert(self._sender[sender][signal], call)

    return cancel
end

function M:publish(sender, signal, ...)
    assert(sender and signal)
	
	local calls = self._sender[sender] and self._sender[sender][signal]
	if not calls then
		return
	end

	local _calls = {}
	for _, call in ipairs(calls) do
		table.insert(_calls, call)
	end

	local invalid_set = {}
	for _, call in ipairs(_calls) do
		if call(...) == 0 then
			invalid_set[call] = true
		end
	end

	local idx = 1
	repeat
		local call = calls[idx]
		if not call then
			break
		end
		if invalid_set[call] then
			table.remove(calls, idx)
		else
			idx = idx + 1
		end
	until(false)
end

return M
