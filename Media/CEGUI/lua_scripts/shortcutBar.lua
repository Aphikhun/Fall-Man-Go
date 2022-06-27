-- 快捷栏 
local worldCfg = World.cfg

local hideItemBar = worldCfg.hideItemBar
local isEditor =  World.CurWorld.isEditor
local isShow = not (hideItemBar or isEditor)

local cups = worldCfg.handBagCap or 9
local shortcutBarConfig = worldCfg.shortcutBarConfig or
{
    cupSize = { x = 60, y = 69},
    cupInterval = 5, -- 快捷栏槽位间隔
    cupSink = 5, -- cell在创建时往下沉多少，在被点击时又浮动起来,
    itemImageArea = {{ 0, 0 }, { 0, -5}, { 0, 50}, { 0, 50}}
}

function self:initProperty()
    self.ItemCellBase:setMousePassThroughEnabled(true)

    self.itemInstances = {}
    self.selectCell = false
    self.itemCDTimeMap = false
    self.delayTimer = false
end

function self:initBg()
    local ItemCellBaseSizeX = self.ItemCellBase:getPixelSize().width
    local targetSizeX = (shortcutBarConfig.cupSize.x + shortcutBarConfig.cupInterval) * cups
    local baseX = self:getPixelSize().width
    local baseY = self:getPixelSize().height
	local imcSize = baseX - ItemCellBaseSizeX
    self:setArea2(self:getXPosition(), self:getYPosition(), {0, targetSizeX + imcSize}, {0, baseY})
end

local function resetBagSelectData(data)
    Me:regSwapData("shortcutBarData", data)
end

function self:initCups()
    local cupInterval = shortcutBarConfig.cupInterval
    local cupSize = shortcutBarConfig.cupSize
    local cupSink = shortcutBarConfig.cupSink
    local itemImageArea = shortcutBarConfig.itemImageArea
    local ItemCellBase = self.ItemCellBase
    local itemInstances = self.itemInstances

    ItemCellBase:setHorizontalAlignment(0)
    ItemCellBase:setVerticalAlignment(2)
    for i = 1, cups do
        local x = cupInterval + (i - 1) * (cupSize.x + cupInterval)
        local cellName = "shortcutBar-ItemCellBase-cell"..i
        local cellInstance = UI:openWindow("sampleCell", cellName, "_layouts_")
        cellInstance:initMask(cellName)
        cellInstance:enableSelectLight(true)
        if itemImageArea then
            cellInstance:setItemImageArea(itemImageArea)
        end

        local cellWin = cellInstance:getWindow()
        cellInstance:setClickCallBack(function()
            local item = cellInstance:getData("item")
            local isValidItem = item and not item:null()
            local tid = cellInstance:getData("tid")
            local slot = cellInstance:getData("slot")
            resetBagSelectData({
                tid = tid,
                slot = slot,
                tray = isValidItem and item:cfg().tray,
                callbackFunc = function()
                    self:resetSelect()
                end
            })
            if Me:checkNeedSwapBagItem() then
                Me:swapBagItem()
                return
            end

            local curSelect = self.selectCell
            if curSelect and curSelect ~= cellInstance then
                curSelect:setSelect(false)
                curSelect:getWindow():setYPosition({0, cupSink})
            end
            self.selectCell = cellInstance
            cellWin:setYPosition({0, 0})
            cellInstance:setSelect(true)

            -- TODO open itemDetail
            if isValidItem and item:cfg().fastUse then
                Skill.Cast("/useitem", {slot = slot, tid = tid})
            else
                Me:setHandItem(item)
            end
        end)

        cellInstance:setLongTouchCallBack(function()
            local item = cellInstance:getData("item")
            if not item or item:null() then
                return
            end
            local canAbandon = item:cfg().canAbandon
            if item:is_block() then
                canAbandon = item:block_cfg().canAbandon
            end
            if canAbandon or worldCfg.allCanAbandon then
                Me:sendPacket({pid = "AbandonItem", tid = item:tid(), slot = item:slot()})
            end
        end)

        cellWin:setArea2({0, x}, {0, cupSink}, {0, cupSize.x}, {0, cupSize.y})
        ItemCellBase:addChild(cellWin)
        itemInstances[i] = cellInstance
    end
end

