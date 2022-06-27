local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local canHideTeamStatusBar = World.cfg.hideTeamStatusBar
local teamCfg = World.cfg.team
local maxPlayerCount = World.cfg.maxPlayers
local defaultRankCondition = {
    noCondition = true,
    showGameTimeRank = false,
    showKillCount = false,
    showScore = false,
}
local rankCondition = Plugins.RequireScript("editor_rankCondition") or defaultRankCondition
local showGameTimeRank = rankCondition.showGameTimeRank
local topTeamInfo = World.cfg.topTeamInfo or {}
local teamListWidthMaxCount = topTeamInfo.teamListWidthMaxCount or 8
local teamItemWidth = topTeamInfo.teamItemWidth or 70
local teamItemHeight = topTeamInfo.teamItemHeight or 48
local teamDieIcon = topTeamInfo.teamDieIcon or "cegui_new_gameUI/icon_team_die"
local teamDieIconArea = topTeamInfo.teamDieIconArea or {{0, 0}, {0, -8}, {0, 16}, {0, 8}}
local teamInfoArea = topTeamInfo.teamInfoArea or {{0,-2},{0,-3},{0,53.45},{0,17}}
local teamIconArea = topTeamInfo.teamIconArea or {{0, 8}, {0, 0}, {0, 56}, {0, teamItemHeight}}

function M:onOpen()
    self:init()
end

function M:subscribeTeamEvent()
    if canHideTeamStatusBar then
        return
    end

    Lib.subscribeEvent(Event.EVENT_PLAYER_LOGIN, function(player)
        if not World.cfg.hideTeamStatusBar and next(Game.GetAllTeamsInfo()) then
            self:updateTeamInfo(player.teamID)
        end
    end)

    Lib.subscribeEvent(Event.EVENT_PLAYER_LOGOUT, function(player)
        if not World.cfg.hideTeamStatusBar and next(Game.GetAllTeamsInfo()) then
            self:updateTeamInfo(player.teamID)
        end
    end)

    Lib.subscribeEvent(Event.EVENT_REFRESH_TEAMS_UI, function(data)
        self:updateTeamInfo(data.teamID)
    end)

    Lib.subscribeEvent(Event.EVENT_UPDATE_TEAM_INFO, function(teamID)
        self:updateTeamInfo(teamID)
    end)

    Lib.subscribeEvent(Event.EVENT_UPDATE_TEAM_STATUS_BAR, function(data)
        local new, old, objID = data.newTeamID, data.oldTeamID, data.objID
        if old ~= 0 then
            self:updateTeamInfo(old)
        end
        if new ~= 0 then
            self:updateTeamInfo(new)
        end
        if Me.objID == objID then
            self:updateTeamBg(new, old)
        end
    end)

    Lib.subscribeEvent(Event.TEAM_UPDATE, function(params)
        self:updateTeamInfo(params.teamID)
    end)

    Lib.subscribeEvent(Event.EVENT_UPDATE_ALIVE_COUNT, function(aliveCount)
        if teamCfg then
            return
        end
        self:child("TopTeamInfo_PlayerCount_Text"):setText(string.format("%s: %s/%s", Lang:toText("all_player_count"), aliveCount, maxPlayerCount))
    end)
    Lib.subscribeEvent(Event.EVENT_UPDATE_PLAYER_RANK, function(rankData)
        if not World.cfg.isShowRank or teamCfg then
            return
        end
        self.teamRankUi:updateRankList(rankData)
        local myData = self.teamRankUi:getMyRankData()
        self:updateTopFightInfoBar(myData)
    end)
end

function M:init()
    self.showTeamInfo = {}
    self.teamRankUi = false
    if teamCfg and (not next(teamCfg)) then
        teamCfg = nil
    end
    self:initRankList()
    self:subscribeTeamEvent()
end

