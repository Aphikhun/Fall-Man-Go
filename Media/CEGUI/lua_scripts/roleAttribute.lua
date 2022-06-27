
local setting = require "common.setting"

local guiMgr = L("guiMgr", GUIManager:Instance())
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local worldCfg = World.cfg
local takeOffButtonText = "win.panel.takeoff"
local characterPropPanelConfig = worldCfg.characterPropPanelConfig or {
    column = 2,
    size = {x = 200, y = 40},
    font = ""
} 
local equipCellConfig = worldCfg.equipCellConfig or {
    trays = 4,
    positions = {
        {x = 31, y = 50 },
        {x = 401, y = 50 },	  
        {x = 31, y = 156 },	  
        {x = 401,  y = 156 }
    },
    normalImage = {image = {name = "role_Panel/icon_chara_cell_nor"}},
    selectImage = {image = {name = "role_Panel/icon_chara_cell_act"}},
    size = 83,
    itemImageArea = {{ 0, 0 }, { 0, 0}, { 0, 50}, { 0, 50}}
}
local characterEquipTrayDatas = worldCfg.characterEquipTrayDatas or { -- 该配置entity身上可以配一个 characterEquipTrayDatas，没有则用默认的
    {
        image = {name = "role_Panel/icon_helmet_none"},
        trayType = 1
    },
    {
        image = {name = "role_Panel/icon_corselet_none"},
        trayType = 2
    },
    {
        image = {name = "role_Panel/icon_leg_none"},
        trayType = 3
    },
    {
        image = {name = "role_Panel/icon_boot_none"},
        trayType =  4
    }
}
local defaultInfoValues = {
    {
      ["name"] = "gui.info.name",
      ["value"] = "name"
    },
    {
      ["name"] = "gui.info.clanname",
      ["value"] = "vars.clanName"
    },
    {
      ["name"]= "gui.info.vip",
      ["value"]= "vars.vip",
      ["langKey"]= "{.vip.name}",
      ["default"]= 0
    }
}
local defauleEntityShowModelCfg = worldCfg.entityShowModelCfg or {
    scale = 0.7,
    baseImage = {image = {name = "role_Panel/img_model_bottom"}}
}
----------------------------------
----------------------------------
----------------------------------

function self:initProp()
    self.equipCells = {}
    self.propInfoGrids = {}
    self.selectedEquip = false
    self.parentUI = false

    self.objID = Me.objID
end

local function fetchEquipCell(self, position, name)
    local equipCellSize = {0, equipCellConfig.size}
    local cellInstance = UI:openWindow("sampleCell", name, "_layouts_")
    cellInstance:getWindow():setArea2({ 0, position.x }, { 0, position.y}, equipCellSize, equipCellSize)
    if equipCellConfig.normalImage then
        cellInstance:setNormalImage(equipCellConfig.normalImage)
    end
    if equipCellConfig.selectImage then
        cellInstance:setSelectFrame(equipCellConfig.selectImage)
    end
    if equipCellConfig.itemImageArea then
        cellInstance:setItemImageArea(equipCellConfig.itemImageArea)
    end
    cellInstance:setSelect(false)
    return cellInstance
end

local function resetBagSelectData(data)
    Me:regSwapData("roleAttributeData", data)
end

function self:initEquipCells()
    local now = World.Now()
    local equipCells = self.equipCells
    local EquipPanel = self.EquipPanel
    EquipPanel:setMousePassThroughEnabled(true)
    local positions = equipCellConfig.positions
    for i = 1, equipCellConfig.trays or 4 do
        local position = positions[i] or positions[1]
        local cellInstance = fetchEquipCell(self, position, "roleAttribute-equipCell-"..i.."-now-"..now)
        EquipPanel:addChild(cellInstance:getWindow())
        equipCells[i] = cellInstance
        -- TODO 旧UI的道具飞过去的效果
        local function checkFunc(checkData)
            return checkData.tray
        end
        cellInstance:setClickCallBack(function()
            resetBagSelectData({
                tid = cellInstance:getData("tid"), 
                slot = cellInstance:getData("slot"), 
                tray = {[1] = cellInstance:getData("trayType")}
            })
            if Me:checkNeedSwapBagItem(checkFunc) then
                Me:swapBagItem()
                return
            end
            resetBagSelectData()
            local item = cellInstance:getData("item")
            if item then
                self.selectedEquip = cellInstance
                local TakeOffButton = self.TakeOffButton
                TakeOffButton:setVisible(true)
                local cellInstanceWin = cellInstance:getWindow()
                local xPos = cellInstanceWin:getXPosition()
                local yPos = cellInstanceWin:getYPosition()
                local size = equipCellConfig.size
                local width = TakeOffButton:getPixelSize().width
                TakeOffButton:setXPosition({xPos[1], (i % 2 == 0) and (xPos[2] - width) or (xPos[2] + size)})
                TakeOffButton:setYPosition(yPos)
            end
        end)
    end
