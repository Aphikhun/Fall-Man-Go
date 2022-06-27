local math_sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local rad = math.rad

local worldCfg = World.cfg

local dragControlConfig = worldCfg.dragControlConfig or {}
--[[
dragControlConfig = 
{
    useDragControl = bool
    fixedPointInCenter = bool
    dragAreaSize = int
    dragAreaStartPoint = {x, y}
    dragNormalImage = xx
    dragPushImage = xx
    dragPointArray = {1, 2, 3, 4, ..}
    dragPointImageConfig = 
    {
        prx = xx,
        asset = xx,
        group = xx
    }
    dragImageUseGroup = resource
}
]]
local useDragControl = dragControlConfig.useDragControl
local fixedDragPointInCenter = dragControlConfig.fixedPointInCenter or false
local dragAreaSize = dragControlConfig.dragAreaSize or 240
local dragAreaRadius = dragAreaSize / 2
local dragAreaStartPoint = dragControlConfig.dragAreaStartPoint or {40,-70}
local dragNormalImage = dragControlConfig.dragNormalImage
local dragPushImage = dragControlConfig.dragPushImage
local dragPointArray = dragControlConfig.dragPointArray or {13,16,19,21,61}
local dragPointImageConfig = dragControlConfig.dragPointImageConfig or 
{
    prx = "main_ui/control_",
    asset = "main_ui",
    group = "_imagesets_"
}
local dragImageUseGroup = dragControlConfig.dragImageUseGroup

local alwaysHideSneak = worldCfg.alwaysHideSneak
local alwaysHideBaseControl = worldCfg.alwaysHideBaseControl

local useNewKeyboardControl = worldCfg.useNewKeyboardControl

local poleControlConfig = worldCfg.poleControlConfig
--[[
    poleControlConfig = { 
        area = {[xx,xx],[xx,xx],[xx,xx],[xx,xx]}
        useGroup = "系统图集xxx/自定义脚本gameres"
        bgImage = { name = "", asset = "" }
    }
]]
local moveStateConfig = worldCfg.moveStateConfig
--[[
    moveStateConfig = {
        isShow = xx
        area = {[xx,xx],[xx,xx],[xx,xx],[xx,xx]}
        useGroup = "系统图集xxx/自定义脚本gameres"
        runImage = { name = "", asset = "" }
        sneakImage = { name = "", asset = "" }
    }
]]
local jumpControlConfig = worldCfg.jumpControlConfig
--[[
    jumpControlConfig = {
        isShow = xx
        area = {[xx,xx],[xx,xx],[xx,xx],[xx,xx]}
        useGroup = "系统图集xxx/自定义脚本gameres"
        jumpImage = { name = "", asset = "" }
        jumpPush = { name = "", asset = "" }
        sneakImage = { name = "", asset = "" }
        useJumpProgress = true/false
        jumpProgressImage = {
            leftImage = {name = xx, asset = xx}
            rightImage = {name = xx, asset = xx}
            resourceGroup = xx
            scale = xx
        }
        jumpProgressImcSize = num
    }
]]

local guiMgr = L("guiMgr", GUIManager:Instance())
local imgMgr = L("imgMgr", CEGUIImageManager:getSingleton())
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local ti = L("ti", TouchManager:Instance())
local CGameinstance = L("CGameinstance", CGame.instance)
local Blockmaninstance = L("Blockmaninstance", Blockman.instance)

local isPc = CGameinstance:getPlatformId() == 1
local isShowPlayerControlUi = CGameinstance:isShowPlayerControlUi()
local isJumpDefault = Blockmaninstance.gameSettings.isJumpSneakDefault > 0

local Logic = L("Logic", {})
local Init = L("Init", {})

local closeFuncMap = {}
------------------------------------------------------------- local

------------------------------------------------------------- Init
function Init.initMousePassEvent(self)
    self:setMousePassThroughEnabled(true)
    self.MoveCompomentBase:setMousePassThroughEnabled(true)
    self.MoveCompomentBase.Keyboard:setMousePassThroughEnabled(true)
    self.MoveCompomentBase.Pole.Point:setMousePassThroughEnabled(true)
    
    self.StateControlBase:setMousePassThroughEnabled(true)

    self.MoveCompomentBase.DragControl.MoveBgPush:setMousePassThroughEnabled(true)
    self.MoveCompomentBase.DragControl.MoveArea:setMousePassThroughEnabled(true)
end

function Init.initCompomentVisable(self)
    local MoveCompomentBase = self.MoveCompomentBase
    MoveCompomentBase.Keyboard:setVisible(false)
    MoveCompomentBase.Pole:setVisible(false)
    MoveCompomentBase.DragControl:setVisible(false)
    self:switchMoveControlMode("keyboard")


    local StateControlBase = self.StateControlBase
    StateControlBase.MoveState.Run:setVisible(Me.movingStyle == 0)
    StateControlBase.MoveState.Sneak:setVisible(Me.movingStyle == 1)
    StateControlBase.JumpControl.JumpLayout:setVisible(true)
    StateControlBase.JumpControl.JumpLayout.JumpProgress:setVisible(false)
    StateControlBase.JumpControl.JumpLayout.JumpPush:setVisible(false)
    StateControlBase.JumpControl.Sneak:setVisible(false)

