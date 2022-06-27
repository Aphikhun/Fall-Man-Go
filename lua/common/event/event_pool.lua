local EventPool = EventPool
local DEFAULT = Define.EVENT_POOL.DEFAULT
--local EventSpaces = Define.EVENT_SPACE
local Creator = BindableEvent.new
local IsValidEvent = Event.IsValidEvent

function EventPool:ctor(ID, Owner, EventSpace)
    self.__ID = ID
    self.__Owner = Owner
    self.__BindableEvents = {} --<Namespace, <EventName, BindableEvent>>
    self.__EventCreator = Creator
    self.__PoolType = DEFAULT
    self.__EventSpace = EventSpace
    self.__Valid = true
end

---@param EventName string : 事件名
---@param Namespace string : 事件作用域, 默认"Engine"
---@param NotCreate boolean : 若不存在则不创建新的BindableEvent
---@return BindableEvent
---@return boolean 是否为新创建的BindableEvent
function EventPool:GetEvent(EventName, Namespace, NotCreate)
    local EventSpace = self:GetEventSpace()
    if not IsValidEvent(EventName, EventSpace) then
        return
    end

    if not Namespace then
        Namespace = "Engine"
    end
    local Events = self.__BindableEvents[Namespace]
    if not Events then
        if NotCreate  then
            return
        end

        Events = {}
        self.__BindableEvents[Namespace] = Events
    end

    local New = false
    local BindableEvent = Events[EventName]
    if not BindableEvent then
        if NotCreate then
            return
        end

        New = true
        BindableEvent = self.__EventCreator(self:GetID(), EventName, Namespace)
        Events[EventName] = BindableEvent
    end

    return BindableEvent, New
end

function EventPool:GetID()
    return self.__ID
end

function EventPool:GetOwner()
    return self.__Owner
end

function EventPool:GetType()
    return self.__PoolType
end

function EventPool:GetEventSpace()
    return self.__EventSpace
end

function EventPool:IsValid()
    return self.__Valid
end

function EventPool:DestroySingleBind(EventName)
    local BindableEvent = self:GetEvent(EventName, "Engine", true)
    if not BindableEvent then
        return
    end

    BindableEvent:DestroySingleBind()
end

function EventPool:GetSingleBindFunction(EventName)
    local BindableEvent= self:GetEvent(EventName, "Engine", true)
    if not BindableEvent then
        return
    end

    return BindableEvent:GetSingleBindFunction()
end

local Event = Event
function EventPool:Destroy()
    --优先销毁Pool管理的事件
    for Namespace,Events in pairs(self.__BindableEvents)  do
        for EventName,BindableEvent in pairs (Events) do
            BindableEvent:Destroy()
        end
    end

    --Event销毁索引
    Event:DestroyEventPool(self)

    --最后销毁自身数据
    self.__Owner = nil
    self.__EventClass = nil
    self.__BindableEvents = nil
    self.__Valid = false
end

Event:RegisterInterface(DEFAULT, "GetEvent",function (Owner, EventName, Namespace, NotCreate)
    local Pool = Event:GetEventPool(Owner, NotCreate)
    if Pool then return Pool:GetEvent(EventName, Namespace, NotCreate) end
end)

Event:RegisterInterface(DEFAULT, "DestroySelfEvent",function (Owner)
    local Pool = Event:GetEventPool(Owner)
    if Pool then Pool:Destroy() end
end)

Event:RegisterInterface(DEFAULT, "DestroySingleBind",function(Owner, EventName)
    local Pool = Event:GetEventPool(Owner, true)
    if Pool then return Pool:DestroySingleBind(EventName) end
end)

Event:RegisterInterface(DEFAULT, "GetSingleBindFunction",function(Owner, EventName)
    local Pool = Event:GetEventPool(Owner, true)
    if Pool then return Pool:GetSingleBindFunction(EventName) end
end)