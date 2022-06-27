--[[
Root
    NorImage
    SecLayout
        SecFrame
        SecLight
    ItemImage
    RightBottomText
    CenterBottomText
]]

local worldCfg = World.cfg
local longTouchTickTime = worldCfg.longTouchTickTime or 5 -- 长按多久触发时间

function self:setData(key, value)
    if not key then
        return
    end
    self.dataMap[key] = value
end

function self:getData(key)
    return self.dataMap[key]
end

function self:setItemData(value)
    self:setData("item", value)
    if not value then
        self.ItemImage:setVisible(false)
        return
    end
    local showImage = value and value:cfg().showImage
    local icon = value and (value:cfg().icon or value:icon())
    if showImage and showImage ~= "" then
        self:setItemImage(showImage)
        self.ItemImage:setVisible(true)
    elseif icon and icon ~= "" then
        self:setItemImage({image =  {name = GUILib.loadImage(icon, value:cfg())}})
        self.ItemImage:setVisible(true)
    end
end

function self:getItemData()
    return self:getData("item")
end

function self:setClickCallBack(func)
    self.clickCallBack = func
end

function self:setLongTouchCallBack(func)
    self.longTouchCallBack = func
end

function self:setSelect(isSelect)
    self.SecLayout:setVisible(isSelect)
end

function self:enableSelectFrame(enable)
    self.SecLayout.SecFrame:setVisible(enable)
end

function self:enableSelectLight(enable)
    self.SecLayout.SecLight:setVisible(enable)
end

function self:showMask(params)
    if not params or not params.beginTime or not params.endTime then
        return
    end
    local maskInstance = self.maskInstance
    if not maskInstance then
        return
    end
    maskInstance:onReopen({
        beginTime = params.beginTime,
        endTime = params.endTime,
        curTime = params.curTime,
        callback = function()
            maskInstance:resetWnd()
            maskInstance:getWindow():setVisible(false)
        end
    })
end

function self:showRightBottomText(text)
    self.RightBottomText:setText(Lang:toText(text))
end

function self:showCenterBottomText(text)
    self.CenterBottomText:setText(Lang:toText(text))
end

function self:resetCell()
    self:setItemData()
    self.dataMap = {}
    self:setSelect(false)
    self.RightBottomText:setText("")
    self.CenterBottomText:setText("")
    if self.maskInstance then
        self.maskInstance:resetWnd()
    end
end

function self:resetMask()
    if self.maskInstance then
        self.maskInstance:resetWnd()
    end
end

function self:setNormalImageArea(area)
    self.NorImage:setArea2(table.unpack(area))
end

function self:setNormalImage(showImage)
    if not showImage or not showImage.image then
        return
    end
    self.NorImage:setImage(showImage.image.name, showImage.resourceGroup or "gameres")
end

function self:setSelectFrameArea(area)
    self.SecLayout:setArea2(table.unpack(area))
end

function self:setSelectFrame(showImage)
    if not showImage or not showImage.image then
        return
    end
    self.SecLayout.SecFrame:setImage(showImage.image.name, showImage.resourceGroup or "gameres")
end

function self:setItemImageArea(area)
    self.ItemImage:setArea2(table.unpack(area))
end

function self:setItemImage(showImage)
    self.ItemImage:setImage(showImage.image.name, showImage.resourceGroup or "gameres")
    self.ItemImage:setVisible(true)
end

function self:setItemImageVisible(visible)
    self.ItemImage:setVisible(visible)
end
-- ==================
-- ==================
-- ==================
function self:initProp()
    self.NorImage:setMousePassThroughEnabled(true)

    self.RightBottomText:setMousePassThroughEnabled(true)
    self.RightBottomText:setVisible(true)
    self.RightBottomText:setText("")

    self.CenterBottomText:setMousePassThroughEnabled(true)
    self.CenterBottomText:setVisible(true)
    self.CenterBottomText:setText("")

    self.SecLayout:setVisible(false)
    self.SecLayout:setMousePassThroughEnabled(true)
    self.SecLayout.SecFrame:setMousePassThroughEnabled(true)
    self.SecLayout.SecFrame:setVisible(true)
    self.SecLayout.SecLight:setVisible(false)

    self.ItemImage:setVisible(false)
    self.ItemImage:setMousePassThroughEnabled(true)
end

function self:initEvent()
    local function longTouchStartFunc()
        if self.longTouchCallBack then
            self.longTouchCallBack()
        end
    end
    local function longTouchStopFunc()
        World.Timer(1, function()
            self.hadTouch = false
        end)
    end
    self.onMouseButtonDown = function(instance, window, ...)
        if self.longTouchTimer then
            self.longTouchTimer()
        end
        self.longTouchTimer = World.Timer(longTouchTickTime, function()
            longTouchStartFunc()
            self.longTouchTimer = false
            self.hadTouch = true
        end)
    end
    self.onMouseButtonUp = function()
        if self.longTouchTimer then
            self.longTouchTimer()
            self.longTouchTimer = false
        end
        if self.hadTouch then
            longTouchStopFunc()
        end
    end
    self.onMouseLeavesArea = function()
        if self.longTouchTimer then
            self.longTouchTimer()
            self.longTouchTimer = false
        end
        if self.hadTouch then
            longTouchStopFunc()
        end
    end
    self.onMouseClick = function(instance, window, ...)
        if self.hadTouch then
            return
        end
        if self.clickCallBack then
            self.clickCallBack()
        end
    end
end

function self:initMask(cellName)
    local maskInstance = UI:openWindow("CDMask", cellName.."-cdMask", "_layouts_")
    local cdMask = maskInstance:getWindow()
    self:addChild(cdMask)
    cdMask:setHorizontalAlignment(1)
    cdMask:setVerticalAlignment(1)
    cdMask:setArea2({0,0},{0,0},{1,0},{1,0})
    cdMask:setVisible(false)
    self.maskInstance = maskInstance
    
end

function self:init()
    self:initProp()
    self:initEvent()
    self.maskInstance = false
    self.longTouchTimer = false
    self.hadTouch = false

    self.clickCallBack = false
    self.longTouchCallBack = false
    self.dataMap = {}
end

function self:onOpen()

end

function self:onClose()

end

self:init()
-- print("cell startup ui")