end

function self:initEntityWnd()
    self:initEquipCells()

    self.PropLayout.PropScrollableView.GridLayout:setProperty("rowSize", characterPropPanelConfig.column.."")
end

function self:initEvent()
    Lib.subscribeEvent(Event.PUSH_ENTITY_INFO, function(info)
        if self.parentUI and not self.parentUI:isVisible() then
            return
        end
        self:onUpdate(info)
    end)

    self.TakeOffButton.onMouseClick = function()
        self:takeOffEquip()
    end
end

function self:lateInit()
    self:setLevel(10)

    local TakeOffButton = self.TakeOffButton
    TakeOffButton:setText(Lang:toText(takeOffButtonText))
    TakeOffButton:setVisible(false)
    TakeOffButton:setAlwaysOnTop(true)
end

function self:init()
    self:initProp()
    self:initEntityWnd()
    -- TODO 旧UI的buffList未处理
    self:initEvent()
    self:lateInit()
end

----------------------------------
----------------------------------
----------------------------------
function self:takeOffEquip()
    if not self.selectedEquip then
        return
    end
    self.TakeOffButton:setVisible(false)
    local trayArray = Me:tray():query_trays({Define.TRAY_TYPE.HAND_BAG, Define.TRAY_TYPE.BAG})
    local tid = self.selectedEquip:getData("tid")
    self.selectedEquip = false
    if not tid then
        return
    end
    for _, tray in ipairs(trayArray) do
        local destTid, bag = tray.tid, tray.tray
        local destSlot = bag:find_free()
        if destSlot then
            Me:switchItem(destTid, destSlot, tid, 1)
            return
        end
    end
    Me:sendPacket({pid = "AbandonItem", tid = tid, slot = 1})
end

function M:resetEntityEquipment(entityCfg)
    local config = Entity.GetCfg(entityCfg)
    local equipCells = self.equipCells
    local characterEquipTrayDatas = config.characterEquipTrayDatas or characterEquipTrayDatas
    for i, cellInstance in pairs(equipCells) do
        cellInstance:resetCell()
        local trayData = characterEquipTrayDatas[i]
        if trayData then
            local trays = Me:tray():query_trays(trayData.trayType)
            cellInstance:setItemImage({image = trayData.image})
            cellInstance:setData("defaultItemImage", {image = trayData.image})
            cellInstance:setData("trayType", trayData.trayType)
            cellInstance:setData("tid", trays and trays[1] and trays[1].tid or nil)
            cellInstance:setData("slot", 1)
            if not cellInstance:getWindow():isVisible() then
                cellInstance:getWindow():setVisible(true)
            end
        else
            if cellInstance:getWindow():isVisible() then
                cellInstance:getWindow():setVisible(false)
            end
        end
    end
end

function M:setEquipCells(data)
    local equipCells = self.equipCells
    for k, v in pairs(data) do
        for i, cellInstance in pairs(equipCells) do
            if k == cellInstance:getData("trayType") then
                local tid, slot, fullName, stack_count = v.tid, v.slot, v.fullName, v.stack_count
                cellInstance:setData("tid", tid)
                cellInstance:setData("slot", slot or 1)
                cellInstance:setData("fullName", fullName)
                cellInstance:showRightBottomText(stack_count or "")
                if tid and slot then
                    cellInstance:setItemData(Me:tray():fetch_tray(tid):fetch_item(slot))
                end
            end
        end
    end
end

function self:showEntityEquipment(info)
    self:resetEntityEquipment(info.cfg)
    self:setEquipCells(info.equip)
end

function self:showEntityActor(entityCfg, info)
    local Actor = self.ActorWindow.Actor
    -- Actor.onMouseClick = function() -- test code
    --     print("showEntityActor test ")
    -- end
    Actor:setActorName(info.actor or "boy.actor")
    Actor:setSkillName("idle")
    local cfg = Entity.GetCfg(entityCfg)
    local showModelCfg = cfg.showModelCfg or defauleEntityShowModelCfg
    Actor:setActorScale(showModelCfg.scale)
    if showModelCfg.baseImage then
        self.ActorBottom:setImage(showModelCfg.baseImage.image.name, showModelCfg.baseImage.resourceGroup)
    end
    local property = showModelCfg.property or {}
    for _, v in pairs(property) do
        Actor:setProperty(v.name, v.value)
    end
    local skin = EntityClient.processSkin(info.actor, info.skin)
    for k, v in pairs(skin) do
        if v == "" then
            Actor:unloadBodyPart(k)
        else
            Actor:useBodyPart(k, v)
        end
    end
