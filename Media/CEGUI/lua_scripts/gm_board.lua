

local worldCfg = World.cfg
local gmBoardConfig = worldCfg.gmBoardConfig or {
    gmBaseConfig = {
        area = {{0,0},{0,25},{1,0},{1,-50}}
    },
    pluginItemConfig = {
        numberOfPages = 9,
        width = {1, -10},
        height = {0, 50},
        space = 10,
    },
    menuItemConfig = {
        width = {1, 0},
        height = {0, 50},
        space = 10,
    },
    secondMenuItemConfig = {
        rowSize = 6,
        width = {0, 150},
        height = {0, 50},
        horizontalSpace = 10,
        verticalSpace = 10,
    }
}

local gmBaseConfig = gmBoardConfig.gmBaseConfig or {}
local pluginItemConfig = gmBoardConfig.pluginItemConfig or {}
local menuItemConfig = gmBoardConfig.menuItemConfig or {}
local secondMenuItemConfig = gmBoardConfig.secondMenuItemConfig or {}

local guiMgr = L("guiMgr", GUIManager:Instance())
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local string_find = string.find

-- ======================================================================== Cells Pool
local CellPoolManager = L("CellPoolManager", {})
local CellManager = L("CellManager", {})

-- ================== CellPoolManager
function CellPoolManager.getPoolCell(cellPool, runningValue, funcArgs)
    local useCount = runningValue.useCount
    local stackMax = runningValue.stackMax
    if useCount >= stackMax then
        stackMax = stackMax * 2 + 1
        runningValue.stackMax = stackMax
        CellPoolManager.expandPool(cellPool, useCount, stackMax, funcArgs)
    end
    useCount = useCount + 1
    runningValue.useCount = useCount
    return cellPool[useCount]
end

function CellPoolManager.expandPool(cellPool, curIndex, stackMax, funcArgs)
    for i = curIndex + 1, stackMax do
        cellPool[i] = funcArgs.func(table.unpack(funcArgs.args))
    end
end

function CellPoolManager.resetPoolCells(cellPool, runningValue)
    for i = 1, runningValue.useCount do
        cellPool[i]:setVisible(false)
    end
    runningValue.useCount = 0
end
-- ================== CellManager
function CellManager.createMenuItemCell(cellName, width, height)
    local image = winMgr:createWindow("Engine/StaticImage", cellName.."-image-"..winMgr:generateUniqueWindowName()) 
    image:setProperty("FrameEnabled", false)
    image:setProperty("Image", "cegui_main_page/top_toorbar_bg")
    image:setArea2({0,0},{0,0},width,height)
    image:setDestroyedByParent(false)
    image:setAlpha(0.75)
    image:setVisible(false)

    local text = winMgr:createWindow("Engine/StaticText", cellName.."-text-"..winMgr:generateUniqueWindowName()) 
    text:setProperty("FrameEnabled", false)
    text:setProperty("HorzFormatting", "CentreAligned")
    text:setProperty("VertFormatting", "CentreAligned")
    text:setArea2({0,0},{0,0},width,height)
    text:setMousePassThroughEnabled(true)
    text:setVisible(true)
    text:setProperty("TextColours", "ffffffff")

    image:addChild(text)
    local retInstance = UI:getWindowInstance(image, true)
    retInstance.setSelect = function(visible)
        text:setProperty("TextColours",visible and "ffffff00" or "ffffffff")
    end
    retInstance.setShowText = function(txt)
        text:setProperty("Text", txt)
    end
    return retInstance
end

function CellManager.createPluginItemCell(cellName, width, height)
    local ret = UI:openWindow("gm_board_plugin_cell", cellName.."-"..winMgr:generateUniqueWindowName(), "_layouts_")
    ret:setArea2({0,0},{0,0},width,height)
    ret:setDestroyedByParent(false)
    ret:setVisible(false)
    return ret
end