end

function Init.initStateControlBase(self)
    local StateControlBase = self.StateControlBase

    if moveStateConfig then
        if moveStateConfig.runImage then
            Logic.setImage(StateControlBase.MoveState.Run, "Image", moveStateConfig.runImage, moveStateConfig.useGroup or "gameres")
        end
        if moveStateConfig.sneakImage then
            Logic.setImage(StateControlBase.MoveState.Sneak, "Image", moveStateConfig.sneakImage, moveStateConfig.useGroup or "gameres")
        end
        if moveStateConfig.area then
            StateControlBase.MoveState:setArea2(table.unpack(moveStateConfig.area))
        end
        StateControlBase.MoveState:setVisible(not (moveStateConfig.isShow==false))
    end

    if jumpControlConfig then
        local JumpLayout = StateControlBase.JumpControl.JumpLayout
        if jumpControlConfig.jumpImage then
            Logic.setImage(JumpLayout.Jump, "Image", jumpControlConfig.jumpImage, jumpControlConfig.useGroup or "gameres")
        end
        if jumpControlConfig.jumpPushImage then
            Logic.setImage(JumpLayout.JumpPush, "Image", jumpControlConfig.jumpPushImage, jumpControlConfig.useGroup or "gameres")
        end
        if jumpControlConfig.sneakImage then
            Logic.setImage(StateControlBase.JumpControl.Sneak, "Image", jumpControlConfig.sneakImage, jumpControlConfig.useGroup or "gameres")
        end
        if jumpControlConfig.area then
            StateControlBase.JumpControl:setArea2(table.unpack(jumpControlConfig.area))
        end
        if jumpControlConfig.jumpProgressImcSize then
            local imcSize = jumpControlConfig.jumpProgressImcSize
            local xPos = JumpLayout:getXPosition()
            local yPos = JumpLayout:getYPosition()
            local xSize = JumpLayout:getWidth()
            local ySize = JumpLayout:getHeight()
            JumpLayout.JumpProgress:setArea2({xPos[1], xPos[2] - imcSize}, {yPos[1], yPos[2] - imcSize}, {xSize[1], xSize[2] + imcSize * 2}, {ySize[1], ySize[2] + imcSize * 2})
        end
        StateControlBase.JumpControl:setVisible(not (jumpControlConfig.isShow==false))
    end

end

function Init.initKeyboardControl(self)
    local MoveCompomentBase = self.MoveCompomentBase

    local Keyboard = MoveCompomentBase.Keyboard
    Keyboard.LeftTop:setVisible(false)
    Keyboard.RightTop:setVisible(false)

end

function Init.initPoleControl(self)
    local MoveCompomentBase = self.MoveCompomentBase

    local Pole = MoveCompomentBase.Pole
    if poleControlConfig then
        if poleControlConfig.area then
            Pole:setArea2(table.unpack(poleControlConfig.area))
        end
        if poleControlConfig.bgImage then
            Logic.setImage(Pole.MoveBg, "Image", poleControlConfig.bgImage, poleControlConfig.useGroup or "gameres")
        end
    end

    local Point = Pole.Point
    self.originPolePosX = Point:getXPosition()
    self.originPolePosY = Point:getYPosition()
    local rect = Point:getPixelPosition()
    local pixelSize = Point:getPixelSize()
    self.originPoleAbsPosX = rect.x + pixelSize.width / 2
    self.originPoleAbsPosY = rect.y + pixelSize.height / 2
end

local function initDragAreaStartPoint()
    dragAreaStartPoint[1] = dragAreaStartPoint[1] ~= 0 and dragAreaStartPoint[1] or 40
    dragAreaStartPoint[2] = dragAreaStartPoint[2] ~= 0 and dragAreaStartPoint[2] or -70
end

