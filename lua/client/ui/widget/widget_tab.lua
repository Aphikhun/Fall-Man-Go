---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by work.
--- DateTime: 2019/9/29 10:53
---
local widget_base = require "ui.widget.widget_base"
local M = Lib.derive(widget_base)

local tabType = {
    Left = 1,
    Top = 2
}

function M:init(type, interval)
    widget_base.init(self, "widget_tab.json")

    self._container = self:child("widget_tab-container")
    self._container:SetMoveAble(false)

    --todo 根据type创建不同类型的tab页 (左/顶)
    self.type = tabType[type] or tabType.Top
    self._container:InitConfig(interval, interval, self.type == 1 and 1 or 6)
    self._container:SetAutoColumnCount(false)
    self.width = { 0, 150 }
    self.height = { 0, 65 }
    self.normalImage = "set:app_shop_new.json image:btn_tab_normal"
    self.pushImage = "set:app_shop_new.json image:btn_tab_pushed"
end

function M:AREA(xPos, yPos, width, height)
    self:root():SetArea(xPos or { 0, 0 }, yPos or { 0, 0 }, width or { 1, 0 }, height or { 1, 0 })
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

--添加tab页内的radioButton
function M:ADD_BUTTON(langKey, proc, color, borderColor, font)
    local index = self._container:GetItemCount()
    local radioBtn = GUIWindowManager.instance:CreateGUIWindow1("RadioButton", "Tab-Name-" .. index)
    radioBtn:SetArea({ 0, 0 }, { 0, 0 }, self.width, self.height)
    radioBtn:SetNormalImage(self.normalImage)
    radioBtn:SetPushedImage(self.pushImage)
    if self.stretch then
        radioBtn:SetProperty("StretchType", "NineGrid")
        radioBtn:SetProperty("StretchOffset", self.stretch)
    end
    local radioName = GUIWindowManager.instance:CreateGUIWindow1("StaticText", "Tab-Btn-Name-" .. index)
    radioName:SetArea({ 0, 0 }, { 0, 0 }, { 1, 0 }, { 1, 0 })
    if color then
        radioName:SetTextColor(color)
    end
    if borderColor then
        radioName:SetTextBoader(borderColor)
    end
    if font then
        radioName:SetProperty("Font", font)
    end
    radioName:SetTextHorzAlign(1)
    radioName:SetTextVertAlign(1)
    radioName:SetProperty("TextRenderOffset", "0 -5")
    radioName:SetText(Lang:toText(langKey))
    radioBtn:AddChildWindow(radioName)
    self:lightSubscribe("error!!!!! script_client widget_tab-cell-langKey="..langKey.." radioBtn event : EventRadioStateChanged",radioBtn, UIEvent.EventRadioStateChanged, function(statu)
        if statu:IsSelected() then
            proc(statu)
        else
            if color then
                radioName:SetTextColor(color)
            end
        end
    end)
    self._container:AddItem(radioBtn)
end

--设置选中的radioBtn
function M:SELECTED(index)
    local radioBtn = self._container:GetItem(index)
    if radioBtn then
        radioBtn:SetSelected(true)
    end
end

function M:GET_CHILD_COUNT()
    return self._container:GetItemCount()
end

--清空tab页
function M:CLEAN()
    self._container:RemoveAllItems()
end

return M