function CellManager:initProperty()
    self.menuItemCellPool = {}
    self.menuItemCellPoolRunningValues = {
        stackMax = 12,
        useCount = 0
    }
    self.menuItemCellPoolFuncArgs = {
        func = CellManager.createMenuItemCell,
        args = {
            "menuItemCell",
            menuItemConfig.width or {1,0},
            menuItemConfig.height or {0,50}
        }
    }

    self.secondMenuItemCellPool = {}
    self.secondMenuItemCellPoolRunningValues = {
        stackMax = 32,
        useCount = 0
    }
    self.secondMenuItemCellPoolFuncArgs = {
        func = CellManager.createMenuItemCell,
        args = {
            "secondMenuItemCell",
            secondMenuItemConfig.width or {0,150},
            secondMenuItemConfig.height or {0,50}
        }
    }

    self.pluginItemCellPool = {}
    self.pluginItemCellPoolRunningValues = {
        stackMax = pluginItemConfig.numberOfPages or 9,
        useCount = 0
    }
    self.pluginItemCellPoolFuncArgs = {
        func = CellManager.createPluginItemCell,
        args = {
            "pluginItemCell",
            pluginItemConfig.width or {1,-10},
            pluginItemConfig.height or {0, 50}
        }
    }
end

function CellManager:initCellsPool()
    CellPoolManager.expandPool(self.menuItemCellPool, 0, self.menuItemCellPoolRunningValues.stackMax, self.menuItemCellPoolFuncArgs)
    CellPoolManager.expandPool(self.secondMenuItemCellPool, 0, self.secondMenuItemCellPoolRunningValues.stackMax, self.secondMenuItemCellPoolFuncArgs)
    CellPoolManager.expandPool(self.pluginItemCellPool, 0, self.pluginItemCellPoolRunningValues.stackMax, self.pluginItemCellPoolFuncArgs)
end

function CellManager:init()
    self:initProperty()
    self:initCellsPool()
end

function CellManager:getMenuItemCell()
    return CellPoolManager.getPoolCell(self.menuItemCellPool, self.menuItemCellPoolRunningValues, self.menuItemCellPoolFuncArgs)
end

function CellManager:getSecondMenuItemCell()
    return CellPoolManager.getPoolCell(self.secondMenuItemCellPool, self.secondMenuItemCellPoolRunningValues, self.secondMenuItemCellPoolFuncArgs)
end

function CellManager:getPluginItemCell()
    return CellPoolManager.getPoolCell(self.pluginItemCellPool, self.pluginItemCellPoolRunningValues, self.pluginItemCellPoolFuncArgs)
end

function CellManager:resetMenuItemCells()
    CellPoolManager.resetPoolCells(self.menuItemCellPool, self.menuItemCellPoolRunningValues)
end

function CellManager:resetSecondMenuItemCells()
    CellPoolManager.resetPoolCells(self.secondMenuItemCellPool, self.secondMenuItemCellPoolRunningValues)
end

function CellManager:resetPluginItemCells()
    CellPoolManager.resetPoolCells(self.pluginItemCellPool, self.pluginItemCellPoolRunningValues)
end

-- **********************************************
-- **********************************************
-- **********************************************
-- **********************************************
-- **********************************************

-- ======================================================================== local
local function sortMenuList()
	local list = {}
	local typItems = {}
	local lastTyp = nil
	for _, gmlist in ipairs({GM.ServerList or {}, GM.BTSGMList or {}, GM.GMList or {}}) do
		for _, value in ipairs(gmlist) do
			local typ, name = table.unpack(Lib.splitString(value, "/"))
			if not name then
				name = typ
				typ = lastTyp
			elseif typ=="" then
				typ = lastTyp
			else
				lastTyp = typ
			end
			local item = {name = name, key = value}
			local items = typItems[typ]
			if not items then
				items = {}
				typItems[typ] = items
				table.insert(list, {typ=typ, list=items})
			end
			table.insert(items, item)
		end
	end
	return list
end
-- ======================================================================== init
function self:initProperty()
    self.curSelectMenuCell = false

    self.pluginItemCurrentPage = 1
    self.pluginTotalItemPage = 1
    self.pluginItemDataPack = false
    self.pluginItemCurrentArr = false
    self.pluginItemOldArr = false
    self.pluginItemNumOfPages = pluginItemConfig.numberOfPages or 9
end

