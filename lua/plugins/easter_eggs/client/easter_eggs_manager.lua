---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2022/3/15 17:57
---
---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2022/3/15 11:25
---

--- @class EasterEggsManager
local EasterEggsManager = T(Lib, "EasterEggsManager")

local EasterEgg = require "common.easter_eggs_obj"
local LuaTimer = T(Lib, "LuaTimer")

---@type EasterEggsRefreshPosConfig
local EasterEggsRefreshPosConfig = T(Config, "EasterEggsRefreshPosConfig")

---@type EasterEggsConfig
local EasterEggsConfig = T(Config, "EasterEggsConfig")

function EasterEggsManager:init()
    self:initClick()
    --self:initActivityDate()
    self:initMapLoaded()
end

function EasterEggsManager:initClick()

end

function EasterEggsManager:initActivityDate(resultDate)
    Lib.logDebug("resultDate  ", resultDate)

    self.isInitDate = true
    self:clearEgg()

    self.curWorldEggs = {}
    self.nextRefreshTime = 0
    self.nextClearTime = 0

    --- 随机出来的蛋的位置
    self.randomEggsPosList = {}

    self.startTime = resultDate.startTime
    self.endTime = resultDate.endTime
    self.easterStartTime = resultDate.peakStart
    self.easterEndTime = resultDate.peakEnd
    self.refreshTime = resultDate.refreshTime


    self:calcNextRefreshTime()
    Lib.logDebug("nextRefreshTime  ", os.time(), self.nextRefreshTime)

    self:initTick()
    if self.productTimer then
        LuaTimer:cancel(self.productTimer)
        self.productTimer = nil
    end
    self.productTimer = LuaTimer:scheduleTimer(function()
        self:onTick()
    end, 1000, -1)

end

function EasterEggsManager:initTick()
    local time = self.refreshTime[self.currIndex]
    if not time then
        return
    end

    local eggType = Define.EASTER_EGG_TYPE.Common
    if self:isInEaster() then
        eggType = Define.EASTER_EGG_TYPE.Advanced
    end

    self:refreshEggs(eggType, self.currIndex)
end

function EasterEggsManager:initMapLoaded()
    Lib.subscribeEvent(Event.EVENT_LOAD_WORLD_END, function()
        local map = World.CurMap
        self:changeNewMap(map)
    end)
end


function EasterEggsManager:getRefreshFrequency()
    local cfg = World.cfg.easter_eggsSetting
    if self:isInEaster() then
        return cfg.refreshFrequency.inEasterDay
    end

    return cfg.refreshFrequency.notInEasterDay
end

function EasterEggsManager:calcNextRefreshTime()
    local currTime = os.time()
    local curIndex = 0
    local count = #self.refreshTime
    for i = count, 1, -1 do
        local time = self.refreshTime[i]
        if currTime >= time then
            curIndex = i
            break
        end
    end

    self.currIndex = curIndex
    self.nextRefreshTime = self.refreshTime[curIndex + 1]
    self.nextClearTime = self.refreshTime[curIndex + 1] or self.endTime

    Lib.logDebug("nextRefreshTime  ", os.time(), self.nextClearTime, self.nextRefreshTime)

    return self.nextRefreshTime
end

function EasterEggsManager:isInEaster()
    local currTime = os.time()

    if currTime >= self.easterStartTime and currTime < self.easterEndTime then
        return true
    end
    return false
end

function EasterEggsManager:onTick()
    local curTime = os.time()
    if curTime >= self.nextClearTime then
        self:clearEgg()
        self.nextClearTime = math.maxinteger
    end

    if self.nextRefreshTime and curTime >= self.nextRefreshTime and curTime <= self.endTime then
        local cfg = World.cfg.easter_eggsSetting
        local eggType = Define.EASTER_EGG_TYPE.Common
        if self:isInEaster() then
            eggType = Define.EASTER_EGG_TYPE.Advanced
        end

        self:refreshEggs(eggType, self.currIndex + 1)
    end
end

