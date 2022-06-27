function M:onOpen(playerData)
    self:initData(playerData)
    self:init()
end

function M:initData(playerData)
    self.playerItemMap = playerData.playerItemMap
    self.playerDataMap = playerData.playerDataMap
    self.playersPanelTipShowTime = playerData.playersPanelTipShowTime
    self.playersPanelTipMessage = playerData.playersPanelTipMessage
    self.playersPanelTipTimerCloser = false
end

function M:init()
    self:setVisible(false)
    self.playersPanelList = self.ScrollablePane.MenuPlayer_PlayerList
    self.playersPanelTipWidget = self.MenuPlayer_Tip_Message
    self.playersPanelTipWidget:setText("")

    Lib.subscribeEvent(Event.EVENT_PLAYER_STATUS, function(status, uId, uName)
        print("EVENT_PLAYER_STATUS", status, uId, uName)
        if status == 1 then -- delete
            self.playerDataMap[uId] = nil
            CGame.instance:getShellInterface():userChange("", "", uId, 0, false)
            self:updatePlayerList(self.playerDataMap)     --reset playerlist
        else   -- add
            self.playerDataMap[uId] = {name = uName, userId = uId, isFriend = (uId == Me.platformUserId), isFriendRequest = false}
            self:createPlayerListItem(uName, uId)
            CGame.instance:getShellInterface():userChange(uName, "", uId, 0, true)
        end
        self:updatePlayerItem()
    end)

    Lib.subscribeEvent(Event.EVENT_PLAYER_RECONNECT, function()
        self:updatePlayerItem()
    end)

    Lib.subscribeEvent(Event.EVENT_FRIEND_OPERATION, function(operationType, playerPlatformId)
        self:onFriendOperationForAppHttpResult(operationType, playerPlatformId)
        self:updatePlayerItem()
    end)

    Lib.subscribeEvent(Event.EVENT_FRIEND_OPERATION_FOR_SERVER, function(operationType, playerPlatformId)
        self:friendOpreationForServer(operationType, playerPlatformId)
        self:updatePlayerItem()
    end)

    Lib.subscribeEvent(Event.EVENT_FRIEND_OPERATION_NOTICE, function(operationType, playerPlatformId)
        --for the gear
        local opType = FriendManager.operationType
        if operationType == opType.AGREE then
            operationType = 3
        elseif operationType == opType.ADD_FRIEND then
            operationType = 4
        end
        if type(operationType) == "number" then
            Lib.emitEvent(Event.EVENT_FRIEND_OPERATION_FOR_SERVER, operationType, playerPlatformId)
        end
    end)
end

function M:updatePlayerList(playerlist)
    if (next(playerlist) == nil) then
        return
    end
    self.playersPanelList:cleanupChildren()
    self.playerItemMap = {}
    self:createPlayerListItem(Me.name, Me.platformUserId)
    for _, player in pairs(playerlist) do
        if player.userId ~= Me.platformUserId and (not self.playerItemMap[player.userId]) then
            self:createPlayerListItem(player.name, player.userId)
        end
    end
    self:updatePlayerItem()
end

function M:createPlayerListItem(name, userId)
    if not name or not userId then
        return
    end
    if userId == Me.platformUserId then
        name = name.."(me)"
    end
    local playerItem = UI:openWidget("menu_player_item", "_layouts_", name, userId, self)
    -- local playerItem = GUIWindowManager.instance:LoadWindowFromJSON("MenuPlayerItem.json")
    self.playersPanelList:addChild(playerItem:getWindow())
    self.playerItemMap[userId] = playerItem
end

----------------------------------------
-- Friend
function M:friendOpreation(userId, viewId, btn, message)
    local playerData = self.playerDataMap[userId]
    if playerData then
        if viewId == 0 then -- BTN_NEGLECT
            playerData.isFriendRequest = false
            btn:setText(Lang:toText("gui_player_list_item_add_friend"))
            playerData.enabled = false
        elseif viewId == 1 then--BTN_AGREE
            CGame.instance:getShellInterface():onFriendOperation(1, userId)
        elseif viewId == 2 then
            CGame.instance:getShellInterface():onFriendOperation(2, userId)
            btn:setText(Lang:toText("gui_player_list_item_add_friend_msg_sent"))
            playerData.enabled = true
        end
        self:updatePlayerItem()
    end
end