function self:initEvent()
    self.CloseButton.onMouseClick = function()
        self:onClose()
    end

    local ContentBase = self.ContentBase
    ContentBase.PageBase.Last.onMouseClick = function()
        self.pluginItemCurrentPage = self.pluginItemCurrentPage - 1
        self:paging()
    end

    ContentBase.PageBase.Next.onMouseClick = function()
        self.pluginItemCurrentPage = self.pluginItemCurrentPage + 1
        self:paging()
    end

    ContentBase.PageBase.Goto.onMouseClick = function()
        self.pluginItemCurrentPage = tonumber(ContentBase.PageBase.GotoPage:getProperty("Text"))
        self:paging()
    end

    ContentBase.SearchBase.Find.onMouseClick = function()
        self:filter(ContentBase.SearchBase.Key:getProperty("Text"))
    end

    ContentBase.SearchBase.Clear.onMouseClick = function()
        self:clearFilter()
    end
    
    self.InputBase.Sure.onMouseClick = function()
        self.pluginItemDataPack.value = self.InputBase.InputBox:getProperty("Text")
        GM.inputBoxCallBack(Me, self.pluginItemDataPack)
        self.InputBase:setVisible(false)
    end
    
    self.InputBase.Cancel.onMouseClick = function()
        self.InputBase:setVisible(false)
    end

    Lib.subscribeEvent(Event.EVENT_SHOW_GM_LIST, function()
		self:onOpen()
    end)

    Lib.subscribeEvent(Event.EVENT_SHOW_GM_PLUGIN, function(packet)
        self.pluginItemDataPack = packet
        self.pluginItemCurrentArr = packet.list
        self.pluginItemCurrentPage = 1
        local totalPage = #packet.list // self.pluginItemNumOfPages
        self.pluginTotalItemPage = totalPage == 0 and 1 or totalPage
        self.ContentBase.SearchBase.Key:setProperty("Text", "")
        self:paging()
    end)

    Lib.subscribeEvent(Event.EVENT_SHOW_GM_INPUTBOX, function(packet)
        self.InputBase.InputBox:setProperty("Text", packet.value)
        self.pluginItemDataPack = packet
        self.InputBase:setVisible(true)
    end)
end

function self:lateInit()
    if gmBaseConfig.area then
        self:setArea2(table.unpack(gmBaseConfig.area))
    end

    local ContentBase = self.ContentBase
    ContentBase.SearchBase:setVisible(false)
    ContentBase.SearchBase.Key:setMaxTextLength(100)
    ContentBase.PageBase:setVisible(false)

    local ItemBase = ContentBase.ItemBase
    ItemBase.MenuItemListPanel.GridView:setProperty("rowSize", 1)
    ItemBase.MenuItemListPanel.GridView:setProperty("vInterval", menuItemConfig.space or 10)

    local ItemContentBase = ItemBase.ItemContentBase  
    local SecondMenuItemListPanelGV = ItemContentBase.SecondMenuItemListPanel.GridView
    SecondMenuItemListPanelGV:setProperty("rowSize", secondMenuItemConfig.rowSize or 6)
    SecondMenuItemListPanelGV:setProperty("hInterval", secondMenuItemConfig.horizontalSpace or 10)
    SecondMenuItemListPanelGV:setProperty("vInterval", secondMenuItemConfig.verticalSpace or 10)

    ItemContentBase.PluginItemListPanel.GridView:setProperty("rowSize", 1)
    ItemContentBase.PluginItemListPanel.GridView:setProperty("vInterval", pluginItemConfig.space or 10)

    self:setPluginItemShow(false)
    self.InputBase:setVisible(false)
    self.InputBase.InputBox:setMaxTextLength(100)
end

function self:init()
    self:initProperty()
    self:initEvent()

    self:lateInit()
end

-- ======================================================================== logic
function self:setPluginItemShow(visible)
    local ContentBase = self.ContentBase
    ContentBase.SearchBase:setVisible(visible)
    ContentBase.PageBase:setVisible(visible)
    ContentBase.ItemBase.ItemContentBase.PluginItemListPanel:setVisible(visible)
    ContentBase.ItemBase.ItemContentBase.SecondMenuItemListPanel:setVisible(not visible)
end

function self:updatePageContent()
    local PageBase = self.ContentBase.PageBase
    PageBase.Page:setProperty("Text", self.pluginItemCurrentPage .. "/" .. self.pluginTotalItemPage)
    PageBase.Last:setVisible(self.pluginItemCurrentPage ~= 1)
    PageBase.Next:setVisible(self.pluginItemCurrentPage ~= self.pluginTotalItemPage)

end

