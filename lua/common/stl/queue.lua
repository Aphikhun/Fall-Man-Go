---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2020/10/14 11:45
---
local class = require "common.class"
local queue = class("queue") ---@class queue : cls

function queue:ctor(tb)
    self._data = tb or {} ---@type any[]
end

function queue:front()
    return self._data[1]
end

function queue:front_pop()
    local ret = self:front()
    self:pop()
    return ret
end

function queue:back()
    return self._data[self:size()]
end

function queue:empty()
    return self:size() == 0
end

function queue:size()
    return #self._data
end

function queue:push(value, pos)
    if pos then
        table.insert(self._data, pos, value)
    else
        table.insert(self._data, value)
    end
end

function queue:pop()
    table.remove(self._data, 1)
end

---@param comp fun(a : any, a : any) : boolean
function queue:sort(comp)
    table.sort(self._data, comp)
end

function queue:clear()
    self._data = {}
end

return queue