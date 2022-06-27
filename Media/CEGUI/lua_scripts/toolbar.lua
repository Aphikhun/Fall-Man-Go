local lfs = require "lfs"
local jumpType = {
    onlineGame = 1,
    uploadGame = 2
}
local isOpenOnlineRoomFlag
function M:onOpen()
    self:init()
end

function M:init()

    self.settingBtn = self:child("settingBtn")
    self.chatBtn = self:child("chatBtn")
    self.viewBtn = self:child("viewBtn")
    self.playerListBtn = self:child("playerListBtn")

    self.EditGameLayout = self:child("EditGameLayout")
    self.OnlineGameLayout = self:child("OnlineGameLayout")

    self.BuyBtnLayout = self:child("BuyBtnLayout")
    self.buyCoinBtn = self:child("buyBtn")
    self.ToolBarGoldDiamondValue = self:child("coinText")

    self.CountDownLayout = self:child("CountDownLayout")
    self.countDownText = self:child("countDownText")

    self.PropCountDownLayout = self:child("PropCountDownLayout")

    self:initChatWindow()

    if World.cfg.hideSetting then
        self.settingBtn:setVisible(false)
    end
    if World.cfg.hideChatBox then
        self.chatBtn:setVisible(false)
    end

    self:initGameTipWindow()
    if World.CurWorld.isEditorEnvironment then
        self:openLocalTest()
    end


    self:initSubscribeEvent()
    self.propCollectCountdownTimer = false
    local settingWnd = UI:openSystemWindow("setting")
    settingWnd:setVisible(false)
end

function M:initGameTipWindow()
    self.gameTipWnd = UI:isOpenWindow("game_tip") or false
    if not self.gameTipWnd then
        self.gameTipWnd = UI:openSystemWindow("game_tip")
        self.gameTipWnd:setVisible(false)
    end
end

function M:initSubscribeEvent()
    self.settingBtn.onMouseClick = function()
        local settingWnd = UI:isOpenWindow("setting")
        -- TODO:打开窗口
        if settingWnd then
            settingWnd:setVisible(not settingWnd:isVisible())
        else
            settingWnd = UI:openSystemWindow("setting")
        end
        Lib.emitEvent(Event.EVENT_ONLINE_ROOM_SHOW, not settingWnd:isVisible())
    end

    self.chatBtn.onMouseClick = function()
        if not self.chatWnd then
            return
        end
        self.chatWnd:setVisible(not self.chatWnd:isVisible())
        Lib.emitEvent(Event.EVENT_CHAT_HIDE_LEFT_BTN, self.chatWnd:isVisible())
    end
        
    self.viewBtn:setVisible(not World.cfg.isHidePerspective)
    self.viewBtn.onMouseClick = function()
        Blockman.instance:switchPersonView()
        PlayerControl.UpdatePersonView()
        Lib.emitEvent(Event.FRONTSIGHT_SHOW)
    end

    self.playerListBtn:setVisible(true)
    self.playerListBtn.Image = "main_ui/icon_friends"
    self.playerListBtn.onMouseClick = function()
        local PlayerList = UI.root.playerList
        if not PlayerList then
            PlayerList = UI:openSystemWindow("playerList")
        end
        PlayerList:setVisible(not PlayerList:isVisible())
    end

    Lib.subscribeEvent(Event.EVENT_CHANGE_PERSONVIEW, function()
        self:updatePerspeceIcon()
    end)
    Lib.subscribeEvent(Event.EVENT_GAME_START, self.updatePerspeceIcon, self)

    Lib.subscribeEvent(Event.EVENT_CHAT_HIDE_LEFT_BTN, function(isHide)
        if World.CurWorld.isEditorEnvironment then
            self.EditGameLayout:setVisible(not isHide)
        end
        
        if isOpenOnlineRoomFlag then
            self.OnlineGameLayout:setVisible(not isHide)
        end
    end)

    Lib.lightSubscribeEvent("error!!!!! : win_toolbar lib event : EVENT_SHOW_RECHARGE", Event.EVENT_SHOW_RECHARGE, function()
        Interface.onRecharge(1)
    end)

    self.buyCoinBtn:setVisible(not FunctionSetting:disableRecharge())
    self.buyCoinBtn.onMouseClick = function()
        if World.cfg.pauseWhenCharge then
            Lib.emitEvent(Event.EVENT_PAUSE_BY_CLIENT)
        end
        Lib.emitEvent(Event.EVENT_SHOW_RECHARGE)
    end

    Lib.subscribeEvent(Event.EVENT_HIDE_RECHARGE, function(hide)		
        self.buyCoinBtn:setVisible(not hide and not FunctionSetting:disableRecharge())
    end)

    Lib.subscribeEvent(Event.EVENT_CHANGE_CURRENCY, function()
        self:changeCurrency()
    end)

    self:setUiOffset()