function self:filter(key)
    if not key or key == "" then return end
    if not self.pluginItemOldArr or not next(self.pluginItemOldArr) then
        self.pluginItemOldArr = self.pluginItemCurrentArr
    end
    local temp = {}
    for _, v in pairs(self.pluginItemOldArr) do
        if string_find(v.name, key) then
            temp[#temp + 1] = v
        end
    end
    self.pluginItemCurrentPage = 1
    self.pluginItemCurrentArr = temp
    self:paging()
end

function self:clearFilter()
    if not self.pluginItemOldArr or not next(self.pluginItemOldArr) then return end
    self.pluginItemCurrentArr = self.pluginItemOldArr
    self.pluginItemCurrentPage = 1
    self.pluginItemOldArr = {}
    self:paging()
end

function self:fillSecondMenuItemList(secondMenuItemMap)
    self:setPluginItemShow(false)

    local SecondMenuItemListGV = self.ContentBase.ItemBase.ItemContentBase.SecondMenuItemListPanel.GridView
    SecondMenuItemListGV:cleanupChildren()
    CellManager:resetSecondMenuItemCells()

    local rowSize = secondMenuItemConfig.rowSize or 6

    local count = 0
    for _, v in pairs(secondMenuItemMap.list or {}) do
        if v.key == "/" then
            for i = 1, rowSize - count do
                local cell = CellManager:getSecondMenuItemCell()
                cell.setShowText(v.name or "")
                cell:setVisible(true)
                cell:setAlpha(0)
                SecondMenuItemListGV:addChild(cell:getWindow())
                count = count + 1
            end
        else
            local cell = CellManager:getSecondMenuItemCell()
            cell.setShowText(v.name or "")
            cell:setVisible(true)
            cell:setAlpha(1)
            SecondMenuItemListGV:addChild(cell:getWindow())
            cell.onMouseClick = function()
                GM.click(Me, v.key)
            end
            count = count + 1
        end
        count = count < rowSize and count or 0
    end
end

function self:fillMenuItemList()
    local list = sortMenuList()
    local MenuItemListGV = self.ContentBase.ItemBase.MenuItemListPanel.GridView
    MenuItemListGV:cleanupChildren()
    CellManager:resetMenuItemCells()

    for k, v in pairs(list or {}) do
        local cell = CellManager:getMenuItemCell()
        cell.setShowText(v.typ or "")
        cell:setVisible(true)
        cell.setSelect(false)
        MenuItemListGV:addChild(cell:getWindow())
        cell.onMouseClick = function()
            if self.curSelectMenuCell then
                self.curSelectMenuCell.setSelect(false)
            end
            cell.setSelect(true)
            self.curSelectMenuCell = cell
            self:fillSecondMenuItemList(v)
        end
        if k==1 then
            cell.setSelect(true)
            self.curSelectMenuCell = cell
        end
    end

    self:fillSecondMenuItemList(list[1])
end

function self:paging()
    local pluginItemCurrentPage = self.pluginItemCurrentPage
    local pluginItemNumOfPages = self.pluginItemNumOfPages
    local pluginItemCurrentArr = self.pluginItemCurrentArr

    local startIdx = (pluginItemCurrentPage - 1) * pluginItemNumOfPages + 1
    local endIdx = pluginItemCurrentPage * pluginItemNumOfPages
    if endIdx > #pluginItemCurrentArr then
        endIdx = #pluginItemCurrentArr
    end

    local ContentBase = self.ContentBase
    local PluginItemListGV = ContentBase.ItemBase.ItemContentBase.PluginItemListPanel.GridView
    PluginItemListGV:cleanupChildren()
    PluginItemListGV:setArea2({0,0}, {0,0}, {1,0}, {1,0})
    CellManager:resetPluginItemCells()

    for i = startIdx, endIdx do
        local item = pluginItemCurrentArr[i]
        local cell = CellManager:getPluginItemCell()
        cell:setVisible(true)
        cell:setSureButtonCallback(function(value)
            item.value = value
            GM.listCallBack(Me, item)
        end)
        cell:setItemName(item.name)
        cell:setItemInputText(item.default)
        if item.typ == "item" then
            local item = Item.CreateItem(item.name, 1)
            local cfg = item:cfg()
            cell:setItemImage(GUILib.loadImage(cfg.icon, cfg))
        end
        if item.typ == "block" then
            local block = Item.CreateItem("/block", 1, function(block)
                block:set_block(item.name)
            end)
            cell:setItemImage(GUILib.loadImage(block:icon()))
        end
        PluginItemListGV:addChild(cell:getWindow())
    end

    self:updatePageContent()
    self:setPluginItemShow(true)
end
-- ======================================================================== open close
function self:isOpen()
    return self:isVisible()
end

function self:onOpen()
    print("gm open !")
    self:setVisible(true)
    self:setLevel(2)
	self:fillMenuItemList()
end

function self:onClose()
    print("gm close !")
    self:setVisible(false)
end

CellManager:init()
self:init()

print("gm startup ui")