function M:updatePlayerItem()
    for uId, playerItem in pairs(self.playerItemMap) do
        local playerData = self.playerDataMap[uId]
        if not playerData then
            goto continue
        end
        local playerName = playerItem.MenuPlayerItem_Name
        if playerData.isFriend then
            playerItem.MenuPlayerItem_Friend_Icon:setVisible(uId ~= Me.platformUserId)
            playerName:setProperty("TextColours", "ffa5e95d")
        else
            playerName:setProperty("TextColours", playerData.isFriendRequest and "ffff3c32" or "ffecdec9")
        end
        playerItem.MenuPlayerItem_Message:setVisible((playerData.isFriendRequest) and (uId ~= Me.platformUserId))
        playerItem.MenuPlayerItem_Btn_Neglect:setVisible((playerData.isFriendRequest) and (uId ~= Me.platformUserId))
        playerItem.MenuPlayerItem_Btn_Agree:setVisible((playerData.isFriendRequest) and (uId ~= Me.platformUserId))
        local btnAddFriend = playerItem.MenuPlayerItem_Btn_Add_Friend
        btnAddFriend:setVisible((not (playerData.isFriend)) and (not (playerData.isFriendRequest)) and (uId ~= Me.platformUserId) and (not FunctionSetting:disableFriend()))
        btnAddFriend:setEnabled(not playerData.enabled)
        btnAddFriend:setText(Lang:toText(playerData.enabled and "gui_player_list_item_add_friend_msg_sent" or "gui_player_list_item_add_friend"))
        ::continue::
    end
    local timerCloser = self.playersPanelTipTimerCloser
    if timerCloser then
        timerCloser()
    end
    self.playersPanelTipTimerCloser = World.Timer(1, function()
        local showTime = self.playersPanelTipShowTime
        if showTime == 0 or showTime > 2000 then
            self.playersPanelTipWidget:setText("")
        else
            self.playersPanelTipShowTime = showTime + 50
            self.playersPanelTipWidget:setText(self.playersPanelTipMessage)
        end
    end)
end

function M:friendOpreationForServer(operationType, userId)
    local playerData = self.playerDataMap[userId]
    if playerData then
        if operationType == 3 then -- AGREE_ADD_FRIEND
            playerData.isFriend = true
            playerData.isFriendRequest = false
        elseif operationType == 4 then--REQUEST_ADD_FRIEND
            playerData.isFriendRequest = true
            Lib.emitEvent(Event.EVENT_SHOW_RED_POINT)
        end
    end
end

function M:onFriendOperationForAppHttpResult(operationType, userId)
    local playerData = self.playerDataMap[userId]
    if not playerData then
        return
    end
    if operationType == 1 then  --NO_FRIEND
        playerData.isFriend = false
    elseif operationType == 2 then     --IS_FRIEND
        playerData.isFriend = true
        playerData.isFriendRequest = false
    elseif operationType == 3 then    --AGREE_ADD_FRIEND
        Me:sendPacket({
            pid = "SendFriendOperation",
            operationType = operationType,
            userId = userId
        }, function() end)
        playerData.isFriend = true
        playerData.isFriendRequest = false
    elseif operationType == 4 then    --REQUEST_ADD_FRIEND
        Me:sendPacket({
            pid = "SendFriendOperation",
            operationType = operationType,
            userId = userId
        }, function() end)
    elseif operationType == 10000 then --REQUEST_ADD_FRIEND_FAILURE
        self.playersPanelTipShowTime = 1
        self.playersPanelTipMessage = Lang:toText("gui_player_list_item_add_friend_msg_send_failure")
        local playerItem = self.playerItemMap[userId]
        if playerItem then
            playerItem.MenuPlayerItem_Btn_Add_Friend:setText(Lang:toText("gui_player_list_item_add_friend"))
            playerData.enabled = false
        end
    elseif operationType == 10001 then --AGREE_ADD_FRIEND_FAILURE
        self.playersPanelTipShowTime = 1
        self.playersPanelTipMessage = Lang:toText("gui_player_list_item_add_friend_msg_agree_failure")
    end
end

function M:invoke(funcName, ...)
    assert(self[funcName], "invoke not func, funcName: " .. funcName)
    self[funcName](self, ...)
end

function M:onClose()
    local closer = self.playersPanelTipTimerCloser
    if closer then
        closer()
        self.playersPanelTipTimerCloser = nil
    end
end
