---Base
class("EventPool")
class("BindableEvent")
class("BindHandler")

--为兼容以往多个旧事件系统而设立的子类
--主体逻辑与基类一致, 子类所做均为兼容化的特殊处理, 无需关心

---Trigger
class("EventPoolTrigger", EventPool)
class("BindableEventTrigger", BindableEvent)

---Object
class("EventPoolObject", EventPool)
class("BindableEventObject", BindableEvent)

---Lib
class("EventPoolLib", EventPool)
class("BindableEventLib", BindableEvent)

---Window
class("EventPoolWindow", EventPool)
class("BindableEventWindow", BindableEvent)

---Instance
class("EventPoolInstance", EventPool)
class("BindableEventInstance", BindableEvent)

require "common.event.event_define"

local Event = Event
local EVENT_POOL = Define.EVENT_POOL
local EVENT_SPACE = Define.EVENT_SPACE
local DEFAULT = EVENT_POOL.DEFAULT
local EventPools = {}

local RegisteredInterface = {
    DEFAULT = {},
    TRIGGER = {},
    LIB = {},
    WINDOW = {},
    INSTANCE = {},
}

function Event:RegisterInterface(Type, Name, InterfaceFunc)
    assert(Type and Name and InterfaceFunc)
    RegisteredInterface[Type][Name] = InterfaceFunc
end

function Event:GetEventPool(Owner, NotCreate)
    if not Owner.__EventPoolID then
        if NotCreate then
            return
        end

        local ID = Event:NewEventPool(Owner)
        Owner.__EventPoolID = ID
    end

    return self:GetEventPoolById(Owner.__EventPoolID)
end

local function Interface(Table, EventSpace ,Type)
    Table.__EventPoolType = EVENT_POOL[Type]
    Table.__EventSpace = EventSpace

    local DefaultInterface = RegisteredInterface[DEFAULT]
    for Name, Func in pairs(DefaultInterface) do
        rawset(Table, Name, Func)
    end
    if Type ~= DEFAULT then
        local TypeInterface = RegisteredInterface[Type]
        for Name, Func in pairs(TypeInterface) do
            rawset(Table, Name, Func)
        end
    end
end

function Event:InterfaceForTable(Table, EventSpace, Type)
    Interface(Table, EventSpace, Type)
end

function Event:InterfaceForMetatable(Metatable, EventSpace, Type)
    --if true then return end
    if not Metatable.__index then
        Metatable.__index = {}
    end
    if type(Metatable.__index) == "function" then
        local SecondMeta = { __index = Metatable.__index }
        setmetatable(Metatable, SecondMeta)
        Metatable.__index = {}
    end
    Interface(Metatable.__index, EventSpace, Type)
end

--[[
function Event:InterfaceForMetatable(Metatable, Type)
    if not Metatable.__index then
        Metatable.__index = {}
    end
    assert(type(Metatable.__index) == "table")
    Interface(Metatable.__index, Type)
end
--]]

local function NewEventMeta(Type)
    local meta = {}
    Event:InterfaceForMetatable(meta, Type)
    return meta
end

function Event:SetMetatable(Table, Type)
    return setmetatable(Table, NewEventMeta(Type))
end

function Event:GetEventPoolById(ID)
    return EventPools[ID]
end

local TypeToClass =
{
    DEFAULT = EventPool,
    TRIGGER = EventPoolTrigger,
    OBJECT = EventPoolObject,
    LIB = EventPoolLib,
    WINDOW = EventPoolWindow,
    INSTANCE = EventPoolInstance,
}

function Event:NewEventPool(Owner, EventSpace)
    local Type = Owner.__EventPoolType
    local Pool = TypeToClass[Type]
    local ID = #EventPools + 1
    if not EventSpace then
        EventSpace = Owner.__EventSpace
    end
    local NewPool = Pool.new(ID, Owner, EventSpace)
    EventPools[ID] = NewPool
    return ID
end

function Event:DestroyEventPool(Pool)
    local Owner = Pool:GetOwner()
    local ID = Pool:GetID()
    Owner.__EventPoolID = nil
    EventPools[ID] = nil
end

local RegisteredEvent = {} --<EventSpace, EventName>

local GLOBAL = EVENT_SPACE.GLOBAL
function Event:RegisterCustomEvent(EventName)
    self:RegisterEvent(EventName, GLOBAL)
end

function Event.IsValidEvent(EventName, EventSpace)
    if EventSpace == EVENT_SPACE.FREE then
        return true
    end

    local Space = RegisteredEvent[EventSpace]
    if not Space then
        return false
    end

    if not Space[EventName] then
        return false
    end

    return true
end

function Event:RegisterEvent(EventName, EventSpace)
    if not RegisteredEvent[EventSpace] then
        RegisteredEvent[EventSpace] = {}
    end

    RegisteredEvent[EventSpace][EventName] = 1
end

---@param EventNames table { Name1, Name2, ... }
function Event:RegisterEvents(EventNames, EventSpace)
    for _,EventName in pairs (EventNames) do
        self:RegisterEvent(EventName, EventSpace)
    end
end

require "common.event.event_pool"
require "common.event.bindable_event"
require "common.event.bind_handler"

----------------------默认全局事件池初始化(暂不开放全局事件)-------------------

--Interface(Event, EVENT_SPACE.GLOBAL, DEFAULT)
--Event.__EventPoolID = 0
--EventPools[0] = EventPool.new(0, Event)

----------------------额外全局UI事件池接口与初始化------------------

local ExtraPools =
{
    WINDOW =
    {
        ID = -1,
        EventSpace = EVENT_SPACE.FREE
    },
    --TRIGGER = -2,
    --LIB = -3,
}

for Type, Config in pairs(ExtraPools) do
    local ID = Config.ID
    local EventSpace = Config.EventSpace
    EventPools[ID] = EventPool.new(ID, Event, EventSpace)
end

function Event:GetExtraEvent(Type, EventName, Namespace, NotCreate)
    local PoolID = ExtraPools[Type].ID
    if not PoolID then return end
    local Pool = EventPools[PoolID]
    return Pool:GetEvent(EventName, Namespace, NotCreate)
end

------------------------------------------------------------