function EasterEggsManager:refreshEggs(eggType, refreshIndex)
    if self.refreshEggsIng then
        return
    end
    self.refreshEggsIng = true
    Me:sendPacket({
        pid = "requestRefreshEasterEggs",
        refreshIndex = refreshIndex
    }, function(resp)
        --Lib.logDebug("resp == ", Lib.v2s(resp, 7), refreshIndex)
        local code = resp.code
        if code then
            self:calcNextRefreshTime()
            self:productEgg(eggType, resp.randomPosList)
        else
            if resp.index then
                if self.refreshTime[resp.index] and self.refreshTime[resp.index] >= os.time() then
                    self:refreshEggs(eggType, resp.index)
                end
            end
        end
        self.refreshEggsIng = false
    end)
end

--- 在地图上生成蛋
function EasterEggsManager:createEggs()
    local state = Me:getEasterEggState()
    local posListConfig = state[self.currIndex] or {}
    local receiveIndex = posListConfig.receiveIndex or {}

    --Lib.logDebug("randomEggsPosList ", Lib.v2s(self.randomEggsPosList, 7))

    for mapType, posList in pairs(self.randomEggsPosList) do

        local eggList = {}
        for i, config in pairs(posList) do
            local posConfig = config.posCfg
            local eggObj = EasterEgg.new(posConfig.id, config.eggId, self.nextClearTime)
            eggList[posConfig.id] = eggObj

            if receiveIndex[posConfig.id] then
                eggObj:setReceived(true)
            end
        end

        self.curWorldEggs[mapType] = eggList
    end

    self:changeNewMap(World.CurMap)
end

function EasterEggsManager:changeNewMap(map)
    local currTime = os.time()
    if not self.isInitDate or currTime < self.startTime or currTime > self.endTime then
        return
    end

    --- added
    Lib.logDebug("createEntity  ", map.name)
    for mapType, eggList in pairs(self.curWorldEggs) do
        for id, eggObj in pairs(eggList) do
            eggObj:createEntity(map)
        end
    end
end

function EasterEggsManager:randomEggsByMapType(type, randomPosList)
    local productData = {}

    for i = 1, #randomPosList do
        local config = randomPosList[i]
        --Lib.logDebug("---------", config)
        table.insert(productData, {posCfg = EasterEggsRefreshPosConfig:getCfgById(config.id), eggId = config.eggId})
    end

    self.randomEggsPosList[type] = productData
end

--- 随机出来的蛋的位置
function EasterEggsManager:randomEggs(eggType, randomPosList)
    self.randomEggsPosList = {}
    local cfg = EasterEggsRefreshPosConfig:getAllCfg()

    for mapType, data in pairs(cfg) do
        self:randomEggsByMapType(mapType, randomPosList[mapType])
    end
end

---@param eggType number 彩蛋类型：1--普通；2--高级
function EasterEggsManager:productEgg(eggType, randomPosList)
    self:randomEggs(eggType, randomPosList)
    self:createEggs()
end

function EasterEggsManager:onClickEntity(player, entity)
    for mapId, eggList in pairs(self.curWorldEggs) do
        for eggId, egg in pairs(eggList) do
            if egg then
                local obj = egg:getEntityObj()
                if obj and obj:isValid() and obj.objID == entity.objID then
                    egg:onInteract(player)
                end
            end
        end
    end
end

function EasterEggsManager:clearEgg()
    for mapType, eggList in pairs(self.curWorldEggs or {}) do
        for eggId, egg in pairs(eggList) do
            if egg then
                egg:destroy()
            end
        end
    end

    self.curWorldEggs = {}
end

---@return EasterEgg
function EasterEggsManager:getEasterEggs(mapType, id)
    local eggList = self.curWorldEggs[mapType] or {}
    for eggId, egg in pairs(eggList) do
        if egg.id == id then
            return egg
        end
    end
end

function EasterEggsManager:easterEggLimitMax()
    for mapType, eggList in pairs(self.curWorldEggs) do
        for eggId, egg in pairs(eggList) do
            egg:setReceived(true)
        end
    end
end

function EasterEggsManager:updateReceiveStatus(value)
    local posList = value[self.currIndex]

    if not posList then
        return
    end

    local receiveIndex = posList.receiveIndex

    for mapType, eggList in pairs(self.curWorldEggs) do
        for eggId, egg in pairs(eggList) do
            if receiveIndex[egg.id] then
                egg:setReceived(true)
            else
                egg:setReceived(false)
            end
            egg:createEntity(World.CurMap)
        end
    end
end

EasterEggsManager:init()
return EasterEggsManager