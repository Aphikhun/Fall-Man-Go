local sin = math.sin
local cos = math.cos
local rad = math.rad
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())

local rotationV3 = {x = 0, y = 0, z = 1} -- 绕正Z轴旋转(正对屏幕)
local function rotationToQuaternion(v3, rotation)
    local halfRotation = 0.5 * rotation
    local halfSin = sin(halfRotation)
    return {w = cos(halfRotation), x = v3.x * halfSin, y = v3.y * halfSin, z = v3.z * halfSin}
end

local function setImage(self, property, image, resourceGroup) -- image 的参数参考注释的 test code
    self:setImage(image.name, resourceGroup or "_imagesets_")
end

function self:resetMaskImage(imageConfig)
    if not imageConfig then
        return
    end

    local leftImage = self.LeftMaskBase.MaskImage
    local rightImage = self.RightMaskBase.MaskImage

    if imageConfig.leftImage then
        setImage(leftImage, "Image", imageConfig.leftImage, imageConfig.resourceGroup)
    end
    if imageConfig.rightImage then
        setImage(rightImage, "Image", imageConfig.rightImage, imageConfig.resourceGroup)
    end

    if imageConfig.scale then
        local scale = imageConfig.scale
        leftImage:setWidth({self.leftImageOriginWidth[1] * scale, self.leftImageOriginWidth[2] * scale})
        leftImage:setHeight({self.leftImageOriginHeight[1] * scale, self.leftImageOriginHeight[2] * scale})
        rightImage:setWidth({self.rightImageOriginWidth[1] * scale, self.rightImageOriginWidth[2] * scale})
        rightImage:setHeight({self.rightImageOriginHeight[1] * scale, self.rightImageOriginHeight[2] * scale})
    end
end

function self:resetMaskPivot()
    self.LeftMaskBase.MaskImage:setProperty("PivotX", 1)
    self.RightMaskBase.MaskImage:setProperty("PivotX", 0)
end

function self:initSelfProperty()
    local leftImage = self.LeftMaskBase.MaskImage
    local rightImage = self.RightMaskBase.MaskImage
    self.leftImageOriginWidth = leftImage:getWidth()
    self.leftImageOriginHeight = leftImage:getHeight()
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
    local q = rotationToQuaternion(rotationV3, rad(180))
    self.LeftMaskBase.MaskImage:setProperty("Rotation", "w:"..q.w.." x:"..q.x.." y:"..q.y.." z:"..q.z)
    self.LeftMaskBase.MaskImage:setVisible(true)
    self.RightMaskBase.MaskImage:setProperty("Rotation", "w:"..q.w.." x:"..q.x.." y:"..q.y.." z:"..q.z)
    self.RightMaskBase.MaskImage:setVisible(true)
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
    -- clockwise = true -- test code
    local timeTick = params.timeTick or 1 -- 多少帧更新一次
    local curTime = params.curTime or beginTime
    local callback = params.callback
    local mask = 1 - (curTime - beginTime) / (endTime - beginTime)
    local upMask = 1 / ((endTime - beginTime) / timeTick)
    local Right = clockwise and self.LeftMaskBase.MaskImage or self.RightMaskBase.MaskImage
    local Left = clockwise and self.RightMaskBase.MaskImage or self.LeftMaskBase.MaskImage

    local leftQ
    maskTick = function()
        mask = mask - upMask
        if mask < 0 then
            local rightQ = rotationToQuaternion(rotationV3, rad(0))
            Right:setProperty("Rotation", "w:"..rightQ.w.." x:"..rightQ.x.." y:"..rightQ.y.." z:"..rightQ.z)
            if callback then
                callback()
            end
            return false
        end
        if mask < 0.5 then
            if not leftQ then
                leftQ = rotationToQuaternion(rotationV3, rad(0))
                Left:setProperty("Rotation", "w:"..leftQ.w.." x:"..leftQ.x.." y:"..leftQ.y.." z:"..leftQ.z)
            end
            local deg = clockwise and ((0.5 - mask) * 360 + 180) or ((mask - 0.5) * 360 + 180)
            local q = rotationToQuaternion(rotationV3, rad(deg))
            Right:setProperty("Rotation", "w:"..q.w.." x:"..q.x.." y:"..q.y.." z:"..q.z)
        else
            local deg = clockwise and ((1 - mask) * 360 + 180) or (mask * 360 + 180)
            local q = rotationToQuaternion(rotationV3, rad(deg))
            Left:setProperty("Rotation", "w:"..q.w.." x:"..q.x.." y:"..q.y.." z:"..q.z)
        end
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


















