local setting = require "common.setting"

local snipeSwitch = L("snipeSwitch", nil)
local snipeDistance = L("snipeDistance", 0)
local changeFov = L("changeFov", 0)
local fov = L("fov", 0)
local snipeCfg
local originViewMode
local hideSnipeImg = L("hideSnipeImg", false)

function M:checkHit(hitObj)
    local type = hitObj._type
    local friend = hitObj.friend
    if friend or type == "MISS" then
        self.snipeMask:setEnabled(false)
    else
        self.snipeMask:setEnabled(true)
    end
end

function M:init()
    self.snipeMask = self:child("Snipe_snipe_show")
    self.snipeSwitchBtn = self:child("Snipe_snipe_switch")
    self.eventSub = {}
    self.snipeSwitchBtn.onMouseClick = function()
        if not snipeSwitch then
            self:openSnipe()
        else
            self:closeSnipe()
        end
    end
    
    self.eventSub[#self.eventSub + 1] = Lib.subscribeEvent(Event.RESET_SNIPE, function()
        self:closeSnipe()
    end)

    self.eventSub[#self.eventSub + 1] = Lib.subscribeEvent(Event.EVENT_SHOW_RELOAD_PROGRESS, function(packet)
        if snipeCfg.exitWhenReload then
            self:closeSnipe()
            local reloadTime = packet.cfg.reloadTime or 20
            if packet.method ~= "Cancel" and reloadTime > 0 then
                self.snipeSwitchBtn:setEnabled(false)
                if self.reloadTimer then
                    self.reloadTimer()
                    self.reloadTimer = nil
                end
                self.reloadTimer = World.Timer(reloadTime, function()
                    self.snipeSwitchBtn:setEnabled(true)
                end)
            end
        end
    end)
    self.eventSub[#self.eventSub + 1] = Lib.subscribeEvent(Event.CHECK_HIT, function(hitObj)
        self:checkHit(hitObj)
    end)
end

function M:initData(cfg, skill)
    if not cfg then
        self:closeSnipe()
        self.close()
        return
    end
    self.snipeMaskImage = false
    self.skillOpenIcon = false
    self.skillCloseIcon = false
    self.reloadTimer = false
    local pathCfg = skill
    if type(cfg) == "string" then
        cfg = setting:fetch("snipe", cfg)
        pathCfg = cfg
    end
    snipeCfg = cfg
    self:setLevel(cfg.level or 50)
    local iconPos = cfg.iconPos
    self.snipeSwitchBtn:setArea2({ iconPos.x, 27 }, { iconPos.y, -70}, { 0, 86}, { 0, 86 })
    -- 可配置开镜遮罩、开镜技能开启和关闭图片
    if cfg.showImage then
        self.snipeMaskImage = cfg.showImage
    end
    if cfg.openIcon then
        self.skillOpenIcon = cfg.openIcon
    end
    if cfg.closeIcon then
        self.skillCloseIcon = cfg.closeIcon
    end
    self.snipeSwitchBtn:setImage(self.skillOpenIcon or "gun/CancalAim", "_imagesets_")
    snipeSwitch = false
    hideSnipeImg = cfg.hideSnipeImg or false
end

function M:onOpen(cfg, skill)
    self:init()
    self:initData(cfg, skill)
end

function M:onClose()
    for k, eventSub in pairs(self.eventSub) do
        if eventSub then
            eventSub()
        end
    end
    self:closeSnipe()
    if self.reloadTimer then
        self.reloadTimer()
        self.reloadTimer = nil
    end
end

local function getFov()
    snipeDistance = snipeCfg.distance
    local temp = 0
    if snipeDistance==2 then
        temp = 0.4
    elseif snipeDistance==4 then
        temp = 0.8
    elseif snipeDistance==6 then
        temp = 1.2
    elseif snipeDistance==8 then
        temp = 1.6
    elseif snipeDistance==15 then
        temp = 2
    elseif snipeDistance > 0 and snipeDistance <= 2 then
        temp = snipeDistance
    end
    return temp
end

local function hideUIWhenopen(visible)
    local hideUICfg = Me:cfg().hideUIWhenOpenAim
    if not hideUICfg then
        return
    end
    local wndName = hideUICfg.windowName
    local ui = UI:isOpenWindow(wndName)
    if not ui then
        return
    end
    for _, v in pairs(hideUICfg.widgetList or {}) do
        ui:child(v):setVisible(visible)
    end
end

local function setToobarPerspeceEnable(enable)
    local toolbarIns = UI:isOpenWindow("toolbar")
    if toolbarIns then
        toolbarIns:setVisible(enable)
    end
end

function M:openSnipe()
    Blockman.instance.gameSettings:setCameraSensitive((World.cfg.cameraSensitive or 0.5) *(World.cfg.cameraSensitiveWhenOpenAim or 1))
    if not snipeCfg.showFrontSight then
        Lib.emitEvent(Event.FRONTSIGHT_NOT_SHOW)
    end
    hideUIWhenopen(false)
    originViewMode = Blockman.instance:getCurrPersonView()
    Blockman.instance:setPersonView(snipeCfg.personView or 0)
    setToobarPerspeceEnable(false)
    changeFov = Blockman.instance.gameSettings:getFovSetting()
    fov = getFov()
    Blockman.instance.gameSettings:setFovSetting(changeFov - fov)
    if not hideSnipeImg then
        self.snipeMask:setVisible(true)
        self.snipeMask:setImage(self.snipeMaskImage or "gun/SniperSight", "_imagesets_")
    end
    self.snipeSwitchBtn:setImage(self.skillCloseIcon or "gun/Aim", "_imagesets_")
    snipeSwitch = true
end

function M:isSnipeOpen()
    return snipeSwitch
end

function M:closeSnipe()
    Blockman.instance.gameSettings:setCameraSensitive((World.cfg.cameraSensitive or 0.5) )
    hideUIWhenopen(true)
    Lib.emitEvent(Event.FRONTSIGHT_SHOW)
    self.snipeMask:setVisible(false)
    changeFov = Blockman.instance.gameSettings:getFovSetting()
    Blockman.instance.gameSettings:setFovSetting(changeFov + fov)
    fov = 0
    self.snipeSwitchBtn:setImage(self.skillOpenIcon or "gun/CancalAim", "_imagesets_")
    setToobarPerspeceEnable(true)
    if originViewMode then
        Blockman.instance:setPersonView(originViewMode)
        originViewMode = nil
    end
    snipeSwitch = false
end

return M
