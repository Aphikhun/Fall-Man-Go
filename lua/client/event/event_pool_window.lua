--local EventPool = EventPool
local EventPoolWindow = EventPoolWindow
local WINDOW = Define.EVENT_POOL.WINDOW
local Creator = BindableEventWindow.new
local guiMgr = L("guiMgr", GUIManager:Instance())
local ArgProcess

--用于兼容Window的EventPool子类
--代码中出现的self.super为EventPool

function EventPoolWindow:ctor(ID, Owner, EventSpace)
    self.super.ctor(self, ID, Owner, EventSpace) --EventPool:ctor
    self.__EventCreator = Creator
    self.__PoolType = WINDOW
    self.__BindsCount = {} --<CppEvent, Count>
    self.__Locks = {} --<CppEvent, Lock>
end

function EventPoolWindow:EmitEvent(CppEventName, ...)
    self:Lock(CppEventName)
    local LuaEvents = UI:ReverseEventMap(CppEventName)
    for _,LuaEvent in pairs(LuaEvents) do
        local BindableEvent = self:GetEvent(LuaEvent, "Engine", true)
        if BindableEvent then
            BindableEvent:Emit(ArgProcess(LuaEvent, ...))
        end
    end
    self:Unlock(CppEventName)
end

--用于UI旧事件
function EventPoolWindow:GetSingleEvent(EventName, Namespace, NotCreate)
    if UI:IsNewEvent(EventName) == false then
        local BindableEvent = self.super.GetEvent(self, EventName, Namespace, NotCreate)
        if BindableEvent then
            BindableEvent:SetNoMulticast()
            return BindableEvent
        end
    end
end

function EventPoolWindow:OnBind(BindableEvent)
    local EventName = BindableEvent:GetEventName()
    local CppEventName = UI:EventMap(EventName)
    if self:GetBindCount(CppEventName) <= 0 then
        local Owner = self:GetOwner()
        guiMgr:subscribeEvent(Owner.__window, CppEventName)
    end
    self:AddBindCount(CppEventName)
end

function EventPoolWindow:OnBindDestroy(BindableEvent)
    local EventName = BindableEvent:GetEventName()
    local CppEventName = UI:EventMap(EventName)
    self:ReduceBindCount(CppEventName)

    local function unsubscribe()
        local Owner = self:GetOwner()
        if self:GetBindCount(CppEventName) > 0 then
            return false
        end

        if self:IsLock(CppEventName) then
            return true
        end

        guiMgr:unsubscribeEvent(Owner.__window, CppEventName)
        return false
    end

    local result = unsubscribe()
    if result then
        World.Timer(1, unsubscribe)
    end
end

function EventPoolWindow:Lock(CppEventName)
    self.__Locks[CppEventName] = true
end

function EventPoolWindow:Unlock(CppEventName)
    self.__Locks[CppEventName] = nil
end

function EventPoolWindow:IsLock(CppEventName)
    return self.__Locks[CppEventName]
end

function EventPoolWindow:GetBindCount(CppEventName)
    return self.__BindsCount[CppEventName] or 0
end

function EventPoolWindow:AddBindCount(CppEventName)
    self.__BindsCount[CppEventName] = self:GetBindCount(CppEventName) + 1
end

function EventPoolWindow:ReduceBindCount(CppEventName)
    self.__BindsCount[CppEventName] = self:GetBindCount(CppEventName) - 1
end

local Event = Event
Event:RegisterInterface(WINDOW, "EmitEvent",function (Owner, EventName, ...)
    local Pool = Event:GetEventPool(Owner, true)
    if Pool then Pool:EmitEvent(EventName, ...) end
end)

--重写EventPool注册的GetEvent接口
Event:RegisterInterface(WINDOW, "GetEvent",function (Owner, EventName, Namespace, NotCreate)
    local Pool = Event:GetEventPool(Owner, NotCreate)
    if Pool and UI:IsNewEvent(EventName)then
        return Pool:GetEvent(EventName, Namespace, NotCreate)
    end
end)

Event:RegisterInterface(WINDOW, "GetSingleEvent",function (Owner, EventName, Namespace, NotCreate)
    local Pool = Event:GetEventPool(Owner, NotCreate)
    if Pool and UI:IsNewEvent(EventName) == false then
        local BindableEvent = Pool:GetEvent(EventName, Namespace, NotCreate)
        if BindableEvent then
            BindableEvent:SetNoMulticast()
            return BindableEvent
        end
    end
end)

local Processes = {}
ArgProcess = function(LuaEvent, ...)
    local Process = Processes[LuaEvent]
    if Process then
        local args = {...}
        return Process(args)
    else
        return ...
    end
end

local function AddArgsProcess(EventName, Process)
    Processes[EventName] = Process
end

local function Touch(args)
    local pos = Lib.v2(args[2],args[3])
    local touchID = args[6]
    return pos, touchID
end

local function Click(args)
    local pos = Lib.v2(args[2],args[3])
    return pos
end

local function Child(args)
    return UI:getWindowInstance(args[1])
end

AddArgsProcess("OnTouchDown", Touch)
AddArgsProcess("OnTouchUp", Touch)
AddArgsProcess("OnTouchMove", Touch)
AddArgsProcess("OnClick", Click)
AddArgsProcess("OnChildAdded", Child)
AddArgsProcess("OnChildRemoved", Child)