function M:createTeamInfoItem(index, teamID)
    local ran = World.Now() .. math.random()
    local teamLayout = winMgr:createWindow("Engine/DefaultWindow", "teamLayout_" .. teamID..ran)
    local offsetX = teamItemWidth * ((index - 1) % teamListWidthMaxCount)
    local offsetY = teamItemHeight * (((index - 1) / teamListWidthMaxCount) // 1)
    teamLayout:setArea2({0, offsetX}, {0, offsetY}, {0, teamItemWidth}, {0, teamItemHeight})
    teamLayout:setMousePassThroughEnabled(true)
    teamLayout:setVisible(true)

    local bg = winMgr:createWindow("Engine/StaticImage", "teamBg_" .. teamID..ran)
    bg:setArea2({0, 0}, {0, 0}, {1, 0}, {1, 0})
    bg:setMousePassThroughEnabled(true)
    bg:setVisible(false)

    local icon = winMgr:createWindow("Engine/StaticImage", "teamIcon_" .. teamID..ran)
    icon:setArea2(table.unpack(teamIconArea))
    icon:setMousePassThroughEnabled(true)
    icon:setImage(Game.GetTeamImage(teamID) or Game.GetTeamIcon(teamID))

    local myTeamicon = winMgr:createWindow("Engine/StaticImage", "myTeamicon_" .. teamID..ran)
    myTeamicon:setArea2(table.unpack(teamIconArea))
    myTeamicon:setMousePassThroughEnabled(true)
    myTeamicon:setVisible(false)

    local dieIcon = winMgr:createWindow("Engine/StaticImage", "teamDieicon_" .. teamID..ran)
    dieIcon:setArea2(table.unpack(teamDieIconArea))
    dieIcon:setImage(teamDieIcon)
    dieIcon:setVerticalAlignment(1)
    dieIcon:setHorizontalAlignment(1)
    dieIcon:setMousePassThroughEnabled(true)
    dieIcon:setVisible(false)

    local info = winMgr:createWindow("Engine/StaticText", "teamInfo_" .. teamID..ran)
    info:setArea2(table.unpack(teamInfoArea))
    info:setMousePassThroughEnabled(true)
    info:setProperty("HorizontalAlignment", "Right")
    info:setProperty("VerticalAlignment", "Bottom")
    info:setProperty("VertFormatting", "CentreAligned")
    info:setProperty("HorzFormatting", "CentreAligned")

    self.teamList:addChild(teamLayout)
    teamLayout:addChild(bg)
    teamLayout:addChild(icon)
    teamLayout:addChild(myTeamicon)
    teamLayout:addChild(dieIcon)
    teamLayout:addChild(info)

    local teamInfo = {
        teamLayout = teamLayout,
        bg = bg,
        icon = icon,
        myTeamicon = myTeamicon,
        dieIcon = dieIcon,
        info = info,
    }
    return teamInfo
end

function M:updateTeamInfoItem(teamInfo, index)
    local teamLayout = teamInfo.teamLayout
    local offsetX = teamItemWidth * ((index - 1) % teamListWidthMaxCount)
    local offsetY = teamItemHeight * (((index - 1) / teamListWidthMaxCount) // 1)
    teamLayout:setXPosition({0, offsetX})
    teamLayout:setYPosition({0, offsetY})
end

function M:initRankList()
    if not World.cfg.isShowRank then
        return
    end
    self.teamRankUi = UI:openSystemWindow("teamRankList", nil, rankCondition)
end

function self:updateSelfTeamToFirst()
    local showTeamInfo = self.showTeamInfo
    local meTeamInfo = showTeamInfo[Me:getValue("teamId")]
    if not meTeamInfo or meTeamInfo.index == 1 then
        return
    end
    local firstTeamViewInfo
    for i, info in pairs(showTeamInfo) do
        if i ~= "teamCount" and info.index ==1 then
            firstTeamViewInfo = info
        end
    end
    if not firstTeamViewInfo then
        return
    end
    local firstTeamView = firstTeamViewInfo.teamView
    firstTeamViewInfo.index, meTeamInfo.index = meTeamInfo.index, firstTeamViewInfo.index
    local cutPlayerTeamView = meTeamInfo.teamView
    local cutPlayerTeamViewXPosition = cutPlayerTeamView.teamLayout:getXPosition()
    local cutPlayerTeamViewYPosition = cutPlayerTeamView.teamLayout:getYPosition()
    cutPlayerTeamView.teamLayout:setXPosition({0, 0})
    cutPlayerTeamView.teamLayout:setYPosition({0, 0})
    firstTeamView.teamLayout:setXPosition(cutPlayerTeamViewXPosition)
    firstTeamView.teamLayout:setYPosition(cutPlayerTeamViewYPosition)
end

local function getPlayerCount(playerList)
    local count = 0
    for _, _ in pairs(playerList) do
        count = count + 1
    end
    return count
end

function M:setTeamInfo(teamID, teamInfo)
    local showTeamInfo = self.showTeamInfo
    local teamViewInfo = showTeamInfo[teamID]
    local teamView = teamViewInfo.teamView
    if not teamViewInfo then --only show four team status bar
        return
    end
    teamView.teamLayout:setVisible(true)
    local count = getPlayerCount(teamInfo.playerList or {}) or 0
    local limit = 0
    for _,v in ipairs(teamCfg) do
        if v.id == teamID then
            limit = v.memberLimit or 4
        end
    end
    if limit then
        teamView.info:setText(count .. "/" .. limit)
    else
        teamView.info:setText(count)
    end
    if (teamInfo.state or "") == "TEAM_BED_DIE" then
        teamView.dieIcon:setVisible(true)
    end
    if teamID == Me:getValue("teamId") then
        self:updateTeamBg(teamID)
        self:updateSelfTeamToFirst()
    end
end

function M:updateTeamBg(teamID, oldTeamId)
    if oldTeamId and oldTeamId == teamID then
        return
    end
    local showTeamInfo = self.showTeamInfo
    local info = showTeamInfo[teamID]
    if info then
        local teamView = info.teamView
        teamView.myTeamicon:setImage(Game.GetMainTeamImageFrame(teamID) or Game.GetMyTeamIcon(teamID))
        teamView.bg:setImage(Game.GetMainTeamImageBg(teamID) or Game.GetMyTeamBg(teamID))
        teamView.bg:setVisible(true)
        teamView.myTeamicon:setVisible(true)
    end
    info = showTeamInfo[oldTeamId]
    if info then
        local teamView = info.teamView
        teamView.bg:setVisible(false)
        teamView.myTeamicon:setVisible(false)
    end
end

function M:updateTeamInfo(teamID)
    if teamID == 0 then
        return
    end
    local showTeamInfo = self.showTeamInfo
    if not showTeamInfo[teamID] then
        self:updateTeamInfoView(teamID)
    else
        self:setTeamInfo(teamID, Game.GetAllTeamsInfo()[teamID] or {})
    end
end

function M:updateTeamInfoView(teamID)
    if teamID == 0 then
        return
    end
    self.teamList = self:child("Top_Team_List")
    local showTeamInfo = self.showTeamInfo
    local allTeamInfo = Game.GetAllTeamsInfo()
    local teamCount = 0
    local index = 1
    for _, teamInfo in pairs(allTeamInfo) do
        local tempTeamID = teamInfo.id
        if not showTeamInfo[tempTeamID] then
            showTeamInfo[tempTeamID] = {teamID = tempTeamID, index = index, teamView = self:createTeamInfoItem(index, tempTeamID)}
        else
            showTeamInfo[tempTeamID].index = index
            self:updateTeamInfoItem(showTeamInfo[tempTeamID].teamView, index)
        end
        index = index + 1
        teamCount = teamCount + 1
    end
    showTeamInfo.teamCount = teamCount
    self.teamList:setWidth({0, ((teamCount > teamListWidthMaxCount) and teamListWidthMaxCount or teamCount) * teamItemWidth})
    self.teamList:setHeight({0, ((teamCount / (teamListWidthMaxCount + 1)) // 1 + 1) * teamItemHeight})
    for _, teamInfo in pairs(allTeamInfo) do
        self:setTeamInfo(teamInfo.id, teamInfo)
    end
    self.teamList:setVisible(true)
end

function M:updateTopFightInfoBar(myData)
    if showGameTimeRank then
        return
    end
    local killCount, score = myData.killCount, myData.score
    self:child("TopTeamInfo_KillCount_Text"):setText(killCount and string.format("%s: %s", Lang:toText("kill_count"), killCount) or "")
    self:child("TopTeamInfo_Score_Text"):setText(score and string.format("%s: %s", Lang:toText("score"), score) or "")
end

return M