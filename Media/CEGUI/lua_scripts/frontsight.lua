local setting = require "common.setting"
local lfs   = require "lfs"
local frontSightTab = L("frontSightTab",{})
local imageTab = L("imageTab",{})
-- local circleTab = L("circleTab",{})
local currenFs = L("currenFs",{})
local _onlyFpShow = L("_onlyFpShow",nil)
local stop = L("stop",nil)
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

function M:onOpen()
    self:notShow()
    self:init()
end

local function hideFeedbackImage(self)
    if self.alphaTimer then
        self.alphaTimer()
    end
    local cfg = Me:cfg().attackFeedback
    local totalTime = cfg.hideTime or 10
    self.timeLeft = totalTime
    self.alphaTimer = World.Timer(1, function()
        self.timeLeft = self.timeLeft - 1
        if self.timeLeft > 0 then
            if cfg.hideSmooth ~= false then
                self.fb_image:setAlpha(self.timeLeft/totalTime)
            end
            return true
        else
            self.fb_image:setAlpha(0)
            self.fb_image:setVisible(false)
            return false
        end
    end)
end

local function hitEntityFeedback(self, packet)
    local cfg = Me:cfg().attackFeedback
    if not cfg then
        return
    end
    if cfg.hitPlayer == false and packet.target:isControl() then
        return
    end
    if cfg.hitNpc == false and not packet.target:isControl() then
        return
    end
    local hidHeadImage = cfg.hitHeadImage or "attack_effect/hit_head"
    local hidBodyImage = cfg.hidBodyImage or "attack_effect/hit_body"
    UI:getWindowInstance(self.fb_image):setImage(GUILib.loadImage(packet.headHit and hidHeadImage or hidBodyImage))
    self.fb_image:setVisible(true)
    self.fb_image:setAlpha(1)
    hideFeedbackImage(self)
end

function M:init()
    self.fb_image = self.Crosshair_Hit_Feedback
    self.fb_image:setVisible(false)
    self.alphaTimer = false
    Lib.subscribeEvent(Event.CREATE_FRONTSIGHT, function(instance)
        self:create(instance)
    end)
    Lib.subscribeEvent(Event.DESTROY_FRONTSIGHT, function()
        self:destroy()
    end)
    Lib.subscribeEvent(Event.DIFFUSE_FRONTSIGHT, function(diffuse)
        -- 这里是是否开启准星的动态伸缩功能，暂时屏蔽掉
        -- local currenCfg = currenFs[1] 
        -- if currenCfg then
        --     diffuse = diffuse or currenCfg.moveDiffuse
        --     self:diffuse(diffuse, 1)
        --     self:Shrink(diffuse)
        -- end
    end)

    Lib.subscribeEvent(Event.FRONTSIGHT_NOT_SHOW, function()
        self:notShow()
    end)

    Lib.subscribeEvent(Event.FRONTSIGHT_SHOW, function()
        self:show()
    end)

    Lib.subscribeEvent(Event.CHECK_HIT, function(hitObj)
        self:checkHit(hitObj)
    end)

    Lib.subscribeEvent(Event.EVENT_ON_HIT_ENTITY, function(packet)
        hitEntityFeedback(self, packet)
    end)
    Lib.subscribeEvent(Event.SKILL_RELOAD, function(isCancel)
        self:reloadFeedBack(isCancel)
    end)
end

function M:reloadFeedBack(isCancel)
    -- TODO: 显示圆形进度条，并且给其设置遮罩
end

function M:create(instance)
    local from = instance.from
    local cfg = instance.cfg
    if frontSightTab[1] or currenFs[1] then
        self:removeChild(frontSightTab[1])
        frontSightTab[1] = nil
        currenFs[1] = nil
    end
    local frontSightInstance = winMgr:createWindow("Engine/DefaultWindow", "FrontSight" .. tostring(from))
    frontSightTab[1] = frontSightInstance
    currenFs[1] = cfg
    self:addChild(frontSightInstance)
    frontSightInstance:setArea2({ 0, 0 }, { 0,  0}, { 1, 0 }, { 1, 0})
    frontSightInstance:setEnabled(false)
    for i,v in pairs(cfg.List or {})do
        if v.type=="Image" then
            self:drawFrontSightByImage(v, cfg, from)

        -- 根据配置去绘制装弹的圆形进度条
        -- elseif v.type=="Ccircle" then
            -- self:drawFrontSightByCircle(v, from)
        end
    end

    self.reloadArg = table.pack(instance)
    --切镜时重新打开准心
    self:show()

    if cfg.onlyFpShow then
        _onlyFpShow = cfg.onlyFpShow
        local view = Blockman.Instance():getCurrPersonView()
        if view~=0 then
            self:notShow()
        end
    end
end

function M:notShow()
    self:setVisible(false)
end

function M:show()
    local view = Blockman.Instance():getCurrPersonView()
    if _onlyFpShow then
        if view==0 then
            self:setVisible(true)
        else
            self:setVisible(false)
        end
    else
        self:setVisible(true)
    end
end

function M:destroy()
    if frontSightTab[1] then
        local destroy = frontSightTab[1]
        self:removeChild(destroy)
        frontSightTab[1] = nil
        currenFs[1] = nil
        imageTab[1] = nil
    end
    if stop then
        stop()
    end
    self:notShow()
end

