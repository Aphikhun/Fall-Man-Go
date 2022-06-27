local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local tabType = {
    Left = 1,
    Top = 2
}

-- local 

function M:onOpen(type, interval)
    self:setMousePassThroughEnabled(true)
    self:init(type, interval)
end

function M:init(type, interval)
    -- self.widget_tab_container = self:child("widget_tab-container")
    -- self.widget_tab_container:SetMoveAble(false)

    --todo 根据type创建不同类型的tab页 (左/顶)
    self.type = tabType[type] or tabType.Top
    -- self.widget_tab_container:InitConfig(interval, interval, self.type == 1 and 1 or 6)
    -- self.widget_tab_container:SetAutoColumnCount(false)
    self.width = { 0, 250 }
    self.height = { 0, 65 }
    self.normalImage = "cegui_main_page/btn_tab_normal"
    self.pushImage = "cegui_main_page/btn_tab_pushed"
end

function M:AREA(xPos, yPos, width, height)
    self:root():setArea(xPos or { 0, 0 }, yPos or { 0, 0 }, width or { 1, 0 }, height or { 1, 0 })
end

--设置radioBtn的size
function M:BTN_SIZE(width, height)
    self.width = width
    self.height = height
end

--btn图片
function M:BTN_IMAGE(normal, push)
    self.normalImage = normal or self.normalImage
    self.pushImage = push or self.normalImage
end

function M:BTN_STRETCH(stretch)
    if stretch and type(stretch) == "string" then
        self.stretch = stretch
    end
end
local function switchSelectStatu(self, proc, radioBtn)
    local itemCount = self.widget_tab_container:getChildCount()
    for i = 1, itemCount do
        local btn = self.widget_tab_container:getChildElementAtIdx(i - 1)
        btn:setProperty("Image", self.normalImage)
        btn.isSelect = false
        -- btn:getChildElementAtIdx(0):setProperty("TextColours", "ffffffff")
    end
    radioBtn.isSelect = true
    -- radioBtn:getChildElementAtIdx(0):setProperty("TextColours", "ff000000")
    if proc then
        proc(radioBtn)
    end
    radioBtn:setProperty("Image", self.pushImage)
end


--添加tab页内的radioButton
function M:ADD_BUTTON(langKey, proc, color, borderColor, font)
    local function initRadioBtn(radioBtn)
        radioBtn:setWidth(self.width)
        radioBtn:setHeight(self.height)
        radioBtn:setProperty("FrameEnabled", false)
        radioBtn:setProperty("Image", self.normalImage)
    end

    local function initRadioBtnName(radioBtnName)
        radioBtnName:setMousePassThroughEnabled(true)
        radioBtnName:setWidth({ 1, 0 })
        radioBtnName:setHeight({ 1, 0 })
        if color then
            radioBtnName:setProperty("TextColours", color)
        end
        if font then
            radioBtnName:setProperty("Font", font)
        end
        radioBtnName:setProperty("FrameEnabled", false)
        radioBtnName:setProperty("VertFormatting", "CentreAligned")
        radioBtnName:setProperty("HorzFormatting", "CentreAligned")
        radioBtnName:setText(Lang:toText(langKey))
    end

    local index = self.widget_tab_container:getChildCount()
    local radioBtn = winMgr:createWindow("WindowsLook/StaticImage", "Tab-Name-" .. index)
    initRadioBtn(radioBtn)

    local radioBtnName = winMgr:createWindow("WindowsLook/StaticText", "Tab-Btn-Name-" .. index)
    initRadioBtnName(radioBtnName)

    radioBtn:addChild(radioBtnName)
    self.widget_tab_container:addChild(radioBtn)
    self.widget_tab_container:layout()
    local radioBtnIns = UI:getWindowInstance(radioBtn)
    radioBtnIns.onMouseClick = function(radioBtn)
        switchSelectStatu(self, proc, radioBtn)
    end
end

--设置选中的radioBtn
function M:SELECTED(index)
    local radioBtn = self.widget_tab_container:getChildElementAtIdx(index)
    if radioBtn then
        switchSelectStatu(self, nil, radioBtn)
        -- radioBtn:setSelected(true)
    end
end

function M:SET_TAB_INTERVAL(interval)
    self.widget_tab_container:setSpace(interval)
end

function M:GET_CHILD_COUNT()
    return self.widget_tab_container:getChildCount()
end

--清空tab页
function M:CLEAN()
    local itemCount = self.widget_tab_container:getChildCount()
    for index = 1, itemCount do
        local itemChild = self.widget_tab_container:getChildElementAtIdx(index - 1)
        self.widget_tab_container:removeChild(itemChild)
    end
end

function M:invoke(funcName, ...)
    assert(self[funcName], "invoke not func, funcName: " .. funcName)
    return self[funcName](self, ...)
end