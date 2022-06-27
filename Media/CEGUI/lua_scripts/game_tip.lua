local cancelEventName

function M:onOpen()
    self:init()
end

function M:init()
    self.tipLayout = self:child("TipLayout")
    self.bodyLayout = self:child("BodyLayout")
    self.cancelBtn = self:child("BodyLayout_cancelBtn")
    self.greenBtn = self:child("BodyLayout_greenBtn")
    self.closeBtn = self:child("TouLayout_closeBtn")
    self.tipText = self:child("BodyLayou_tipText")
    self.screenShotLayout = self:child("ScreenShotLayout")

    self.cancelBtn:setText(Lang:toText("global.cancel"))
    self:child("TopLayout_text"):setText(Lang:toText("win.main.online.consume.remind.title"))
    self:child("BodyLayout_cancelBtn"):setText(Lang:toText("global.cancel"))
    self:child("BodyLayout_greenBtn"):setText(Lang:toText("global.sure"))

    self.cancelBtn.onMouseClick = function ()
        if cancelEventName then
            CGame.instance:onEditorDataReport(cancelEventName, "", 2)
        end
        self:setVisible(false)
    end

    self.closeBtn.onMouseClick = function ()
        self:setVisible(false)
    end
end

function M:openGameTip(text, func, eventName)
    cancelEventName = eventName
    self:setVisible(true)
    self.tipLayout:setArea2({0,0},{0,0},{0,450},{0,300})
    self.tipLayout:setYPosition({0, -30})
    self.tipText:setYPosition({0, 75})
    self.screenShotLayout:setVisible(false)
    self.tipText:setText(text)
    self.greenBtn:setText(Lang:toText("global.sure"))
    self.greenBtn.onMouseClick = function ()
        self:setVisible(false)
        func() 
    end
end

function M:openGameScreenShotTip(func, screenShotImgPath, editorUtil, eventName)
    cancelEventName = eventName
    local screenShotInfo = editorUtil:getCertainScreenShotInfo()
    local localOrUrlImg = (screenShotInfo.coverLocalPath or screenShotInfo.coverUrl) or ""
    local isRelease = localOrUrlImg ~= ""
    self:setVisible(true)
    local noReleaseLayout = self:child("ScreenShotLayout_NoRelease")
    local releaseLayout = self:child("ScreenShotLayout_Release")
    local releaseLeftImg = self:child("ReleaseLayout_Left_Img")
    local leftSelected = self:child("ReleaseLayout_Left_Selected")
    local releaseRightImg = self:child("ReleaseLayout_Right_Img")
    local rightSelected = self:child("ReleaseLayout_Right_Selected")
    local noReleaseImg = self:child("NoRelease_Img")
    local title = isRelease and Lang:toText("win.screenShot.releaseGameAndselectImg") or Lang:toText("win.screenShot.releaseGame")

    self:child("NoRelease_Text"):setText(Lang:toText("win.screenShot.autoScreenShot"))
    self:child("ReleaseLayout_Left_Text"):setText(Lang:toText("win.screenShot.useCurrentImg"))
    self:child("ReleaseLayout_Right_Text"):setText(Lang:toText("win.screenShot.useNewImg"))
    self.greenBtn:setText(Lang:toText("win.screenShot.saveAndpublish"))

    self.tipLayout:setArea2({0,0},{0,-30},{0,800},{0,420})
    self.tipText:setYPosition({0, 20})
    self.tipText:setText(title)
    self.screenShotLayout:setVisible(true)
    noReleaseLayout:setVisible(not isRelease)
    releaseLayout:setVisible(isRelease)

    local function setSelectStatus(isSelectLeft)
        leftSelected:setVisible(isSelectLeft)
        releaseLeftImg:setProperty("FrameEnabled", isSelectLeft and "true" or "false")

        rightSelected:setVisible(not isSelectLeft)
        releaseRightImg:setProperty("FrameEnabled", not isSelectLeft and "true" or "false")
    end

    releaseLeftImg.onMouseClick = function ()
        setSelectStatus(true)
    end

    releaseRightImg.onMouseClick = function ()
        setSelectStatus(false)
    end

    if isRelease then
        releaseLeftImg:setImage(GUILib.loadSingleImage(localOrUrlImg, "gameres"))
        releaseRightImg:setImage(GUILib.loadSingleImage(screenShotImgPath.rectangle, "gameres"))
    else
        noReleaseImg:setImage(GUILib.loadSingleImage(screenShotImgPath.rectangle, "gameres"))
    end

    self.greenBtn.onMouseClick = function ()
        if isRelease and leftSelected:isVisible() then
            editorUtil:removeScreenShot()
        end

        if not isRelease or rightSelected:isVisible() then
            editorUtil:saveGameGlobalField("setting.json", "isUseNewScreenShot", true)
        end
        self:setVisible(false)
        func()
    end
end