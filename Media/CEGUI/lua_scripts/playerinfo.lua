local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local saveBuff = {}
local customizeAreaBuff = {}
local countDownBuff = {}

local function getDefaultBoolVar(value, default)
    if not default then
        return value or false
    end
    if value == nil then
        return true
    end
    return value
end

function M:init()
    self:setMousePassThroughEnabled(true)
    self.showBuffIcon = self:child("PlayerInfo_Armor_List")
    self.showBuffCountDown = self:child("PlayerInfo_Countdown_List")
    -- 加buff时画bufficon
    Lib.subscribeEvent(Event.DRAW_BUFFICON, function(buff)
        self:drawBuffIcon(buff)
    end)
    --删buff时删bufficon
    Lib.subscribeEvent(Event.CLEAR_BUFFICON, function(buff)
        self:removeBuffIcon(buff)
    end)
    --监听加载玩家信息(头像)
    Lib.subscribeEvent(Event.LOAD_USER_DETAIL_FINISH, function(data)
        self:setUserDetail(data)
    end)
end

function M:onOpen()
    self:init()
    self:onUpdate()
end

function M:onUpdate()
    local config = World.cfg.playerInfoUI or {}
    local style = config.style
    local isShowHp = getDefaultBoolVar(config.isShowHp, true)
    local isShowFood = getDefaultBoolVar(config.isShowFood, true)
    local isShowExp = getDefaultBoolVar(config.isShowExp, true) and false --暂时不显示经验条

    local health, healthValue, healthText
    local food, foodValue, foodText
    local exp, expValue, expText
    local level
    self.topInfo = self:child("PlayerInfo_Top_Infos")
    self.btmInfo = self:child("PlayerInfo_Bottom_Infos")
    self.myInfo = self:child("PlayerInfo_MyInfo")
    if style == "top" then
        self.topInfo:setVisible(true)
        self.btmInfo:setVisible(false)
        self.myInfo:setVisible(false)
        health = self:child("PlayerInfo_Hp_Bar_Base")
        healthValue = self:child("PlayerInfo_Top_Health_Value")
        healthText = self:child("PlayerInfo_Top_Health_Text")
        food = self:child("PlayerInfo_Food_Bar_Base")
        foodValue = self:child("PlayerInfo_Top_Food_Value")
        foodText = self:child("PlayerInfo_Top_Food_Text")
        exp = self:child("PlayerInfo_Level_Bar_Base")
        expValue = self:child("PlayerInfo_Top_Exp_Value")
        expText = self:child("PlayerInfo_Top_Exp_Text")
    elseif style == "endless" then
        self.topInfo:setVisible(false)
        self.btmInfo:setVisible(false)
        self.myInfo:setVisible(true)
        level = self:child("PlayerInfo_MyLevel")
        exp = self:child("PlayerInfo_MyExp")
        expText = self:child("PlayerInfo_MyLevel_Per")
        health = self:child("PlayerInfo_MyHp")
        healthText = self:child("PlayerInfo_HpText")
        food = self:child("PlayerInfo_MyVp")
        foodText = self:child("PlayerInfo_VpText")
        healthValue = self:child("PlayerInfo_MyHp_p")
        foodValue = self:child("PlayerInfo_MyVp_p")
        expValue = self:child("PlayerInfo_MyExp_p")
    else
        self.topInfo:setVisible(false)
        self.btmInfo:setVisible(true)
        self.myInfo:setVisible(false)
        health = self:child("PlayerInfo_Bottom_Health")
        healthValue = self:child("PlayerInfo_Bottom_Health_Value")
        healthText = self:child("PlayerInfo_Bottom_Health_Text")
        food = self:child("PlayerInfo_Bottom_Food")
        foodValue = self:child("PlayerInfo_Bottom_Food_Value")
        foodText = self:child("PlayerInfo_Bottom_Food_Text")
        exp = self:child("PlayerInfo_Bottom_Exp")
        expValue = exp
        expText = exp
    end

    if World.cfg.hideItemBar then
        self.btmInfo:setYPosition({0, -10})
        self.myInfo:setYPosition({0, -30})
    end

    health:setVisible(isShowHp)
    food:setVisible(isShowFood)
    exp:setVisible(isShowExp)   

    local isNeedPoint = getDefaultBoolVar(config.isNeedPoint, false)
    local function sf(cur,max)
        local leftChar = cur >= 1000 and "k" or ""
        local rightChar = max >= 1000 and "k" or ""
        local cur = cur >= 1000 and cur/1000 or cur
        local max = max >= 1000 and max/1000 or max
        if isNeedPoint then
            return string.format("%.1f%s/%.1f%s", cur, leftChar, max, rightChar)
        else
            return string.format("%s%s/%s%s", math.ceil(cur), leftChar, math.ceil(max), rightChar)
        end
    end

    local function showHp()
        if isShowHp then
            local curHp, maxHp = math.ceil(math.max(0, Me.curHp)), math.ceil(Me:prop("maxHp"))
            healthValue:setProgress(curHp / maxHp)
            healthText:setText(sf(curHp,maxHp))
        end
    end

    local function showVp()
        if isShowFood then
            local curVp, maxVp = math.ceil(math.max(0, Me.curVp)), math.ceil(Me:prop("maxVp"))
            foodValue:setProgress(curVp / maxVp)
            foodText:setText(sf(curVp,maxVp))
        end
    end

    local function showExp()
        if isShowExp then
            local curExp, maxExp = math.max(0, Me:getValue("exp")), Me:prop("levelUpExp")
            expValue:setProgress(curExp / maxExp)
            if style == "endless" then
                local per = string.format("%.1f%%", 100 * curExp/maxExp)
                expText:setText(string.format("%s[%s]", sf(curExp,maxExp), per))
            else
                expText:setText(sf(curExp,maxExp))
            end
        end
    end
    
    showHp()
    showVp()
    showExp()
    if level then
        level:setText("Lv." .. Me:getValue("level"))
    end

    Lib.subscribeEvent(Event.ENTITY_HP_NOTIFY, function(curHp)
        if next(Me) then
            showHp()
        end
    end)

    Lib.subscribeEvent(Event.ENTITY_VP_NOTIFY, function(curVp)
        if next(Me) then
            showVp()
        end
    end)