end

function M:setContentValue(infoValues, cfg)
    if not infoValues then
        return
    end
    local titles = {}
    local values = {}
    local iconBases = {}
    for i, info in ipairs(cfg) do
        local value = infoValues[i]
        if not info.langKey then
            value = tostring(value)
        elseif type(info.langKey) ~= "string" then
            value = Lang:toText(value)
        elseif type(value) ~= "table" then
            value = Lang:toText({info.langKey, value})
        else
            value = Lang:toText({info.langKey, table.unpack(value, 1, #info.value)})
        end
        if info.multiply then
            value = tonumber(value) * tonumber(info.multiply)
            value = string.format("%.1f", value)
        end
        titles[i] = Lang:toText(info.name)
        values[i] = value
        iconBases[i] = info.iconBase 
    end
    local ret = {
        titles = titles,
        values = values,
        iconBases = iconBases,
    }
    return ret
end

function M:setInfoGrid(info, column)
    local titles = info.titles
    local values = info.values
    if not titles then
        return
    end
    local PropGridLayout = self.PropLayout.PropScrollableView.GridLayout
    local propPanelSize = characterPropPanelConfig.size
    local font = characterPropPanelConfig.font
    local width = propPanelSize.x
    local height = propPanelSize.y
    local propInfoGrids = self.propInfoGrids
    for i, title in ipairs(titles) do
        if values[i] == "nil" then
            values[i] = ""
        end
        if propInfoGrids[i] then
            local tempData = propInfoGrids[i]
            if not tempData.tabWindow:isVisible() then
                tempData.tabWindow:setVisible(true)
            end
            tempData.textNameWindow:setText(Lang:toText(title))
            tempData.textValWindow:setText(Lang:toText(values[i]))
        else
            local tab = winMgr:createWindow("Engine/StaticImage", "roleAttribute-tabBase-"..i)
            local textName = winMgr:createWindow("Engine/StaticText", "roleAttribute-textName-"..i)
            local textVal = winMgr:createWindow("Engine/StaticText", "roleAttribute-textText-"..i)
            PropGridLayout:addChild(tab)
            tab:setArea2(tab:getXPosition(), tab:getYPosition(), { 0, width}, { 0, height})
            textName:setArea2({ 0, 0 }, { 0, 0}, { 0, width / 2}, { 0, height})
            textName:setText(Lang:toText(title))
            textVal:setArea2({ 0, width / 2 }, { 0, 0}, { 0, width / 2}, { 0, height})
            textVal:setText(Lang:toText(values[i]))
            if font and font~="" then
                textName:setFont(font)
                textVal:setFont(font)
            end
            tab:addChild(textName)
            tab:addChild(textVal)
            propInfoGrids[i] = {tabWindow = tab, textNameWindow = textName, textValWindow = textVal}
        end
    end
    for i = #titles+1, #propInfoGrids do
        propInfoGrids[i].tabWindow:setVisible(false)
    end
end

function M:resetEntityViewInfo(info)
    if not info then
        return
    end
    local entityCfg = info.cfg
    local entity = World.CurWorld:getObject(self.objID)
    self.PropLayout.PropTitleImage.PropTitleText:setText(Lang:toText(entity and entity.name or Me.name))

    self:showEntityEquipment(info)
    self:showEntityActor(entityCfg, info)

    local config = Entity.GetCfg(entityCfg)
    if info.values then
        if not config.infoValues then
            config.infoValues = Lib.copy(defaultInfoValues)
        end
        local equipmentInfo = self:setContentValue(info.values, config.infoValues or {})
        self:setInfoGrid(equipmentInfo)
    end
end

function self:onOpen(packet)
    if not packet or not packet.info then
        return
    end
    if not Me.objID then
        return
    end
    self.objID = packet.objID or Me.objID or false
    self.openArgs = packet or false
    self.parentUI = packet.parentUI or false
    self:resetEntityViewInfo(packet.info)
    self:setVisible(true)
end

function M:onClose()
    self:setVisible(false)
end

function M:onUpdate(info)
    if not Me.objID then
        return
    end
    self.objID = info.objID or Me.objID or false
    self:resetEntityViewInfo(info)
    self:setVisible(true)
end

self:init()
print("roleAttribute startup ui")