function Init.initDragControl(self)
    local MoveCompomentBase = self.MoveCompomentBase

    local DragControl = MoveCompomentBase.DragControl
    initDragAreaStartPoint()
    DragControl:setArea2({0, dragAreaStartPoint[1]}, {0, dragAreaStartPoint[2]}, {0, dragAreaSize}, {0, dragAreaSize})
    DragControl.MoveBgPush:setVisible(false)
    if dragNormalImage then
        Logic.setImage(DragControl.MoveBg, "Image", {name = dragNormalImage}, dragImageUseGroup or "gameres")
    end
    if dragPushImage then
        Logic.setImage(DragControl.MoveBgPush, "Image", {name = dragPushImage}, dragImageUseGroup or "gameres")
    end

    self.dragTouchID = false
    local pixelPosition = DragControl.MoveBg:getPixelPosition()
    local pixelSize = DragControl.MoveBg:getPixelSize()
    if fixedDragPointInCenter then    
        self.dragScreenX = pixelPosition.x + pixelSize.width / 2
        self.dragScreenY = pixelPosition.y + pixelSize.height / 2
    else
        self.dragScreenX = false
        self.dragScreenY = false
    end

    self.dragPoints = {}
    local MoveArea = DragControl.MoveArea
    for i=1, #dragPointArray do
        local radius = dragPointArray[i]
        local point = winMgr:createWindow("Engine/StaticImage", "DragControlPoint" .. i)
        point:setMousePassThroughEnabled(true)
        Logic.setImage(point, "Image", {name = dragPointImageConfig.prx..i, asset = dragPointImageConfig.asset}, dragPointImageConfig.group)
        point:setArea2({0.5, 0}, {0.5, 0}, {0, radius}, {0, radius})
        MoveArea:addChild(point)
        point:setVisible(false)
        -- point:setFrameEnabled(false)
        point:setProperty("FrameEnabled", false)
        -- point:setProperty("BackgroundEnabled", false)
        point:setClippedByParent(false)
        self.dragPoints[i] = point
    end
end

function Init.initFlexibleDragControl(self)
    local MoveCompomentBase = self.MoveCompomentBase

    local FlexibleDragControl = MoveCompomentBase.FlexibleDragControl
    FlexibleDragControl.BottomImage:setImage("main_ui/linghuo_bottom")
    FlexibleDragControl.BottomImage.UpImage:setImage("main_ui/linghuo_up")
    FlexibleDragControl:setLevel(FlexibleDragControl:getLevel()-1)
end

function Init.initNewKeyboardControl(self)
    local newKeyboardControl = self.newKeyboardControl
    if not newKeyboardControl then
        newKeyboardControl = UI:openSystemWindow("newKeyboardControl")
        self:addChild(newKeyboardControl.__window)
    end
    newKeyboardControl:setVisible(false)
end

function Init.initCompomentProperty(self)
    Init.initStateControlBase(self)
    Init.initKeyboardControl(self)
    Init.initPoleControl(self)
    Init.initDragControl(self)
    Init.initFlexibleDragControl(self)
    Init.initNewKeyboardControl(self)
end