end

local v_alignment = {LEFT = 0, CENTER = 1, RIGHT = 2, TOP = 0, CENTER = 1, BOTTOM = 2}
local H_alignment = {LEFT = 0, CENTER = 1, RIGHT = 2, TOP = 0, CENTER = 1, BOTTOM = 2}
local function customWindowArea(cell, area, progress)
    local progress = progress or 0
    if not cell or not area then
        return
    end
    local TB, LR = area.VA or 0, area.HA or 0
    local VA = area.VAlign and v_alignment[area.VAlign] or (TB >= 0 and 0 or 2)
    local HA = area.HAlign and H_alignment[area.HAlign] or (LR >= 0 and 0 or 2)
    TB = VA == v_alignment.BOTTOM and TB > 0 and TB * -1 or TB
    LR = HA == H_alignment.RIGHT and LR > 0 and LR * -1 or LR
    cell:setVerticalAlignment(VA)
    cell:setHorizontalAlignment(HA)
    cell:setArea2({ 0, LR + progress/2}, { 0, TB + progress/2}, { 0, (area.W or area.width or 70) + progress}, { 0, (area.H or area.height or 70) +progress})
end

function M:updateBuffIcon(item, bg, icon)
    item:child("IconCountDown-bg"):setImage(bg)
    item:child("IconCountDown-icon"):setImage(icon)
end

local buffIconCount = 1
function M:drawBuffIcon(buff)
    if not buff.cfg["showIcon"] then
        return
    end

    local buffCfg = buff.cfg
    local buffId = buff.id
    local buffIconName = buffCfg["showIcon"]
    local buffIcon = winMgr:createWindow("WindowsLook/StaticImage", "buffIcon_" .. buffIconCount)
    buffIconCount = buffIconCount + 1
    buffIcon:setProperty("FrameEnabled", false)
    local iconArea = buffCfg.iconArea
    if iconArea then -- buff 如果自定义位置则需要放在根位置并且是从右下角开始计算位置(同技能图标计算一样)
        buffIcon:setImage(GUILib.loadImage(buffIconName, buffCfg))
        customWindowArea(buffIcon, iconArea, buffCfg.progress)
        self:addChild(buffIcon)
        customizeAreaBuff[buffId] = buffIcon
    elseif buffCfg.countDown then 
        local item = UI:loadLayoutInstance("widget_icon_count_down", "_layouts_")
        self:updateBuffIcon(item)
        self.showBuffCountDown:addChild(item)
        self:updateCountDown(buff.time, item)
        countDownBuff[buffId] = item
    else
        buffIcon:setImage(GUILib.loadImage(buffIconName, buffCfg))
        buffIcon:setArea2({ 0, 0 }, { 0, 0 }, { 0, 50 }, { 0, 50 })
        self.showBuffIcon:addChild(buffIcon)
        saveBuff[buffId] = buffIcon
    end

    -- local time = (not buff.cfg.noMask) and buff.time
    -- if buffIconName and time then
    --     self:updateMask(time, buffIcon)
    -- elseif buffIconName then
    --     buffIcon:setMask(0)
    -- end
end

function M:updateCountDown(time, item)
    time = math.floor(time / 20)
    local function tick()
        if not item then
            return false
        end
        time = time - 1
        if time <= 0 then 
            self.showBuffCountDown:removeChild(item)
            return false
        end
        item:child("IconCountDown-txt"):setText(time.."s")
        return true
    end
    item:child("IconCountDown-txt"):setText(time.."s")
    World.Timer(20, tick)
end

-- function M:updateMask(time, buffIcon)
--     local mask = 1
--     local upMask = 1 / (time / 1)
--     local function tick()
--         if not buffIcon then
--             return false
--         end
--         mask = mask - upMask
--         if mask >= 1 then
--             buffIcon:setMask(1)
--             return false
--         end
--         buffIcon:setMask(mask)
--         return true
--     end
--     World.Timer(1, tick)
-- end

function M:removeBuffIcon(buff)
    if saveBuff[buff.id] then
        self.showBuffIcon:removeChild(saveBuff[buff.id])
        saveBuff[buff.id] = nil
    end
    if customizeAreaBuff[buff.id] then
        self:removeChild(customizeAreaBuff[buff.id])
        customizeAreaBuff[buff.id] = nil
    end
    if countDownBuff[buff.id] then
        self.showBuffCountDown:child(countDownBuff[buff.id])
        countDownBuff[buff.id] = nil
    end
end

function M:setUserDetail(data)
    -- if data.picUrl and #data.picUrl > 0 then
        -- local headIcon = self:child("PlayerInfo_Top_Player_Icon")
        -- headIcon:SetImageUrl(data.picUrl)
    -- end
end
