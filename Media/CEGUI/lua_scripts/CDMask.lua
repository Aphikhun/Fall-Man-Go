local sin = math.sin
local cos = math.cos
local rad = math.rad
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
local config_clockwise

local rotationV3 = {x = 0, y = 0, z = 1} -- 绕正Z轴旋转(正对屏幕)
local function rotationToQuaternion(v3, rotation)
    local halfRotation = 0.5 * rotation
    local halfSin = sin(halfRotation)
    return {w = cos(halfRotation), x = v3.x * halfSin, y = v3.y * halfSin, z = v3.z * halfSin}
end

local function setImage(self, image, resourceGroup, alpha) -- image 的参数参考注释的 test code
    self:setImage(image, resourceGroup or "_imagesets_")
    self:setAlpha(alpha or 1)
end


function self:getMaskWin()
    return self.MaskImage
end

function self:resetMaskImage(imageConfig)
    if not imageConfig then
        return
    end

    local rightImage = self.MaskImage

    if imageConfig.image then
        setImage(rightImage, imageConfig.image, imageConfig.resourceGroup, imageConfig.alpha or 1)
    end

    if imageConfig.scale then
        local scale = imageConfig.scale
        rightImage:setWidth({self.rightImageOriginWidth[1] * scale, self.rightImageOriginWidth[2] * scale})
        rightImage:setHeight({self.rightImageOriginHeight[1] * scale, self.rightImageOriginHeight[2] * scale})
    end

    if imageConfig.height and imageConfig.width then
        rightImage:setWidth({0,imageConfig.width})
        rightImage:setHeight({0, imageConfig.height})
    end
    
    rightImage:setProperty("ImageBlendMode", 4)
    
    if imageConfig.FillType and imageConfig.FillPosition then   
        rightImage:setProperty("FillType",imageConfig.FillType)
        rightImage:setProperty("FillPosition",imageConfig.FillPosition)
    end
    if imageConfig.AntiClockwise then
        rightImage:setProperty("AntiClockwise",imageConfig.AntiClockwise)
    end
end

function self:resetMaskPivot()
    self.MaskImage:setProperty("PivotX", 0)
end

function self:initSelfProperty()
    local rightImage = self.MaskImage
    self.rightImageOriginWidth = rightImage:getWidth()
    self.rightImageOriginHeight = rightImage:getHeight()
end

function self:init()
    self:resetMaskPivot()
    self:initSelfProperty()
end

function self:onOpen(params)
    if not params then
        return
    end
    self:resetMaskImage(params.imageConfig)
    self:setMask(params)
end

function self:onReopen(params)
    self:onOpen(params)
end

local maskTick = nil
local cdTimer = nil
function self:resetWnd()
    if cdTimer then
        cdTimer()
        cdTimer = nil
    end
    self.MaskImage:setVisible(true)
end

--[[
    imageConfig = 
    {
        leftImage = {name = xx, asset = xx}
        rightImage = {name = xx, asset = xx}
        resourceGroup = xx
        scale = xx
    }
    -- 注意：要旋转的image的Image组件的最终大小不要小于30*30，不然会因为太小而被剔除掉不显示！
]]
function self:setMask(params)
    local beginTime, endTime = params.beginTime, params.endTime
    if not beginTime or not endTime or endTime < beginTime then
        self:setVisible(false)
        self:resetWnd()
        return
    end
    self:setVisible(true)
    self:resetWnd()
    local clockwise = params.clockwise -- 顺时针
    if clockwise == nil then
        clockwise = config_clockwise
    end
    -- clockwise = true -- test code
    local timeTick = params.timeTick or 1 -- 多少帧更新一次
    local curTime = params.curTime or beginTime
    local callback = params.callback
    local mask = 1 - (curTime - beginTime) / (endTime - beginTime)
    local upMask = 1 / ((endTime - beginTime) / timeTick)
    local Right = self.MaskImage

    local leftQ
    maskTick = function()
        mask = mask - upMask
        if mask < 0 then
            self:setVisible(false)
            self:resetWnd()
            if callback then
                callback()
            end
            return false
        end

        Right:setProperty("FillArea",mask)
        return true
    end
    cdTimer = World.Timer(timeTick, maskTick)
    return 
end

function self:onClose()
    if cdTimer then
        cdTimer()
        cdTimer = nil
    end
end

self:init()


