function Init.initCompomentEvent(self)
    local function sneakDoubleClick()
        local sneakPressed = Blockmaninstance:isKeyPressing("key.sneak")
		Blockmaninstance:setKeyPressing("key.sneak", not sneakPressed)
        self.StateControlBase.MoveState.Run:setVisible(sneakPressed)
        self.StateControlBase.MoveState.Sneak:setVisible(not sneakPressed)
        self.StateControlBase.JumpControl.Sneak:setAlpha(sneakPressed and 0.9 or 0.6)
        self.MoveCompomentBase.Keyboard.CenterSneak:setAlpha(sneakPressed and 0.9 or 0.6)
    end
    local MoveCompomentBase = self.MoveCompomentBase
    -- pole
    local Pole = MoveCompomentBase.Pole
    Pole.MoveArea.onMouseButtonDown = function(instance, window, ...)
        self:clearPoleDownStatus()
        self.poleDownTouchID = ti:getActiveTouch()
        self.poleTouchEndListener = Lib.subscribeEvent(Event.EVENT_SCENE_TOUCH_END, function(x, y, preX, preY, touchId)
            if not self.poleDownTouchID or touchId ~= self.poleDownTouchID then
                return
            end
            self:clearPoleDownStatus()
            self:onPoleTouchUp()
        end)
        self:onPoleTouchDown()
    end

    Pole.MoveArea.onMouseButtonUp = function(instance, window, ...)
        self:clearPoleDownStatus()
        self:onPoleTouchUp()
    end

    Pole.MoveArea.onMouseLeavesArea = function(instance, window, ...)
        self:clearPoleDownStatus()
        self:onPoleTouchUp()
    end

    Pole.MoveArea.onMouseMove = function(instance, window, dx, dy)
        self:onPoleTouchMove(dx, dy)
    end

    -- drag
    local DragControl = MoveCompomentBase.DragControl
    DragControl.MoveBg.onMouseButtonDown = function(instance, window, dx, dy)
        self:onDragTouchDown(dx, dy)
    end

    DragControl.MoveBg.onMouseButtonUp = function(instance, window, dx, dy)
        self:onDragTouchUp()
    end

    DragControl.MoveBg.onMouseMove = function(instance, window, dx, dy)
        self:onDragTouchMove(dx, dy)
    end

    -- flexibleDrag
    local FlexibleDragControl = MoveCompomentBase.FlexibleDragControl
    FlexibleDragControl.onMouseButtonDown = function(instance, window, dx, dy)
        DragControl:setVisible(true)
        instance.BottomImage:setVisible(false)
        local pos = instance:getPixelPosition()
        local offsetX = dx - pos.x
        local offsetY = dy - pos.y
        local dragOriginXPos = instance:getXPosition()
        local dragOriginYPos = instance:getYPosition()
        local dragControlSzie = DragControl:getPixelSize()
        DragControl:setXPosition({dragOriginXPos[1], dragOriginXPos[2] + offsetX - (dragControlSzie.width * 0.5)})
        DragControl:setYPosition({dragOriginYPos[1], dragOriginYPos[2] + offsetY - (dragControlSzie.height * 0.5)})
        self:onDragTouchDown(dx, dy)
    end

    FlexibleDragControl.onMouseButtonUp = function(instance, window, dx, dy)
        DragControl:setVisible(false)
        instance.BottomImage:setVisible(true)
        self:onDragTouchUp()
    end

    FlexibleDragControl.onMouseMove = function(instance, window, dx, dy)
        self:onDragTouchMove(dx, dy)
    end

    -- keyboard
    local Keyboard = MoveCompomentBase.Keyboard
    local KeyboardSneak = Keyboard.CenterSneak
    KeyboardSneak.onMouseDoubleClick = function(instance, window, ...)
        sneakDoubleClick()
    end
    Keyboard.CenterTop.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.forward", true)
        self:showMainControlTopLeftRight(true)
    end
    Keyboard.CenterTop.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.forward", false)
        self:checkHideMainControlTopLeftRight()
    end
    Keyboard.CenterTop.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.forward", false)
        self:checkHideMainControlTopLeftRight()
    end

    Keyboard.CenterBottom.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.back", true)
    end
    Keyboard.CenterBottom.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.back", false)
    end
    Keyboard.CenterBottom.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.back", false)
    end

    Keyboard.LeftCenter.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.left", true)
    end
    Keyboard.LeftCenter.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.left", false)
    end
    Keyboard.LeftCenter.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.left", false)
    end

    Keyboard.RightCenter.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.right", true)
    end
    Keyboard.RightCenter.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.right", false)
    end
    Keyboard.RightCenter.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.right", false)
    end


    Keyboard.LeftTopTouch.onMouseEntersArea = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.left", true)
		self:showMainControlTopLeftRight(true)
    end
    Keyboard.LeftTopTouch.onMouseButtonDown = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.left", true)
		self:showMainControlTopLeftRight(true)
    end
    Keyboard.LeftTopTouch.onMouseButtonUp = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.left", false)
		self:checkHideMainControlTopLeftRight()
    end
    Keyboard.LeftTopTouch.onMouseLeavesArea = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.left", false)
		self:checkHideMainControlTopLeftRight()
    end

    Keyboard.RightTopTouch.onMouseEntersArea = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.right", true)
		self:showMainControlTopLeftRight(true)
    end
    Keyboard.RightTopTouch.onMouseButtonDown = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.right", true)
		self:showMainControlTopLeftRight(true)
    end
    Keyboard.RightTopTouch.onMouseButtonUp = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.right", false)
		self:checkHideMainControlTopLeftRight()
    end
    Keyboard.RightTopTouch.onMouseLeavesArea = function(instance, window, ...)
		Blockmaninstance:setKeyPressing("key.top.right", false)
		self:checkHideMainControlTopLeftRight()
    end

    Keyboard.CenterJump.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", true)
    end
    Keyboard.CenterJump.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", false)
    end
    Keyboard.CenterJump.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", false)
    end

    -- State Control
    local StateControlBase = self.StateControlBase
    local MoveStateRun = StateControlBase.MoveState.Run
    local MoveStateSneak = StateControlBase.MoveState.Sneak
    local JumpControl = StateControlBase.JumpControl
    local JumpControlJump = JumpControl.JumpLayout.Jump
    local JumpControlSneak = JumpControl.Sneak
    JumpControlJump.onMouseButtonDown = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", true)
        JumpControl.JumpLayout.JumpPush:setVisible(true)
    end
    JumpControlJump.onMouseButtonUp = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", false)
        JumpControl.JumpLayout.JumpPush:setVisible(false)
    end
    JumpControlJump.onMouseLeavesArea = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.jump", false)
        JumpControl.JumpLayout.JumpPush:setVisible(false)
    end
    JumpControlSneak.onMouseDoubleClick = function(instance, window, ...)
        sneakDoubleClick()
    end
    MoveStateSneak.onMouseClick = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.sneak", false)
        MoveStateSneak:setVisible(false)
        MoveStateRun:setVisible(true)
        KeyboardSneak:setAlpha(0.9)
        JumpControlSneak:setAlpha(0.9)
    end
    MoveStateRun.onMouseClick = function(instance, window, ...)
        Blockmaninstance:setKeyPressing("key.sneak", true)
        MoveStateSneak:setVisible(true)
        MoveStateRun:setVisible(false)
        KeyboardSneak:setAlpha(0.6)
        JumpControlSneak:setAlpha(0.6)
    end

