---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by work.
--- DateTime: 2019/5/20 14:12
---
local widget_base = require "ui.widget.widget_base"
local bm = Blockman.Instance()
local gs = GUISystem.instance

local M = Lib.derive(widget_base)

function M:init()
    widget_base.init(self, "widget_reward.json")

    self._reward_content = self:child("widget_reward-content")
    self._reward_content:InitConfig(0, 0, 4)
    self._reward_content:HasItemHidden(false)
    self._reward_content:SetAutoColumnCount(false)

    self._itemBg = "set:gui_task.json image:reward_bg.png"
    self._itemBgOffset = "10 10 10 10"
    self._itemCountBg = "set:gui_task.json image:reward_num_bg.png"
    self._itemCountBgOffset = "10 10 10 10"
    self._itemCountArea = { { 0, 0 }, { 1, 0 }, { 1, 0 }, { 0, 25 } }
end

function M:refreshTemplate(template, icons, reward, layout, times, showCount)
    local itemIcon = template:GetChildByIndex(0)
    local itemCountLayout = template:GetChildByIndex(1)
    local itemCount = itemCountLayout:GetChildByIndex(0)
    template:SetBackImage(self._itemBg)
    template:SetProperty("StretchOffset", self._itemBgOffset)
    itemCountLayout:SetArea(table.unpack(self._itemCountArea))
    itemCountLayout:SetBackImage(self._itemCountBg)
    itemCountLayout:SetProperty("StretchOffset", self._itemCountBgOffset)
    local icon = icons.icon or ResLoader:getIcon(reward.type, reward.name)
    itemIcon:SetImage(icon)
    local range = reward.countRange
    local count = icons.count or reward.count
    if range then
        itemCount:SetText(range.min .. "-" .. range.max)
        itemCount:SetProperty("AllShowOneLine", "true")
        if itemCount:GetWidth()[2] > itemCountLayout:GetWidth()[2] then
            itemCountLayout:SetWidth({ 0, itemCount:GetWidth()[2] + 5 })
        end
    elseif count then
        itemCount:SetText(count * (times or 1))
        itemCount:SetProperty("AllShowOneLine", "true")
        if itemCount:GetWidth()[2] > itemCountLayout:GetWidth()[2] then
            itemCountLayout:SetWidth({ 0, itemCount:GetWidth()[2] + 5 })
        end
    else
        itemCountLayout:SetVisible(false)
    end
    if showCount ~= nil then
        itemCountLayout:SetVisible(showCount)
    end
end

-- ** count 显示多少个   showCount 是否展示下标数量
function M:SHOW(rewardPath, cfg, layout, count, showCount)
    local reward, _cfg, icons = ResLoader:rewardContent(rewardPath, cfg)
    for i, r in ipairs(reward) do
        if count and i > count then
            return
        end
        local _icons = icons[i]
        if not _icons then
            return
        end
        local tem = GUIWindowManager.instance:CreateWindowFromTemplate("Widget-Reward-Item-" .. i, "TaskRewardItem.json")
        self:refreshTemplate(tem, _icons, r, layout, false, showCount)
        self._reward_content:AddItem(tem)
    end
    if layout then
        layout:CleanupChildren()
        layout:AddChildWindow(self._reward_content)
    end
end

function M:REWARD(reward, count, layout, times)
    for i, r in ipairs(reward) do
        if count and i > count then
            return
        end
        local tem = GUIWindowManager.instance:CreateWindowFromTemplate("Widget-Reward-Item-" .. i, "TaskRewardItem.json")
        self:refreshTemplate(tem, r, r.data, layout, times)
        self._reward_content:AddItem(tem)
    end
    if layout then
        layout:AddChildWindow(self._reward_content)
    end
end

function M:RESET()
    self._reward_content:RemoveAllItems()
end

function M:INIT_CONFIG(hInterval, vInterval, rowSize)
    self._reward_content:InitConfig(hInterval, vInterval, rowSize)
end

function M:SET_ITEM_BG(path, offset)
    self._itemBg = path
    self._itemBgOffset = offset
end

function M:SET_ITEM_COUNT_BG(path, offset)
    self._itemCountBg = path
    self._itemCountBgOffset = offset
end

function M:COUNT_AREA(area)
    self._itemCountArea = area
end

function M:MOVE_ABLE(move)
    self._reward_content:SetMoveAble(move == nil or move and true)
end

function M:onInvoke(key, ...)
    local fn = M[key]
    assert(type(fn) == "function", key)
    return fn(self, ...)
end

return M