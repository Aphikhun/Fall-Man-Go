---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by bell.
--- DateTime: 2020/3/25 22:16
---
local id = 0

---@param segment number
---@return number
local function accumulator(segment)
    id = segment or id + 1
    return id
end

Event = {
    EVENT_PAY_MONEY_SUCCESS = accumulator(),
    EVENT_PLAYER_LOGIN = accumulator(),
    EVENT_PLAYER_LOGOUT = accumulator(),
    EVENT_ON_GROUND = accumulator(),
}

function Event.register(name)
    if Event[name] then
        Lib.logError("Event has register ".. name)
        return
    end
    id = accumulator()
    Event[name] = id
    return id
end