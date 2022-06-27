local Event = Event
local BindHandler = BindHandler
local BindableEvent = BindableEvent

function BindableEvent:ctor(EventPoolID, EventName, Namespace)
    self.__PoolID = EventPoolID
    self.__EventName = EventName
    self.__Namespace = Namespace
    self.__Multicast = true --是否多播, 即允许多个绑定
    self.__Lock = false --发射事件时进入上锁状态, 发射结束解锁, 上锁状态影响事件Emit与Bind的流程
    self.__Binds = {} --<ID, BindHandler> ID仅用于销毁, 不用于查询
    self.__LockingBinds = {} --<ID, BindHandler>
    self.__SingleBind = nil --用于单播绑定
end

function BindableEvent:Destroy()
    for _,Bind in pairs(self.__Binds) do
        Bind:Destroy()
    end
    if self.__SingleBind then
        self.__SingleBind:Destroy()
    end
    self.__Binds = nil
    self.__LockingBinds = nil
    self.__SingleBind = nil
end

---@param
---@return
local errorLog = "BindableEvent:Emit call fail"
function BindableEvent:Emit(...)
    if self:IsLock() then
        Lib.logWarning("Attempt to emit a emitting event", debug.traceback())
        return
    end

    self:Lock()
    if self:IsMulticast() then
        for _,Handler in pairs(self.__Binds) do
            local Function = Handler:GetFunction()
            Lib.XPcall(Function, errorLog, ...)
        end
        self:MoveLockingBinds()
    elseif self.__SingleBind then
        local Function = self.__SingleBind:GetFunction()
        local ok, ret = Lib.XPcall(Function, errorLog, ...)
        self:Unlock()
        if ok then return ret end --单播事件允许返回值
    end
    self:Unlock()
end

---@param Function function : 绑定函数
---@return BindHandler
function BindableEvent:Bind(Function)
    local NewBind = BindHandler.new(Function)

    --多播需要考虑上锁状态, 单播不考虑直接覆盖
    if self:IsMulticast() then
        local ToTable
        if self:IsLock() then
            ToTable = self.__LockingBinds
        else
            ToTable = self.__Binds
            NewBind:Activate()
        end

        local ID = #ToTable + 1
        ToTable[ID] = NewBind
        NewBind:SetDestroy(function()
            ToTable[ID] = nil
            self:OnBindDestroy()
        end)
    else
        local OldBind = self.__SingleBind
        if OldBind then OldBind:Destroy() end
        self.__SingleBind = NewBind
        NewBind:Activate()
        NewBind:SetDestroy(function()
            self.__SingleBind = nil
            self:OnBindDestroy()
        end)
    end

    return NewBind
end

function BindableEvent:OnBindDestroy()
    --等待子类拓展
end

function BindableEvent:MoveLockingBinds()
    --调用的地方做了判断, 此处不做判断了
    --if not self:IsMulticast() then
    --    return
    --end
    for _ID,Bind in pairs(self.__LockingBinds) do
        local ID = #self.__Binds + 1
        self.__Binds[ID] = Bind
        Bind:Activate()
        Bind:SetDestroy(function()
            self.__Binds[ID] = nil
            self:OnBindDestroy()
        end)
        self.__LockingBinds[_ID] = nil
    end
end

function BindableEvent:DestroySingleBind()
    if self.__SingleBind then
        self.__SingleBind:Destroy()
    end
end

function BindableEvent:GetSingleBindFunction()
    if self.__SingleBind then
        return self.__SingleBind:GetFunction()
    end
end

function BindableEvent:ExistBind()
    if self.__SingleBind or next(self.__Binds) or next(self.__LockingBinds) then
        return true
    end

    return false
end

function BindableEvent:GetNamespace()
    return self.__Namespace
end

function BindableEvent:GetEventName()
    return self.__EventName
end

function BindableEvent:GetPoolID()
    return self.__PoolID
end

function BindableEvent:GetPool()
    return Event:GetEventPoolById(self:GetPoolID())
end

function BindableEvent:GetOwner()
    return self:GetPool():GetOwner()
end

function BindableEvent:IsMulticast()
    return self.__Multicast
end

function BindableEvent:SetNoMulticast()
    self.__Multicast = false
end

function BindableEvent:Lock()
    self.__Lock = true
end

function BindableEvent:Unlock()
    self.__Lock = false
end

function BindableEvent:IsLock()
    return self.__Lock
end


