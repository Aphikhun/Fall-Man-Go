---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by 10184.
--- DateTime: 2020/11/23 16:01
---
local LuaTimer = T(Lib, "LuaTimer") ---@type LuaTimer
local CommonActivityRewardConfig = T(Config, "CommonActivityRewardConfig") ---@type CommonActivityRewardConfig
local CommonActivityChestConfig = T(Config, "CommonActivityChestConfig") ---@type CommonActivityChestConfig

local widget_base = require "ui.widget.widget_base"
local M = Lib.derive(widget_base)

local function safeSetUI(window, key, ...)
    if window and window[key] then
        window[key](window, ...)
    end
end

function M:init(name, activity)
    widget_base.init(self, name)
    self.__name = name
    self.activity = activity
    self:initWnd()
end

function M:initWnd()
    local name = self.__name:gsub(".json", "-")
    self.tvTitle = self:child(name .. "Title")
    self.tvTime = self:child(name .. "Time")
    self.tvDesc = self:child(name .. "Desc")
    self.awActor = self:child(name .. "Actor")
    self.ivImage = self:child(name .. "Image")
    self.ivImageBox = self:child(name .. "Image-Box")
    self.tvPrice = self:child(name .. "Price")
    self.ivPriceIcon = self:child(name .. "Price-Icon")
    self.tvName = self:child(name .. "Name")

    self:root():SetVisible(false)
    self:root():SetBackImage(self.activity.background)
    safeSetUI(self.tvTitle, "SetText", Lang:getMessage(self.activity.titleLang))
    safeSetUI(self.tvDesc, "SetText", Lang:getMessage(self.activity.descLang))
    self:root():SetWidth({ 1, 0 })
    self:root():SetHeight({ 1, 0 })
    self:onChildLoad()
    self:showRewardDetail(self.activity)

    self:addTimer(LuaTimer:scheduleTimer(function()
        self:onSecondTick()
    end, 1000))

    local llSlideBlock = self:child(name .. "Actor-Slide-Block")
    safeSetUI(llSlideBlock, "subscribe", UIEvent.EventWindowTouchDown, function(window, dx, dy)
        safeSetUI(self.awActor, "TouchDown", {x = dx,y = dy})
    end)

    safeSetUI(llSlideBlock, "subscribe", UIEvent.EventWindowTouchMove, function(window, dx, dy)
        safeSetUI(self.awActor, "TouchMove", {x = dx,y = dy})
    end)

    if CommonActivityChestConfig:getChestGroupById(self.activity.chestGroupId) then
        self.wChestGroup = UIMgr:new_widget("commonActivityChestGroup", self.activity, self):invoke("get")
    end
end

function M:onSecondTick()
    if not self.activity.lastTime or self.activity.lastTime <= 0 then
        return
    end
    self.activity.lastTime = self.activity.lastTime - 1
    if self.activity.lastTime >= Lib.getDaySeconds() then
        local text = string.format(Lang:getMessage("common.activity.day"), tostring(math.floor(self.activity.lastTime / Lib.getDaySeconds())))
        safeSetUI(self.tvTime, "SetText", text)
    else
        safeSetUI(self.tvTime, "SetText", Lib.getFormatTime(self.activity.lastTime))
    end
end

function M:showRewardDetail(activity)
    local reward = CommonActivityRewardConfig:getRewardById(activity.mainRewardId)
    if not reward then
        return
    end
    safeSetUI(self.tvName, "SetText", Lang:getMessage(reward.name))
    if reward.priceIcon and #reward.priceIcon > 0 then
        if reward.price == -1 then
            safeSetUI(self.ivPriceIcon, "SetImage", "")
            safeSetUI(self.tvPrice, "SetText", "")
        else
            safeSetUI(self.ivPriceIcon, "SetImage", reward.priceIcon)
            safeSetUI(self.tvPrice, "SetText", tostring(reward.price))
            if self.tvPrice then
                local extent = self.tvPrice:GetFont():GetTextExtent(tostring(reward.price), 1)
                safeSetUI(self.ivPriceIcon, "SetXPosition", { -0.3, -extent / 2 })
            end
        end
    else
        safeSetUI(self.ivPriceIcon, "SetImage", "")
    end
    if reward.actor and #reward.actor > 7 then
        local pos
        if self.awActor and self.awActor["GetPosition"] then
            pos = self.awActor:GetPosition()
        end
        safeSetUI(self.ivImage, "SetVisible", false)
        safeSetUI(self.awActor, "SetXPosition", { pos.x[1], activity.actorXOffset })
        safeSetUI(self.awActor, "SetYPosition", { pos.y[1], activity.actorYOffset })
        safeSetUI(self.awActor, "SetWidth", { 0, activity.actorScale })
        safeSetUI(self.awActor, "SetActor1", activity.actor, "idle")
        safeSetUI(self.awActor, "SetRotateY", activity.actorRotate)

        for index, actorBody in pairs(activity.actorBody) do
            if activity.actorBodyId[index] then
                safeSetUI(self.awActor, "UseBodyPart", actorBody or "body", activity.actorBodyId[index] or "")
            end
        end
    else
        safeSetUI(self.awActor, "RemoveActor")
        safeSetUI(self.ivImage, "SetVisible", true)
        if activity.imageBox and #activity.imageBox > 10 then
            safeSetUI(self.ivImageBox, "SetImage", activity.imageBox)
        else
            safeSetUI(self.ivImageBox, "SetImage", "")
        end

        if activity.mainRewardImage and #activity.mainRewardImage > 10 then
            UIHelper:setImageAdjustSize(self.ivImage, activity.mainRewardImage, 250, 250)
        else
            safeSetUI(self.ivImage, "SetImage", "")
        end
    end

    Lib.emitEvent(Event.EventCommonActivityCheckRedPoint, activity.id)
end

function M:isNeedRedPoint()
    return false
end

function M:onChildLoad()

end

function M:onShow()

end

function M:isShow()
    return self:root():IsVisible()
end

function M:onTick()
    if self.wChestGroup then
        self.wChestGroup:onTick()
    end
end

return M