end

function M:initChatWindow()
    self.chatWnd = UI:isOpenWindow("chat")
    if not self.chatWnd then
        self.chatWnd = UI:openSystemWindow("chat")
    end
    self.chatWnd:setVisible(false)
end

function M:setUIXPosition(ui, offset, isReset)
    local xPosition = ui:getXPosition()
    if isReset then
        offset = self.initBuyBtnLayoutWidth + offset + 25
    end
    xPosition[2] = xPosition[2] + offset
    ui:setXPosition(xPosition)
end

local isSetUiOffset
function M:setUiOffset()
    if isSetUiOffset then
        return
    end
    local uiNavigation = World.cfg.uiNavigation
    local isShowShopBtn = World.cfg.showButtonShopName and (World.cfg.showButtonShopName ~= "") or false
    local pcShowShop = uiNavigation and uiNavigation[1] and uiNavigation[1].name == "shop"
    local offsetX = 0
    if isShowShopBtn or pcShowShop then
        offsetX = offsetX - 100
    end
    self:setUIXPosition(self.BuyBtnLayout, offsetX)
    self:setUIXPosition(self.CountDownLayout, offsetX)
    isSetUiOffset = true
end

function M:updatePerspeceIcon()
	local cameraCfg = World.cfg.cameraCfg
    if World.cfg.hidePerSpec or (cameraCfg and cameraCfg.canSwitchView == false) then
        self.viewBtn:setVisible(false)
        return
    end

    local view = Blockman.instance:getCurrPersonView()
    local imageRes
    if view == 1 then
        imageRes = "main_ui/icon_bei_view"
    elseif view == 2 then
        imageRes = "main_ui/icon_first_view"
    else
        imageRes = "main_ui/icon_thrid_view"
    end
    self.viewBtn:setImage(imageRes)
    Me:sendPacket({
        pid = "SyncViewInfo",
        view = Blockman.instance:getCurrPersonView()
    })

    Lib.emitEvent(Event.FRONTSIGHT_SHOW)
end

local isInitgDiamonds
function M:changeCurrency()
    print("----------changeCurrency--------")
    local wallet = Me:data("wallet")
    local coinCfg = Coin:GetCoinCfg()
    if not World.CurWorld.isEditorEnvironment and not World.cfg.noShowCoin then
        local gDiamonds = wallet["gDiamonds"] or {}
        local coinLength = #((gDiamonds.count or 0) .. "")
        local buyBtnLayoutWidth = 100 + coinLength * 10
        self.BuyBtnLayout:setVisible(true)
        self.BuyBtnLayout:setWidth({0, buyBtnLayoutWidth})
        self:setUIXPosition(self.CountDownLayout, -buyBtnLayoutWidth - 25, isInitgDiamonds)
        self.ToolBarGoldDiamondValue:setText(gDiamonds.count or 0)
        if not isInitgDiamonds then
            self.initBuyBtnLayoutWidth = buyBtnLayoutWidth
        end
        isInitgDiamonds = true

        -- 实现ui时再搬逻辑
        -- local index = 0
        -- for _, cfg in pairs(coinCfg) do
        --     if cfg.showUi ~= false then
        --         local coinName = cfg.coinName
        --         local addBtn = cfg.addButton
        --         local iconWnd = self:getCurrencyWindow(addBtn and self.ToolBarGoldDiamond or self.currency, coinName, cfg, index)
        --         local count = Coin:countByCoinName(Me, coinName)
        --         iconWnd:GetChildByIndex(1):setText(count or 0)
        --         index = index + 1
        --     end
        -- end
    end
end

function M:tipGameCountdown(keepTime, vars, regId, textArgs, isTip)
    local leftTick = vars and vars.var or -1
    if not World.cfg.isShowCountDown or leftTick <= -1 then
        self.CountDownLayout:setVisible(false)
        return
    end

    local consumedTime = os.time() - vars.nowTime
    leftTick = leftTick - consumedTime * 20
    self.CountDownLayout:setVisible(true)

    local leftSecond = leftTick / 20
    if leftSecond <= 0 then
        return
    end
    vars.var = leftSecond * 20
    local timeHour, timeMinute, timeSecond = Lib.timeFormatting(leftSecond)
    local times = string.format("%02d:%02d", math.floor(timeHour * 60 + timeMinute), math.floor(timeSecond))
    self.countDownText:setText(times)
end

