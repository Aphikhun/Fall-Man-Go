local teamCfg = World.cfg.team
local function stopTimer(self)
    if self.refreshTimer then
        self.refreshTimer()
        self.refreshTimer = false
    end
end

function M:subscribeRankEvent()
    Lib.subscribeEvent(Event.EVENT_UPDATE_TEAM_RANK, function(rankData)
        if not teamCfg then
            return
        end
        self:updateRankList(rankData)
    end)

    Lib.subscribeEvent(Event.EVENT_RANK_DATA_DIRTY, function(rankType)
        if not self.showGameTimeRank or rankType ~= 2 then
            return
        end
        Rank.RequestRankData(rankType)
    end)

    Lib.subscribeEvent(Event.EVENT_RECEIVE_RANK_DATA, function(rankType)
        if not self.showGameTimeRank or rankType ~= 2 then
            return
        end
        self:refreshGameTimeRank()
    end)

    Lib.subscribeEvent(Event.EVENT_GAME_START, function()
        if not self.rankList then
            self:initRankList()
        end
        World.Timer(20, function()
            self:showPlayTime()
        end)
    end)

    Lib.subscribeEvent(Event.EVENT_FINISH_DEAL_GAME_INFO, function()
        if Game.GetState() ~= "GAME_GO" then
            return
        end
        World.Timer(40, function()
            self:showPlayTime()
        end)
    end)

    Lib.subscribeEvent(Event.EVENT_GAME_RESULT, function(packet)
        self:setGameTimeText(packet.result.myTime)
        stopTimer(self)
        self.dontCountDown = true
    end)
end

function M:getNewRankItem(rankData, textColor)
    return UI:openWidget("teamRankItem", "_layouts_", rankData, self.showGameTimeRank, textColor):getWindow()
end

local function formatTime(gameTime)
    if math.tointeger(gameTime) then
        gameTime = string.format("%.02fs", gameTime / 1000)
    end
    return gameTime
end

function M:setGameTimeText(time)
    if time then
        self.gameTimeText:setText(formatTime(time))
    end
end

function M:onDestroy()
    stopTimer(self)
end

function M:showPlayTime()
    if not self.showGameTimeRank then
        return
    end

    if self.dontCountDown then
        return
    end

    if self.startedTimer then
        return
    end

    Me:startPlayTime()
    self.startedTimer = true

    self.refreshTimer = World.Timer(1, function ()
        if not self.gameTimeText then
            self.refreshTimer()
            self.refreshTimer = false
            return false
        end
        local text = formatTime(Me:getPlayTime(true))
        self.gameTimeText:setText(text)
        return true
    end)
end

function M:refreshGameTimeRank()
    local data = Rank.GetRankData(2)[1]
    self:updateRankList(data, true)
end

function M:initData(rankCondition)
    self.myRankData = false
    self.refreshTimer = false
    self.showKillCount = rankCondition.showKillCount
    self.showScore = rankCondition.showScore
    self.showGameTimeRank = rankCondition.showGameTimeRank
    self.dontCountDown = false
    self.startedTimer = false
end

function M:onOpen(rankCondition)
    self:initData(rankCondition)
    self:init()
    self:subscribeRankEvent()
end

function M:init()
    self.rankList = self:child("Team_Rank_List_Container")
    self.openRankListBtn = self:child("Team_Rank_List_Open")
    self.openRankListBg = self:child("Team_Rank_List_Title_Bg")
    self.rankListDetail = self:child("Team_Rank_List_Detail")
    self.rankListFoldBtn = self:child("Team_Rank_List_Fold")
    self.rankListGameTime = self:child("Rank_List_GameTime")
    self.gameTimeText = self:child("Rank_List_GameTime_Time")

    local function openRank(isOpen)
        self.rankListDetail:setVisible(isOpen)
        self.openRankListBtn:setVisible(not isOpen)
        self.rankListGameTime:setVisible(not isOpen)
    end

    self.openRankListBtn.onMouseClick = function ()
        openRank(true)
    end
    self.rankListFoldBtn.onMouseClick = function ()
        openRank(false)
    end
    self.openRankListBg.onMouseClick = function ()
        openRank(false)
    end

    self:child("Team_Rank_List_Title_Text"):setText(Lang:toText("battle_info"))
    self:child("Team_Rank_List_Title_Rank"):setText(Lang:toText("rank"))
    self:child("Team_Rank_List_Title_TeamIcon"):setText(not self.showGameTimeRank and (teamCfg and Lang:toText("team") or "ID") or "ID")
    self:child("Team_Rank_List_Title_KillCount"):setText(not self.showGameTimeRank and (self.showKillCount and Lang:toText("kill_count") or "") or Lang:toText("time"))
    self:child("Team_Rank_List_Title_Score"):setText(not self.showGameTimeRank and (self.showScore and Lang:toText("score") or "") or "")
    self:child("Rank_List_GameTime_Title"):setText(Lang:toText("battle.linfo.game.time"))
    self:child("Rank_List_GameTime_Title"):setVisible(self.showGameTimeRank)
end

local myObjID, myUserId, myName = Me.objID, Me.platformUserId, Me.name

local function isMe(rankData)
    if rankData.objID == myObjID then
        return true
    end
    if rankData.userId == myUserId then
        return true
    end
    return false
end

function M:updateRankList(rankData, isGameTimeData)
    if (self.showGameTimeRank and not isGameTimeData) then
        return
    end
    local rankList = assert(self.rankList)
    self.myRankData = false
    rankList:cleanupChildren()

    for _, data in pairs(rankData) do
        if isMe(data)  then
            self.myRankData = data
            break
        end
    end

    if self.showGameTimeRank or not teamCfg then
        if not self.myRankData then
            local cache = UserInfoCache.GetCache(myUserId)
            myName = cache and cache.name or Me.name
            self.myRankData = {
                name = myName,
                rank = "---",
                score = "---",
                objID = myObjID,
            }
        end
        local rankItem = self:getNewRankItem(self.myRankData, "ffffff00")
        rankList:addChild(rankItem)
    end

    for _, data in pairs(rankData) do
        local rankItem = self:getNewRankItem(data, "ffffffff")
        rankList:addChild(rankItem)--add to top
    end
end

function M:getMyRankData()
    return self.myRankData
end

return M