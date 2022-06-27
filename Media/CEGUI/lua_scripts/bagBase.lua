-- 背包槽位界面
local worldCfg = World.cfg
local bagCapacity = worldCfg.bagCap or 9
local bagCellColumn = worldCfg.bagCellColumn or 6
local bagCellConfig = worldCfg.bagCellConfig or {
    normalImage = {image = {name = "role_Panel/but_bag_cell_act"}},
    selectImage = {image = {name = "role_Panel/but_bag_cell_nor"}},
    size = 65,
    itemImageArea = {{ 0, 0 }, { 0, 0}, { 0, 50}, { 0, 50}}
}

local count = 0
local function fecthCell(cellName)
    local now = World.Now()
    cellName = cellName or "bagBase-cell-"..count.."now"..now
    count = count + 1
    local cellInstance = UI:openWindow("sampleCell", cellName, "_layouts_")
    local cellConfigSize = bagCellConfig.size
    if cellConfigSize then
        local cellWin = cellInstance:getWindow()
        cellWin:setArea2({ 0, 0 }, { 0, 0}, {0, cellConfigSize}, {0, cellConfigSize})
        cellInstance:setNormalImageArea({{ 0, 0 }, { 0, 0}, {0, cellConfigSize - 5}, {0, cellConfigSize - 5}})
    end
    if bagCellConfig.normalImage then
        cellInstance:setNormalImage(bagCellConfig.normalImage)
    end
    if bagCellConfig.selectImage then
        cellInstance:setSelectFrame(bagCellConfig.selectImage)
    end
    if bagCellConfig.itemImageArea then
        cellInstance:setItemImageArea(bagCellConfig.itemImageArea)
    end
    cellInstance:setSelect(false)
    return cellInstance
end

local function resetBagSelectData(data)
    if not Me.objID then
        return
    end
    Me:regSwapData("bagData", data)
end

function self:initItemGridView()
    local function cellClickCallBack(cellInstance)
        local selectedCell = self.selectedCell
        if selectedCell == cellInstance then
            self:resetSelect()
            return
        end
        if selectedCell and (selectedCell:getItemData() or cellInstance:getItemData()) then
            Me:switchItem(selectedCell:getData("tid"), selectedCell:getData("slot"), cellInstance:getData("tid"), cellInstance:getData("slot"))
            self:resetSelect()
            return
        end
        if selectedCell then
            selectedCell:setSelect(false)
        end
        local item = cellInstance:getData("item")
        local isValidItem = item and not item:null()
        resetBagSelectData({
            tid = cellInstance:getData("tid"), 
            slot = cellInstance:getData("slot"), 
            tray = isValidItem and item:cfg().tray,
            callbackFunc = function()
                self:resetSelect()
            end
        })
        if Me:checkNeedSwapBagItem() then
            Me:swapBagItem()
            return
        end
        cellInstance:setSelect(true)
        self.selectedCell = cellInstance
    end
    local GridLayout = self.ScrollableView.GridLayout
    GridLayout:setProperty("rowSize", bagCellColumn.."")
    local cells = self.cells
    for i = 1, bagCapacity do
        local cellInstance = fecthCell()
        cellInstance:setClickCallBack(function()
            cellClickCallBack(cellInstance)
        end)
        GridLayout:addChild(cellInstance:getWindow())
        cells[i] = cellInstance
    end
end

function self:initEvent()
    Lib.subscribeEvent(Event.EVENT_PLAYER_ITEM_MODIFY, function()
        if self.parentUI and not self.parentUI:isVisible() then
            return
        end
        self:resetSelect()
        self:onUpdate()
    end)

end

function self:init()
    self.selectedCell = false
    self.isOpen = false
    self.parentUI = false
    self.cells = {}
    self:initItemGridView()
    self:initEvent()
end
-----------------------------
-----------------------------
-----------------------------
function self:resetSelect()
    if self.selectedCell then
        self.selectedCell:setSelect(false)
        self.selectedCell = false
    end
    resetBagSelectData(nil)
end

function self:resetBagView()
    for _, cellInstance in pairs(self.cells)  do
        cellInstance:resetCell()
    end
    self:resetSelect()
end

function self:fetchPlayerInfo()
    self:resetBagView()
    local trayArray = Me:tray():query_trays({ Define.TRAY_TYPE.BAG})
	if not trayArray or not trayArray[1] then
		return
	end
    local tid, tray = trayArray[1].tid , trayArray[1].tray
    local cells = self.cells
    for slot = 1, bagCapacity do
        local item = tray:fetch_item_generator(slot)
        if item:null() then
            item = nil
        end
        local instance = cells[slot]
        instance:setItemData(item)
        instance:setData("tid", tid)
        instance:setData("slot", slot)
        if item and not item:null() then
            instance:showRightBottomText(item:stack_count())
        end
    end
end

function self:onUpdate()
    self:fetchPlayerInfo() 
end

function self:onOpen(packet)
    self.isOpen = true
    self.parentUI = packet.parentUI or false
    self:setVisible(true)	
    self:fetchPlayerInfo() 
end

function self:onClose()
    self.isOpen = false
    self:setVisible(false)
end

self:init()

print("bagBase startup ui")