function M:propCollectCountdown(isCancel, collectorsName, CountdownTime, autoCountDown, fromPCGameOverCondition)
    if self.propCollectCountdownTimer then
        self.propCollectCountdownTimer()
        self.propCollectCountdownTimer = false
    end
    if isCancel or CountdownTime<=0 then
        self.PropCountDownLayout:setVisible(false)
        return
    end

    local function getCollectorsName()
        if fromPCGameOverCondition then
            return string.format("%s  计入倒计时", collectorsName)
        end
        local isTeam = World.cfg.team
        if not isTeam then
            return string.format("%s  计入倒计时", collectorsName)
        else
            local teamName = Lang:toText(Game.GetTeamName(collectorsName))
            return teamName .. "计入倒计时"
        end
    end

    self.PropCountDownLayout:setVisible(true)
    self:child("CountDownText_Num"):setText(CountdownTime)
    self:child("CountDownText_Tip"):setText(getCollectorsName())
    if autoCountDown and CountdownTime > 0 then
        self.propCollectCountdownTimer = World.Timer(20, self.propCollectCountdown, self, isCancel, collectorsName, CountdownTime - 1, autoCountDown, fromPCGameOverCondition)
    end
end

function M:openLocalTest()
    local editorUtil = require "editor.utils"
    local backEditBtn = self:child("backEditBtn")
    local onlineGameBtn = self:child("onlineGameBtn")
    local uploadGameBtn = self:child("uploadGameBtn")

    backEditBtn.onMouseClick = function()
        self.gameTipWnd:openGameTip(Lang:toText("win.game.isExitGame"), function ()
            EditorModule:emitEvent("enterEditorMode")
        end)
    end
    
    onlineGameBtn.onMouseClick = function()
        CGame.instance:onEditorDataReport("click_gametest_multiplayer", "", 2)
        editorUtil:screenShot(function ()
            self.gameTipWnd:openGameTip(Lang:toText("win.game.isOnlineGame"), function ()
                editorUtil:saveGameGlobalField("setting.json", "isUseNewScreenShot", true)
                CGame.instance:onEditorDataReport("click_gametest_multiplayer_confirm", "", 2)
                CGame.instance:getShellInterface():jumpToAppPage(jumpType.onlineGame)
            end, "click_gametest_multiplayer_cancel")
        end)
    end

    uploadGameBtn.onMouseClick = function()
        CGame.instance:onEditorDataReport("click_gametest_submit", "", 2)
        editorUtil:screenShot(function (screenShotImgPath)
            self.gameTipWnd:openGameScreenShotTip(function ()
                CGame.instance:onEditorDataReport("click_gametest_submit_confirm", "", 2)
                CGame.instance:getShellInterface():jumpToAppPage(jumpType.uploadGame)
            end, screenShotImgPath, editorUtil, "click_gametest_submit_cancel")
        end)
    end
    if self.chatWnd then
        self.chatWnd:setChatOffsetX(80)
    end
    self.EditGameLayout:setVisible(true)
end

function M:openOnlineRoom(roomOwnerId)
    isOpenOnlineRoomFlag = true
    local roomId = CGame.instance:getShellInterface():getRoomId()
    local roomIdText = self:child("OnlineRoomLayout_roomId")
    local roomIdtipText = self:child("OnlineRoomLayout_tipText")
    local onlineRoomBtn = self:child("OnlineRoomLayout_Btn")
    local onlineGameBtn_online = self:child("onlineGameBtn_online")

    if Me.platformUserId == roomOwnerId then
        onlineGameBtn_online:setVisible(true)
    end

    self.OnlineGameLayout:setVisible(true)
    roomIdText:setText(roomId or "21023940")
    roomIdtipText:setText(Lang:toText("win.main.online.room.info.title"))

    onlineRoomBtn.onMouseClick = function ()
        local text = Lib.splitString(Lang:toText("win.main.online.room.info.copy"), ",")
        local msg = "[colour='FF2FA926']" .. text[1] .. ", " .. "[colour='FF3C4657']" .. text[2]
        Lib.emitEvent(Event.EVENT_TOAST_TIP, msg, 20, 60, Lang:toText("win.main.online.room.info.copy"))
        CGame.instance:getShellInterface():copyToClipboard(roomId, "test")
        CGame.instance:onEditorDataReport("click_multiplayer_invite", "", 2)
    end

    onlineGameBtn_online.onMouseClick = function ()
        CGame.instance:onEditorDataReport("click_multiplayer_submit", "", 2)
        self.gameTipWnd:openGameTip(Lang:toText("win.game.isUploadGame"), function ()
            CGame.instance:onEditorDataReport("click_multiplayer_submit_confirm", "", 2)
            CGame.instance:getShellInterface():jumpToAppPage(jumpType.uploadGame)
        end, "click_multiplayer_submit_cancel")
    end
    if self.chatWnd then
        self.chatWnd:setChatOffsetX(80)
    end
end

function M:setChecked(checked) -- 和老UI保持一致，避免接口调用报错
end