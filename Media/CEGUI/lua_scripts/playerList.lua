local operationType = FriendManager.operationType

M.capacity = 0
M.infoMap = {}

local EState = {
    PendingRequest = 1, -- 待处理请求
    Friend = 2, -- 好友
    Requesting = 3, -- 请求中
    Stranger = 4,  -- 陌生人
    BeRefused = 5, -- 被拒绝
}

local StateWeigthSet = {
    [EState.PendingRequest] = 4,
    [EState.Friend] = 3,
    [EState.Requesting] = 2,
    [EState.Stranger] = 1,
    [EState.BeRefused] = 1,
}

local EventMap = {
    AddButton = {
        onMouseClick = function (instance)
            instance.info.state = EState.Requesting
            AsyncProcess.FriendOperation(operationType.ADD_FRIEND, instance.info.userId)
            M:updatePlayerList()
        end
    },
    IgnoreButton = {
        onMouseClick = function (instance)
            instance.info.state = EState.Stranger
            AsyncProcess.FriendOperation(operationType.REFUSE, instance.info.userId)
            M:updatePlayerList()
        end
    },
    AgreeButton = {
        onMouseClick = function (instance)
            instance.info.state = EState.Friend
            AsyncProcess.FriendOperation(operationType.AGREE, instance.info.userId)
            M:updatePlayerList()
        end
    },
}
function M.MainLayout.TabLayout.ReturnTab:onMouseClick()
    M:setVisible(false)
end

function M.MainLayout.ScrollableView:onMouseButtonDown()
    local window = self:child("__auto_vscrollbar__")
    window.originalDocumentSize = window:getDocumentSize()
    window.originalMaxPosition = window:getMaxScrollPosition()
    window:setDocumentSize(window.originalDocumentSize+100)
end

function M.MainLayout.ScrollableView:onMouseButtonUp()
    local window = self:child("__auto_vscrollbar__")
    window:setDocumentSize(window.originalDocumentSize)
    if window:getScrollPosition() > window.originalMaxPosition then
        window:setScrollPosition(window.originalMaxPosition)
    end
end

function M:createPlayerItem(name)
    local window = M.MainLayout.ScrollableView.PlayerList.Player:clone()
    window:setName(name)
    M.MainLayout.ScrollableView.PlayerList:addChild(window.__window)
    M.capacity = M.capacity + 1
    for winName, events in pairs(EventMap) do
        local win = window.FunctionalArea.Functional[winName]
        for eventName, func in pairs(events) do
            win[eventName] = func
        end
    end
    return window
end

local function hideAllChild(window)
    local count = window:getChildCount()
    for idx = 0, count-1 do
        local child = window:getChildElementAtIdx(idx)
        hideAllChild(child)
        child:setVisible(false)
    end
end

local VIPImageInfo = {
    [1] = { image = "friend/VIP"},
    [2] = { image = "friend/VIP_Pro"},
    [3] = { image = "friend/MVP"},
    [4] = { image = "friend/MVP_Pro"},
}

function M:setButtonImage(button, img)
    button.PushedImage = img
    button.HoverImage = img
    button.NormalImage = img
end

function M:updateFunctionAreaView(window, info)
    hideAllChild(window.FunctionalArea)
    window.FunctionalArea.Functional:setVisible(true)
    window.FunctionalArea:setVisible(true)
    if info.state == EState.PendingRequest then
        window.FunctionalArea.Desc:setVisible(true)
        window.FunctionalArea.Desc:setText(Lang:toText("playerList.pendingRequest"))
        window.FunctionalArea.Functional.IgnoreButton:setVisible(true)
        window.FunctionalArea.Functional.AgreeButton:setVisible(true)
    elseif info.state == EState.Friend then

    elseif info.state == EState.Requesting then
        if not info.timer then
            FriendManager.UpdateCdTime(info.userId, operationType.ADD_FRIEND)
            info.timer = World.Timer(1, function()
                if FriendManager.CanAddFriend(info.userId) then
                    if info.state == EState.Requesting or info.state == EState.BeRefused then
                        info.state = EState.Stranger
                        M:updatePlayerList()
                    end
                    info.timer = nil
                    return false
                else
                    return true
                end
            end)
        end

        local AddButton = window.FunctionalArea.Functional.AddButton
        M:setButtonImage(AddButton, "friend/icon_AddFriend_Hui")

        AddButton:setEnabled(false)
        AddButton:setVisible(true)

        AddButton.AddImage:setImage("friend/img_+_unable")
        AddButton.AddImage:setVisible(true)
        AddButton.Text:setText(Lang:toText("playerList.requesting"))
        AddButton.Text:setVisible(true)
    elseif info.state == EState.BeRefused then
        local AddButton = window.FunctionalArea.Functional.AddButton
        M:setButtonImage(AddButton, "friend/icon_AddFriend_Hui")
        AddButton:setEnabled(false)
        AddButton:setEnabled(false)
        AddButton:setVisible(true)
    elseif info.state == EState.Stranger then
        local AddButton = window.FunctionalArea.Functional.AddButton
        M:setButtonImage(AddButton, "friend/icon_AddFriend")
        AddButton:setEnabled(true)
        AddButton:setVisible(true)
        AddButton.AddImage:setVisible(true)
        AddButton.AddImage:setImage("friend/img_+")
        AddButton.Text:setVisible(true)
        AddButton.Text:setText(Lang:toText("playerList.stranger"))
    end