local function updateAllItemMask(self)
    self.delayTimer = false
    local now = World.Now()
    local itemCDTimeMap = self.itemCDTimeMap
    if not itemCDTimeMap or not next(itemCDTimeMap) then
        return
    end
    for _, cellInstance in pairs(self.itemInstances) do
        local item = cellInstance:getItemData()
        if item and not item:null() then
            local fullName = item:cfg().fullName
            local itemCd = itemCDTimeMap[fullName] or {}
            local endTick = itemCd.endTick
            if itemCd.startTick and endTick and endTick > now then
                cellInstance:showMask({
                    beginTime = itemCd.startTick,
                    endTime = endTick,
                    curTime = now,
                })
            end
        else
            cellInstance:resetMask()
        end
    end
end


function self:initEvent()
    self.OpenBagItem.onMouseClick = function()
        local win = UI:isOpenWindow("appMainRole")
        if win then
            win:onOpen()
        end
    end

    self.unsubItemLoaded = Lib.subscribeEvent(Event.EVENT_PLAYER_ITEM_LOADED, function()
        self:updateCells()
    end)

    self.unsubItemModify = Lib.subscribeEvent(Event.EVENT_PLAYER_ITEM_MODIFY, function()
        self:updateCells()
    end)

    Lib.subscribeEvent(Event.EVENT_UPDATE_ITEM_CD_MASK, function(value)
        if value then
            self.itemCDTimeMap = value or false
        end
        if self.delayTimer then
            return
        end
        self.delayTimer = World.Timer(5, updateAllItemMask, self)
    end)
end

function self:init()
    if not isShow then
        self:setVisible(false)
        return
    end
    self:initProperty()
    self:initBg()
    self:initCups()
    self:initEvent()
end

function self:getSeleceCell()
    return self.selectCell
end

function self:resetSelect()
    if self.selectCell then
        self.selectCell:setSelect(false)
        self.selectCell:getWindow():setYPosition({0, shortcutBarConfig.cupSink})
        self.selectCell = false
    end
    Me:setHandItem()
    resetBagSelectData()
end

function self:resetCells()
    local itemInstances = self.itemInstances
    for i = 1, #itemInstances do
        itemInstances[i]:resetCell()
        itemInstances[i]:getWindow():setYPosition({0, shortcutBarConfig.cupSink})
    end
end

function self:getCellItemCenterBottomText(item)
    local container = item:container()
    if not container then
        return ""
    end
    local currentCapacity = item:getValue("currentCapacity") or container.initCapacity or 0
    local maxCapacity = container.maxCapacity + (item:getValue("extCapacity") or 0)
    local totalCapacity = container.isShowTotal and (container.totalCapacity or Me:tray():find_item_count(container.reloadName, container.reloadBlock)) or maxCapacity
    return currentCapacity .. "/" .. totalCapacity
end

function self:updateCells()
    self:resetCells()
	local trayArray = Me:tray():query_trays(Define.TRAY_TYPE.HAND_BAG)
    local itemInstances = self.itemInstances
	local idx = 0
    for _, element in pairs(trayArray) do
        local tid, tray = element.tid, element.tray
        local items = tray:query_items()
        for slot, cellInstance in ipairs(itemInstances) do
            cellInstance:setData("tid", tid)
            cellInstance:setData("slot", slot)
            local item = items[slot]
            if item and not item:null() then
                cellInstance:setItemData(item)
                cellInstance:showRightBottomText(item:stack_count())
                cellInstance:showCenterBottomText(self:getCellItemCenterBottomText(item))
            end
		end
    end
    local selectCell = self.selectCell
    if selectCell then
        selectCell:setSelect(true)
        selectCell:getWindow():setYPosition({0, 0})
        local item = selectCell:getData("item")
        local isValidItem = item and not item:null()
        resetBagSelectData({
            tid = selectCell:getData("tid"),
            slot = selectCell:getData("slot"),
            tray = isValidItem and item:cfg().tray,
            callbackFunc = function()
                self:resetSelect()
            end
        })
        Me:setHandItem(selectCell:getItemData("item"))
    end
    Lib.emitEvent(Event.EVENT_UPDATE_ITEM_CD_MASK)
end

function self:onOpen()

end

function self:onClose()
    if self.unsubItemLoaded then
        self.unsubItemLoaded()
        self.unsubItemLoaded = nil
    end
    if self.unsubItemModify then
        self.unsubItemModify()
        self.unsubItemModify = nil
    end
end

self:init()
print("shortcutBar startup ui")