function M:drawFrontSightByImage(imageFrontSight, frontSightCfg, fullName)
    local needReload = false
    for i,v in pairs(imageFrontSight.Image)do
        local initPos = v.initPos
        local _, imagePath = GUILib.loadImage(v.path, frontSightCfg)
        if not imagePath then 
            goto CONTINUE
        end 

        local frontSight = winMgr:createWindow("Engine/StaticImage", "FrontSight" .. tostring(imagePath) .. i)
        local frontSightIns = UI:getWindowInstance(frontSight)
        local imageSize = TextureManager.Instance():getImageWidthAndHeight(imagePath)
        if imageSize.x == -1 or imageSize.y == -1 then 
            needReload = true
            goto CONTINUE
        end
        frontSight:setHorizontalAlignment(1)
        frontSight:setVerticalAlignment(1)
        frontSight:setArea2({ 0, initPos.x }, { 0,  initPos.y}, {  0, v.width or imageSize.x }, { 0, v.height or imageSize.y})
        frontSightIns:setImage(GUILib.loadImage(imagePath))
        frontSightTab[1]:addChild(frontSight)
        imageTab[1] = imageTab[1] or {}
        table.insert(imageTab[1], frontSightIns)
        ::CONTINUE::
    end

    if needReload then 
        World.Timer(20, function()
            self:onReload(self.reloadArg)
        end)
    end
end

function M:drawFrontSightByCircle(circleFrontSightVal)
    -- TODO:用来绘制装弹时的圆形进度条
end

function M:Shrink(diffuseVal)
    local currenCfg = currenFs[1]
    if not currenCfg or not diffuseVal then
        return
    end
    local shrinkVal = currenCfg.shrinkVal
    local diffuse = diffuseVal
    local function tick()
        diffuse = (diffuse - shrinkVal) or 1
        if diffuse < currenCfg.minDiffuse then
            return false
        end
        self:diffuse(shrinkVal, 2)
       return true
    end
    stop = World.Timer(0, tick)
end

function M:diffuse(diffuse,type)
    local currenCfg = currenFs[1]
    if not currenCfg or not diffuse then
        return
    end
    if diffuse<=0 then
        return
    end
    if diffuse >= currenCfg.maxDiffuse then
        return
    end
    local toMove = 0
    local minDiffuse = currenCfg.minDiffuse
    if type==1 then
        toMove = diffuse - minDiffuse
    end
    if type==2 then
        toMove = (-diffuse)
    end
    if imageTab[1] then
        --Image
        for i,v in ipairs(imageTab[1])do
            local x = v:getXPosition()
            local y = v:getYPosition()
            --在轴上的四种情况
            if x[2]==0 and y[2]<0 then
                v:setYPosition({0,y[2] + (-toMove)})
            end
            if x[2]==0 and y[2]>0 then
                v:setYPosition({0,y[2] + toMove})
            end
            if x[2]<0 and y[2]==0 then
                v:setXPosition({0,x[2] + (-toMove)})
            end
            if x[2]>0 and y[2]==0 then
                v:setXPosition({0,x[2] + toMove})
            end
            --在象限内的四种情况
            if x[2]<0 and y[2]<0 then
                v:setXPosition({0,x[2] + (-toMove)})
                v:setYPosition({0,y[2] + (-toMove)})
            end
            if x[2]>0 and y[2]<0 then
                v:setXPosition({0,x[2] + toMove})
                v:setYPosition({0,y[2] + (-toMove)})
            end
            if x[2]<0 and y[2]>0 then
                v:setXPosition({0,x[2] + (-toMove)})
                v:setYPosition({0,y[2] + toMove})
            end
            if x[2]>0 and y[2]>0 then
                v:setXPosition({0,x[2] + toMove})
                v:setYPosition({0,y[2] + toMove})
            end
        end
    end

    -- TODO:在这里给设置圆形进度条的进度值toMove
end

function M:checkHit(hitObj)
    local _type = hitObj._type
    local friend = hitObj.friend
    local currenCfg = currenFs[1]
    if not currenCfg or not imageTab or not imageTab[1] then
        return
    end
    local images = {}
    for i,v in pairs(currenCfg.List)do
        if v.type == "Image" then
            images = v.Image
            break
        end
    end
    if  _type=="MISS" or not hitObj.canAttackTarget then
        for j,k in ipairs(imageTab[1])do
            if j <= #images then
                local imagePath = GUILib.loadImage(images[j].path, currenFs[1])
                k:setImage(GUILib.loadImage(imagePath))
            end
        end
    elseif _type=="ENTITY" and friend then
        for j,k in ipairs(imageTab[1])do
            if j <= #images then
                local imagePath = GUILib.loadImage(images[j].hitFriendlyPath or images[j].path, currenFs[1])
                k:setImage(GUILib.loadImage(imagePath))
            end
        end
    elseif _type=="BLOCK" or _type=="ENTITY" then
        for j,k in ipairs(imageTab[1])do
            if j <= #images then
                local imagePath = GUILib.loadImage(images[j].hitPath or images[j].path, currenFs[1])
                k:setImage(GUILib.loadImage(imagePath))
            end
        end
    end
end

function M:onReload(reloadArg)
    local _instance = table.unpack(reloadArg or {}, 1, reloadArg and reloadArg.n)
    self:create(_instance)
end

return M