end

function M:updateNonFunctionAreaView(window, info)
    window.PlayerName:setText(info.nickName)
    window.Tribe:setText(info.clanName or "")
    
    window.AvatarFrame.Image = "friend/bg_HaoYouTouXiang"
    if info.picUrl and info.picUrl ~= "" then
        window.AvatarFrame.Avatar.Image = info.picUrl
    else
        window.AvatarFrame.Avatar.Image = "friend/TouXiangJiaZaiZhong"
    end
    
    if info.sex == 1 then
        window.Gender.Image = "friend/icon_boy"
    elseif info.sex == 2 then
        window.Gender.Image = "friend/icon_girl"
    end

    if VIPImageInfo[info.vip] then
        local vipInfo = VIPImageInfo[info.vip]
        window.VIPImage:setVisible(true)
        window.VIPImage:setImage(vipInfo.image)
    else
        window.VIPImage:setVisible(false)
    end
end

function M:updatePlayerItem(idx, info)
    local window
    local windowName = "Player" .. idx
    if idx > M.capacity then
        window = M:createPlayerItem(windowName)
    else
        window = M.MainLayout.ScrollableView.PlayerList:child(windowName)
    end
    assert(window, "no window named: " .. windowName)
    M:updateNonFunctionAreaView(window, info)
    M:updateFunctionAreaView(window, info)
    window.info = info
    window.FunctionalArea.Functional.AddButton.info = info
    window.FunctionalArea.Functional.IgnoreButton.info = info
    window.FunctionalArea.Functional.AgreeButton.info = info
    window:setVisible(true)
end

function M:removePlayerItem(idx)
    local windowName = "Player" .. idx
    local window = M.MainLayout.ScrollableView.PlayerList:child(windowName)
    window.info = nil
    window:setVisible(false)
end

function M:changeInfo(id, state)
    local info = M:getInfo(id)
    info.state = state
end

function M:updatePlayerList()
    local compare = function(lhs, rhs)
        local lWeight = StateWeigthSet[lhs.state]
        local rWeight = StateWeigthSet[rhs.state]
        if lWeight > rWeight then
            return true
        elseif lWeight == rWeight then
            if lhs.userId < rhs.userId then
                return true
            else
                return false
            end
        else
            return false
        end
    end

    local infoList = {}
    for _, info in pairs(M.infoMap) do
        if info.userId ~= Me.platformUserId then
            table.insert(infoList, info)
        end
    end
    table.sort(infoList, compare)
    for idx, info in ipairs(infoList) do
        M:updatePlayerItem(idx, info)
    end
    local curSize = #infoList
    local lastSize = M.lastSize or M.capacity
    for idx = curSize+1, lastSize do
        M:removePlayerItem(idx)
    end
    M.lastSize = curSize
end

function M:updateMainPlayerItem()
    local windowName = "Player"
    local  window = M.MainLayout.ScrollableView.PlayerList:child(windowName)
    assert(window, "no window named: " .. windowName)
    local userDetailData = Me.userDetailData
    M:updateNonFunctionAreaView(window, userDetailData)
    window.FunctionalArea:setVisible(false)
    window:setVisible(true)
end

function M:addInfo(userId, info)
    M.infoMap[userId] = info
end

function M:getInfo(userId)
    return M.infoMap[userId]
end

function M:createInfo(userId, name, state)
    local info = {name = name, userId = userId, state = state}
    return info
end

function M:removeInfo(userId)
    M.infoMap[userId] = nil
end

function M:setState(id, state)
    local info = M:getInfo(id)
    info.state = state
end