end

function Init.initCompoment(self)
    Init.initCompomentVisable(self)
    Init.initCompomentProperty(self)
    Init.initCompomentEvent(self)

end

function Init.initLibSubEvent(self)
    local jumpTimer = nil
    local cdMaskWnd = nil
    local jumpHadAddCDMask = false
    local JumpProgress = self.StateControlBase.JumpControl.JumpLayout.JumpProgress
    Lib.subscribeEvent(Event.EVENT_UPDATE_JUMP_PROGRESS, function(tb)
        if not jumpControlConfig or not jumpControlConfig.useJumpProgress then -- 测试隐藏即可
            return
        end
        if tb.jumpStop then
            if cdMaskWnd then
                cdMaskWnd:resetWnd()
            end
            JumpProgress:setVisible(false)
        elseif tb.jumpStart then
            JumpProgress:setVisible(true)
            if not cdMaskWnd then
                local packet = {beginTime = tb.jumpBeginTime, endTime = tb.jumpEndTime, imageConfig = jumpControlConfig and jumpControlConfig.jumpProgressImage}
                cdMaskWnd = UI:openWindow("progressMask", "actionControl_JumpProgress_progressMask", "_layouts_", packet)
                closeFuncMap[#closeFuncMap + 1] = function() cdMaskWnd:close() end
            else
                cdMaskWnd:onReopen({beginTime = tb.jumpBeginTime, endTime = tb.jumpEndTime})
            end
            if tb.jumpBeginTime < tb.jumpEndTime and not jumpHadAddCDMask then
                jumpHadAddCDMask = true
                JumpProgress:addChild(cdMaskWnd:getWindow())
            end
		end
    end)

    Lib.subscribeEvent(Event.EVENT_CHECKBOX_CHANGE, function(status)
		self:switchMoveControl(Blockmaninstance.gameSettings.usePole)
		self:sneakBtnStatus()
    end)

	Lib.subscribeEvent(Event.EVENT_SWITCH_MOVE_CONTROL, function(usePole)
		self:switchMoveControl(usePole)
    end)

    Lib.subscribeEvent(Event.EVENT_SET_GUI_SIZE, function()
		self:updateGuiSize()
    end)

    Lib.subscribeEvent(Event.EVENT_SWITCH_MOVE_CONTROL_MODE, function(mode)
        if self.curControlMode ~= mode then
		    self:switchMoveControlMode(mode)
        end
    end)

end
local isInitFly = false
function Init.initFlyBtn(self)
    if isInitFly then
        return
    end
    isInitFly = true
    local flyBtnSetting = World.cfg.flyBtnSetting or {}
    local flyBtnArea = flyBtnSetting.area
    local flyBtnUp = flyBtnSetting.up or {}
    local flyBtnDown = flyBtnSetting.down or {}
    local flyBtnHideJumpWhenFly = flyBtnSetting.hideJumpWhenFly
    local flyBtnNorUpIcon = flyBtnSetting.norUpIcon or {name = "main_ui/fly_up_normal", asset = "main_ui"}
    local flyBtnPushUpIcon = flyBtnSetting.pushUpIcon or {name = "main_ui/fly_up_push", asset = "main_ui"}
    local flyBtnNorDownIcon = flyBtnSetting.norDownIcon or {name = "main_ui/fly_down_normal", asset = "main_ui"}
    local flyBtnPushDownIcon = flyBtnSetting.pushDownIcon or {name = "main_ui/fly_down_push", asset = "main_ui"}

    local contentArea = flyBtnArea or {{0, -20}, {0, -60}, {0, 192}, {0, 210}}
    local x, y, w, h = table.unpack(contentArea)
    local content = winMgr:createWindow("DefaultWindow", "Main-FlyContent")
    content:setArea2(x, y, w, h)
    content:setHorizontalAlignment(flyBtnSetting.hAlign or 2)
    content:setVerticalAlignment(flyBtnSetting.vAlign or 2)
    content:setVisible(false)
    content:setMousePassThroughEnabled(true)
    self:addChild(content)
    
    local up = winMgr:createWindow("Engine/StaticImage", "Main-FlyContent-up")
    Logic.setImage(up, "Image", flyBtnNorUpIcon, flyBtnSetting.useGroup)
    up:setArea2(table.unpack(flyBtnSetting.upArea or {{0, 0}, {0, 0}, {1, 0}, {0, h[2] * 0.5}}))
    up:setVerticalAlignment(0)
    content:addChild(up)
    local upInstance = UI:getWindowInstance(up, true)

    local down = winMgr:createWindow("Engine/StaticImage", "Main-FlyContent-down")
    Logic.setImage(down, "Image", flyBtnNorDownIcon, flyBtnSetting.useGroup)
    down:setArea2(table.unpack(flyBtnSetting.downArea or {{0, 0}, {0, 0}, {1, 0}, {0, h[2] * 0.5}}))
    down:setVerticalAlignment(2)
    content:addChild(down)
    local downInstance = UI:getWindowInstance(down, true)

    local control = Blockmaninstance:control()
    local function flyBegin(isUp)
        Logic.setImage(up, "Image", isUp and flyBtnPushUpIcon or flyBtnNorUpIcon, flyBtnSetting.useGroup)
        Logic.setImage(down, "Image", isUp and flyBtnNorDownIcon or flyBtnPushDownIcon, flyBtnSetting.useGroup)
        control:setVerticalSpeed(isUp and 1 or -1)
    end
    local function flyEnd()
        Logic.setImage(up, "Image", flyBtnNorUpIcon, flyBtnSetting.useGroup)
        Logic.setImage(down, "Image", flyBtnNorDownIcon, flyBtnSetting.useGroup)
        control:setVerticalSpeed(0)
    end

    upInstance.onMouseButtonDown = function(instance, window, dx, dy)
        flyBegin(true)
    end

    upInstance.onMouseButtonUp = function(instance, window, ...)
        flyEnd()
    end

    upInstance.onMouseLeavesArea = function(instance, window, ...)
        flyEnd()
    end

    downInstance.onMouseButtonDown = function(instance, window, dx, dy)
        flyBegin(false)
    end

    downInstance.onMouseButtonUp = function(instance, window, ...)
        flyEnd()
    end

    downInstance.onMouseLeavesArea = function(instance, window, ...)
        flyEnd()
    end

    Lib.subscribeEvent(Event.EVENT_UPDATE_FLY_STATE, function(state)
        content:setVisible(state)
        flyEnd()
        if flyBtnSetting.hideJumpWhenFly then
            self.StateControlBase.JumpControl:setVisible(not state)
        end
    end)

end

------------------------------------------------------------- Logic
function Logic.setImage(self, property, image, resourceGroup) -- image 的参数参考注释的 test code
    if property == "Image" then
        self:setImage(image.name, resourceGroup)
    elseif property == "NormalImage" then
        self:setNormalImage(image.name, resourceGroup)
    elseif property == "PushedImage" then
        self:setPushedImage(image.name, resourceGroup)
    end
end
------------------------------------------------------------- self
function self:switchMoveControl(usePole)
    local isUsePole = usePole > 0
    if useDragControl then
        self:switchMoveControlMode("dragControl")
    elseif isUsePole then
        self:switchMoveControlMode("pole")
    elseif useNewKeyboardControl then
        self:switchMoveControlMode("newKeyboard")
    else
        self:switchMoveControlMode("keyboard")
    end
end

function self:setKeyboardControlModeEnabled(setting)
    local Keyboard = self.MoveCompomentBase.Keyboard
    Keyboard:setVisible(setting)
    if alwaysHideSneak then
        Keyboard.CenterJump:setVisible(setting)
    else
        Keyboard.CenterJump:setVisible(setting and not isJumpDefault)
        Keyboard.CenterSneak:setVisible(setting and isJumpDefault)
    end
end

function self:setNewKeyboardControlModeEnabled(setting)
    local newKeyboardControl = self.newKeyboardControl
    newKeyboardControl:setVisible(setting)
end

function self:setPoleModeEnabled(setting)
    local Pole = self.MoveCompomentBase.Pole
    local JumpControl = self.StateControlBase.JumpControl
    Pole:setVisible(setting)
    JumpControl.JumpLayout:setVisible(setting)
    JumpControl.Sneak:setVisible(false)
end

function self:setDragControlModeEnabled(setting)
    local DragControl = self.MoveCompomentBase.DragControl
    DragControl:setVisible(setting)
    if setting then
        initDragAreaStartPoint()
        DragControl:setArea2({0, dragAreaStartPoint[1]}, {0, dragAreaStartPoint[2]}, {0, dragAreaSize}, {0, dragAreaSize})
    end
end

function self:setFlexibleDragControlModeEnabled(setting)
    local FlexibleDragControl = self.MoveCompomentBase.FlexibleDragControl
    FlexibleDragControl:setVisible(setting)
end

local moveControlEnabledHandles = 
{
    keyboard = self.setKeyboardControlModeEnabled,
    pole = self.setPoleModeEnabled,
    newKeyboard = self.setNewKeyboardControlModeEnabled,
    dragControl = self.setDragControlModeEnabled,
    flexibleDragControl = self.setFlexibleDragControlModeEnabled,
}

function self:switchMoveControlMode(mode)
    if not isShowPlayerControlUi and isPc then
        return
    end

    if self.curControlMode then
        local handle = moveControlEnabledHandles[self.curControlMode]
        handle(self,false)
    end
    
    local JumpControl = self.StateControlBase.JumpControl
    if alwaysHideSneak then
        JumpControl.JumpLayout:setVisible(alwaysHideSneak)
        JumpControl.Sneak:setVisible(not alwaysHideSneak)
    else
        JumpControl.JumpLayout:setVisible(isJumpDefault)
        JumpControl.Sneak:setVisible(not isJumpDefault)
    end

    self.curControlMode = mode
    local handle = moveControlEnabledHandles[mode]
    handle(self, true)
    Lib.emitEvent(Event.EVENT_SWITCH_MOVE_CONTROL_MODE, mode)
end

function self:sneakBtnStatus()
	local isSneakPressed = Blockmaninstance:isKeyPressing("key.sneak")
    self.StateControlBase.JumpControl.Sneak:setAlpha(isSneakPressed and 0.9 or 0.6)
    self.MoveCompomentBase.Keyboard.CenterSneak:setAlpha(isSneakPressed and 0.9 or 0.6)
end

function self:updateGuiSize()
    local sizeTb = {Blockmaninstance.gameSettings.playerActivityGuiSize, 0}
    self.StateControlBase.JumpControl.JumpLayout:setWidth(sizeTb)
    self.StateControlBase.JumpControl.JumpLayout:setHeight(sizeTb)
    local MoveCompomentBase = self.MoveCompomentBase
    self.MoveCompomentBase.Keyboard:setWidth(sizeTb)
    self.MoveCompomentBase.Keyboard:setHeight(sizeTb)
    self.MoveCompomentBase.Pole:setWidth(sizeTb)
    self.MoveCompomentBase.Pole:setHeight(sizeTb)
end
--------------
function self:clearPoleDownStatus()
    if rawget(self, "poleTouchEndListener") and self.poleTouchEndListener then
        self.poleTouchEndListener()
        self.poleTouchEndListener = nil
    end
    self.poleDownTouchID = nil
end

function self:onPoleTouchDown()
    local MoveCompomentBase = self.MoveCompomentBase
    local Pole = MoveCompomentBase.Pole
    Pole.MoveBg:setAlpha(0.5)
end

function self:onPoleTouchMove(dx, dy)
    local fMaxDis = 25.0
	local offX = dx - self.originPoleAbsPosX
	local offY = dy - self.originPoleAbsPosY
	local disSqr = offX * offX + offY * offY
    disSqr = disSqr ~= 0 and disSqr or 1
	if disSqr > fMaxDis * fMaxDis then
		local rate = math_sqrt(fMaxDis * fMaxDis / disSqr)
		offX = offX * rate
		offY = offY * rate
		disSqr = fMaxDis * fMaxDis
	end
    self.MoveCompomentBase.Pole.Point:setXPosition({self.originPolePosX[1], self.originPolePosX[2] + offX})
    self.MoveCompomentBase.Pole.Point:setYPosition({self.originPolePosY[1], self.originPolePosX[2] + offY})
	Blockmaninstance.gameSettings.poleForward = -offY / math_sqrt(disSqr)
	Blockmaninstance.gameSettings.poleStrafe = -offX / math_sqrt(disSqr)

end

function self:onPoleTouchUp()
    local MoveCompomentBase = self.MoveCompomentBase
    local Pole = MoveCompomentBase.Pole
    Pole.MoveBg:setAlpha(0.75)
    Pole.Point:setXPosition(self.originPolePosX)
    Pole.Point:setYPosition(self.originPolePosY)
	Blockmaninstance.gameSettings.poleForward = 0
	Blockmaninstance.gameSettings.poleStrafe = 0
end

function self:showMainControlTopLeftRight(show)
    local Keyboard = self.MoveCompomentBase.Keyboard
    Keyboard.LeftTop:setVisible(show)
    Keyboard.LeftTopTouch:setVisible(show)
    Keyboard.RightTop:setVisible(show)
    Keyboard.RightTopTouch:setVisible(show)
	local timer = rawget(self, "hideControlTopLeftRightTimer") and self.hideControlTopLeftRightTimer
	if show and timer then
		timer()
		self.hideControlTopLeftRightTimer = nil
	end
end

local TopLeftRightRelatedKeys = {"key.forward", "key.top.left", "key.top.right"}
function self:checkHideMainControlTopLeftRight(isTimerCallback)
    if not isTimerCallback then
		self.hideControlTopLeftRightTimer = World.Timer(7, self.checkHideMainControlTopLeftRight, self, true)
		return
    end
	self.hideControlTopLeftRightTimer = nil
	for _, key in pairs(TopLeftRightRelatedKeys) do
		if Blockmaninstance:isKeyPressing(key) then
			return
		end
	end
	self:showMainControlTopLeftRight(false)
end

function self:onDragTouchDown(dx, dy)
    if not dx or not dy then
        return
    end
    local DragControl = self.MoveCompomentBase.DragControl
    local MoveBg = DragControl.MoveBg
    local rect = MoveBg:getPixelPosition()
    local radius = MoveBg:getPixelSize().width * 0.5
    local offsetX, offsetY = dx - (rect.x + radius), dy - (rect.y + radius)
    if (offsetX * offsetX + offsetY * offsetY) > radius * radius then
        return
    end

    for _, point in ipairs(self.dragPoints) do
        local width = point:getWidth()[2]
        point:setXPosition({0.5, -width / 2})
        point:setYPosition({0.5, -width / 2})
        point:setVisible(true)
    end
    DragControl.MoveBgPush:setVisible(true)

    Blockmaninstance.gameSettings.poleForward = 0
	Blockmaninstance.gameSettings.poleStrafe = 0
    if not fixedDragPointInCenter then
        self.dragScreenX = dx
        self.dragScreenY = dy
        local dragOriginXPos = MoveBg:getXPosition()
        local dragOriginYPos = MoveBg:getYPosition()
        local MoveArea = DragControl.MoveArea
        MoveArea:setXPosition({dragOriginXPos[1], dragOriginXPos[2] + offsetX})
        MoveArea:setYPosition({dragOriginYPos[1], dragOriginYPos[2] + offsetY})
    end
end

function M:onDragTouchUp()
    if not fixedDragPointInCenter then
        self.dragScreenX = false
        self.dragScreenY = false
    end
    local DragControl = self.MoveCompomentBase.DragControl
    for _, point in ipairs(self.dragPoints) do
        local width = point:getWidth()[2]
        point:setXPosition({0.5, 0})
        point:setYPosition({0.5, 0})
        point:setVisible(false)
    end
    DragControl.MoveBgPush:setVisible(false)
    Blockmaninstance.gameSettings.poleForward = 0
	Blockmaninstance.gameSettings.poleStrafe = 0
    local MoveArea = DragControl.MoveArea
    MoveArea:setXPosition({0, 0})
    MoveArea:setYPosition({0, 0})
end

local rotationV3 = {x = 0, y = 0, z = 1} -- 绕正Z轴旋转(正对屏幕)
local function rotationToQuaternion(rotation)
    local halfRotation = 0.5 * rotation
    local halfSin = sin(halfRotation)
    return {w = cos(halfRotation), x = rotationV3.x * halfSin, y = rotationV3.y * halfSin, z = rotationV3.z * halfSin}
end

function self:onDragTouchMove(dx, dy)
    if not self.dragScreenX or not self.dragScreenY or not self.isShown then
        return
    end
	local offX = dx - self.dragScreenX
    local offY = dy - self.dragScreenY
	local disSqr = offX * offX + offY * offY
    disSqr = disSqr ~= 0 and disSqr or 1
	local poleForward = -offY / math_sqrt(disSqr)
	local poleStrafe = -offX / math_sqrt(disSqr)
	Blockmaninstance.gameSettings.poleForward = poleForward
	Blockmaninstance.gameSettings.poleStrafe = poleStrafe
    local count = #self.dragPoints
    for i = 2, count do
        local point = self.dragPoints[i]
        local width = point:getWidth()[2]
        point:setXPosition({0.5, offX / (count - 1) * (i - 1) - 0.5 * width})
        point:setYPosition({0.5, offY / (count - 1) * (i - 1) - 0.5 * width})
        -- local q = rotationToQuaternion(rad(90 + math.atan(offY , offX) * 180 / math.pi))
        -- point:setProperty("Rotation", "w:"..q.w.." x:"..q.x.." y:"..q.y.." z:"..q.z)
    end
end

function self:init()
    Init.initMousePassEvent(self)
    Init.initCompoment(self)
    Init.initLibSubEvent(self)

    self:switchMoveControl(Blockmaninstance.gameSettings.usePole)
    self:setVisible(not alwaysHideBaseControl)

    Init.initFlyBtn(self)
    if Me.isWatch and Me:isWatch() then
        self.StateControlBase:setVisible(false)
    end
    self.GM:setVisible(World.gameCfg.gm or false)
    self.GM.onMouseClick = function()
        Lib.emitEvent(Event.EVENT_SHOW_GMBOARD)
    end
    self.isShown = self:isVisible()
end

function M:showGM(show)
    self.GM:setVisible(show)
end
------------------------------------------------------------- open close
local openCount = 0
function self:onOpen()
    print("actionControl onOpen , openCount = ", openCount)
    openCount = openCount + 1

end

function self:onClose()
    print("actionControl onClose ")
    for _ , func in pairs(closeFuncMap) do
        func()
    end

end

function self:onHidden()
    self.isShown = false
    Blockmaninstance.gameSettings.poleForward = 0
    Blockmaninstance.gameSettings.poleStrafe = 0
end

function self:onShown()
    self.isShown = true
end

self:init()


--write your test code
local count = 1
local win 
local win2 
function self.SwitchButtonTest.onMouseClick(instance, window, ...)
    --write your test code
end