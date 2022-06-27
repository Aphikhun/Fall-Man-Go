---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by 10184.
--- DateTime: 2020/11/16 11:09
---
local LuaTimer = T(Lib, "LuaTimer") ---@type LuaTimer
local CommonActivity = T(Lib, "CommonActivity") ---@type CommonActivity
local CommonActivityChestConfig = T(Config, "CommonActivityChestConfig") ---@type CommonActivityChestConfig

function M:init()
    WinBase.init(self, "CommonActivityMain.json")
    self:initWnd()
    self:initEvent()
end

function M:initWnd()
    self.btnEnterButton = self:child("CommonActivityMain-Enter-Button")
    self.ivRedPoint = self:child("CommonActivityMain-Red-Point")
    self.ivRedPoint:SetVisible(false)
end

function M:initEvent()
    self:subscribe(self.btnEnterButton, UIEvent.EventButtonClick, function()
        UI:openWnd("commonActivityLayout")
    end)
end

function M:checkTabsRedPoint()
    LuaTimer:schedule(function()
        self.ivRedPoint:SetVisible(UI:getWnd('commonActivityLayout'):isHaveRedPoint())
    end, 1)
end