function M:subscribeEvents()
    Lib.subscribeEvent(Event.EVENT_FINISH_LOAD_FRIEND_DATA, function()
        for _, playerInfo in pairs(Game.GetAllPlayersInfo() or {}) do
            local id = playerInfo.userId
            local player = UserInfoCache.GetCache(id)
            if player then
                local info = M:getInfo(id)
                if not info then
                    info = {}
                    M:addInfo(id, info)
                end
                info.userId = player.userId
                info.nickName = player.nickName
                info.sex = player.sex
                info.clanName = player.clanName
                info.vip = player.vip
                info.picUrl = player.picUrl
                local isFriend = FriendManager.friendsMap[id]
                local state = isFriend and EState.Friend or EState.Stranger
                info.state = state
            end
        end
        self:updatePlayerList()
    end)

    Lib.subscribeEvent(Event.EVENT_FINISH_PARSE_REQUESTS_DATA, function()
        local requests = FriendManager.requests
        local needUpdate = false
        for id, _ in pairs(requests or {}) do
            local info = M:getInfo(id)
            if info and info.state ~= EState.PendingRequest then
                info.state = EState.PendingRequest
                needUpdate = true
            end
        end
        
        if needUpdate then
            self:updatePlayerList()
        end    
    end)

    Lib.subscribeEvent(Event.EVENT_FRIEND_OPERATION_NOTICE, function(operationType, playerPlatformId)
        if M:getInfo(playerPlatformId) then
            local opType = FriendManager.operationType
            if operationType == opType.AGREE then
                M:setState(playerPlatformId, EState.Friend)
            elseif operationType == opType.ADD_FRIEND then
                M:setState(playerPlatformId, EState.PendingRequest)
            elseif operationType == opType.REFUSE then
                local info = M:getInfo(playerPlatformId)
                if info.timer then
                    M:setState(playerPlatformId, EState.BeRefused)
                else
                    M:setState(playerPlatformId, EState.Stranger)
                end
            end
        end
        self:updatePlayerList()
    end)

    Lib.subscribeEvent(Event.EVENT_PLAYER_STATUS, function(status, uId, uName)
        if status == 1 then -- logout
            M:removeInfo(uId)
        else   -- login
            local player = UserInfoCache.GetCache(uId)
            if player then
                local info = M:getInfo(uId)
                if not info then
                    info = {}
                    M:addInfo(uId, info)
                end
                info.userId = player.userId
                info.nickName = player.nickName
                info.sex = player.sex
                info.clanName = player.clanName
                info.vip = player.vip
                info.picUrl = player.picUrl
                local isFriend = FriendManager.friendsMap[uId]
                local state = isFriend and EState.Friend or EState.Stranger
                info.state = state
            end
        end
        self:updatePlayerList()
    end)

    Lib.subscribeEvent(Event.EVENT_PLAYER_STATUS_2, function(status, uId, uName)
        if status == 1 then -- logout
            M:removeInfo(uId)
        else   -- login
            local player = UserInfoCache.GetCache(uId)
            if player then
                local info = M:getInfo(uId)
                if not info then
                    info = {}
                    M:addInfo(uId, info)
                end
                info.userId = player.userId
                info.nickName = player.nickName
                info.sex = player.sex
                info.clanName = player.clanName
                info.vip = player.vip
                info.picUrl = player.picUrl
                local isFriend = FriendManager.friendsMap[uId]
                local state = isFriend and EState.Friend or EState.Stranger
                info.state = state
            end
        end
        self:updatePlayerList()
    end)

    Lib.subscribeEvent(Event.LOAD_USER_DETAIL_FINISH, function()
        M:updateMainPlayerItem()
    end)
    
end

function M:init()
    M:subscribeEvents()
    M:initUI()
    M:loadData()
end

function M:onOpen()
    M:init()
    M:setVisible(false)
    M:setAlwaysOnTop(true)
end

function M:initUI()
    M.MainLayout.BgImage:setImage("setting/bg_SheZhiDiBuDieHao")
    M.MainLayout.TabLayout.BgImage:setImage("setting/bg_DingBuBiaoTi")
    M.MainLayout.TabLayout.PlayerTab:setText(Lang:toText("playerList.playerTab"))
    M:setButtonImage(M.MainLayout.TabLayout.ReturnTab, "friend/ICON_back_setting")

    local  PlayerItem = M.MainLayout.ScrollableView.PlayerList.Player
    PlayerItem.BgImage:setImage("friend/bg_HaoYouLieBiao")
    PlayerItem.BgImage:setImage("friend/bg_HaoYouLieBiao")

    M:setButtonImage(PlayerItem.FunctionalArea.Functional.AgreeButton, "friend/icon_YES")
    M:setButtonImage(PlayerItem.FunctionalArea.Functional.IgnoreButton, "friend/icon_NO")
    for winName, events in pairs(EventMap) do
        local win = PlayerItem.FunctionalArea.Functional:child(winName)
        for eventName, func in pairs(events) do
            win[eventName] = func
        end
    end
end

function M:loadData()
    AsyncProcess.NewLoadFriend()
    AsyncProcess.LoadUserRequests()
end

