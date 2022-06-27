-- 先简单处理，只看自己的，后面如有需要再加上看别人的
-- TODO 查看别人的
local worldCfg = World.cfg
local appMainRoleLevel = worldCfg.appMainRoleLevel or 20 -- 越小层级越高
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local bagMainUi = World.cfg.bagMainUi or {
    {
        tabName = "gui_main_left_tab_name_role",
        titleName = "gui_main_title_name_role",
        entityType = "ENTITY_INTO_TYPE_PLAYER",
        leftWindow = {
            openWindow = "roleAttribute",
            resourceGroup = "_layouts_"
        },
        rightWindow = {
            openWindow = "bagBase",
            resourceGroup = "_layouts_"
        }
    },
}

function self:initProp()
    self:setLevel(appMainRoleLevel)
    self:setMousePassThroughEnabled(true)

    self.leftTabInstanceList = {}

    self.leftChildWindowInstance = false
    self.rightChildWindowInstance = false
    self.curSelectInstance = false

    self.openObjID = false
    self.curCfg = false
    self.opening = false
end

function self:initEvent()
    self.Close.onMouseClick = function()
        self:onClose()
    end

    Lib.subscribeEvent(Event.FETCH_ENTITY_INFO, function()
        if not self.opening or not self.curCfg or not self:isVisible() then
            return
        end
        self:getInfoByID(self.openObjID or Me.objID, Define[self.curCfg.entityType])
    end)
end

local function createTabCell(self, name, cfg, index)
    local now = World.Now()
    local ret = UI:openWindow("rolePanelCell", name.."-rolePanelCell-now"..now, "_layouts_")
    ret:setText(Lang:toText(cfg.tabName))
    ret:setSelect(false)

    ret:setClickCallBack(function()
        self:selectItem(ret, cfg)
    end)
    return ret
end

function self:initLeftTab()
    local GridLayout = self.LeftLayout.RoleScrollableView.GridLayout
    GridLayout:setProperty("rowSize", "1")

    for index, cfg in ipairs(bagMainUi) do
        local windowName = string.format("appMainRole-tab-%d", index)
        local instance = createTabCell(self, windowName, cfg, index)
        self.leftTabInstanceList[#self.leftTabInstanceList + 1] = {instance = instance, cfg = cfg}
        GridLayout:addChild(instance:getWindow())
    end
end

function self:init()
    self:initProp()
    self:initEvent()
    self:initLeftTab()

end

---------------------------
---------------------------
---------------------------
---------------------------

function self:getInfoByID(objID, entityType)
    local function handleViewInfo(info, isCache)
        if type(info) == "table" then
            Lib.emitEvent(Event.PUSH_ENTITY_INFO, info)
            info.cache = isCache
        end
    end
	Me:sendPacket({
		pid = "QueryEntityViewInfo",
		objID = assert(objID),
		entityType = entityType,
	}, handleViewInfo)
end

function self:openWindow(cfg)
    -- TODO 缓存优化？
    if self.leftChildWindowInstance then
        UI:closeWindow(self.leftChildWindowInstance)
        self.Main.LeftLayout:removeChildAtIndex(0)
    end
    if self.rightChildWindowInstance then
        UI:closeWindow(self.rightChildWindowInstance)
        self.Main.RightLayout:removeChildAtIndex(0)
    end
    local function openWin(info)
        local leftWindowCfg = cfg.leftWindow
        local leftWindow = UI:openWindow(leftWindowCfg.openWindow, winMgr:generateUniqueWindowName(), leftWindowCfg.resourceGroup, 
        {
            isMe = true,
            entityType = cfg.entityType,
            info = info,
            objID = self.openObjID,
            parentUI = self
        })
        self.Main.LeftLayout:addChild(leftWindow:getWindow())
        self.leftChildWindowInstance = leftWindow

        local rightWindowCfg = cfg.rightWindow
        local rightWindow = UI:openWindow(rightWindowCfg.openWindow, winMgr:generateUniqueWindowName(), rightWindowCfg.resourceGroup,
        {
            parentUI = self
        })
        self.Main.RightLayout:addChild(rightWindow:getWindow())
        self.rightChildWindowInstance = rightWindow
    end
    if cfg.entityType then
        openWin()
        self:getInfoByID(self.openObjID, Define[cfg.entityType])
    else
        openWin()
    end
end

function self:selectItem(instance, cfg)
    if self.curSelectInstance then
        if self.curSelectInstance == instance then
            if cfg.entityType then
                self:getInfoByID(self.openObjID or Me.objID, Define[cfg.entityType])
            end
            if self.rightChildWindowInstance then
                self.rightChildWindowInstance:onUpdate()
            end
            return
        end
        self.curSelectInstance:setSelect(false)
    end
    instance:setSelect(true)
    self.curSelectInstance = instance
    self.TopLayout.Text:setText(Lang:toText(cfg.titleName))
    self.curCfg = cfg
    self:openWindow(cfg)
end

local isFristOpen = true
function self:onOpen(objID)
    if not Me.objID then
        return
    end
    self.openObjID = objID or Me.objID or false
    self.opening = true
    self:selectItem(self.leftTabInstanceList[1].instance, self.leftTabInstanceList[1].cfg)
    self:setVisible(not isFristOpen)
    isFristOpen = false
end

function self:onClose()
    self.opening = false
    self:setVisible(false)
end

function self:isOpen()
    return self.opening
end

self:init()
print("appMainRole startup ui")