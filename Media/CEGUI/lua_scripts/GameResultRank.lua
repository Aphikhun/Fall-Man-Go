local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local itemHeight = 50
local rate = {
    rank = 1,
    team = 1,
    id = 1.5,
    killCount = 1,
    score = 1,
    result = 1,
    timeScore = 1,
}

local teamCfg = World.cfg.team
if teamCfg and (not next(teamCfg)) then
    teamCfg = nil
end

local function getWidth(self, item)
    local len = self.listWidth
    local w = 0
    for k, _ in pairs(self.items or {}) do
        if rate[k] then
            w = w + rate[k]
        end
    end
    if w == 0 or not rate[item] then
        return 0
    end
    return len * rate[item] / w
end


local function init()
    self.titleName = self:child("textTitle")
    self.titleName:setText(Lang:toText("bed.summer.title"))
    self.header = self:child("imageHeader")
    self.list = self:child("listContent")
    self.listWidth = self:child("ScrollableView"):getPixelSize().width
    self.exitBtn = self:child("btnExit")
    self.replayBtn = self:child("btnAgain")
    self.exitBtn:setText(Lang:toText("game_result_exit"))
    self.replayBtn:setText(Lang:toText("game_result_replay"))
    self.myTimeSocreText = self:child("textYourScore")
    -- self.myTimeSocreText:setText("123456")
    self:setMyTimeScore(0)
    self:initImage()

    self.requestTimer = false
    self.items = false
    self.myScore = false

    self.exitBtn.onMouseClick = function()
        if World.CurWorld.isEditorEnvironment then
            EditorModule:emitEvent("enterEditorMode")
        else
            CGame.instance:exitGame()
        end
    end
    
    self.replayBtn.onMouseClick = function()
        self:close()
        if World.CurWorld.isEditorEnvironment then
            local gameRootPath = CGame.Instance():getGameRootDir()
            CGame.instance:restartGame(gameRootPath, CGame.instance:getMapName(), 1, false)
        else
            CGame.instance:getShellInterface():nextGame()
        end
    end
end

function M:initImage()
    self.exitBtn:setNormalImage("set:bed_summer.json image:button_red.png", "_imagesets_")
    self.exitBtn:setPushedImage("set:bed_summer.json image:button_red.png", "_imagesets_")
    self.replayBtn:setNormalImage("set:bed_summer.json image:button_green.png", "_imagesets_")
    self.replayBtn:setPushedImage("set:bed_summer.json image:button_green.png", "_imagesets_")
    self:child("imageContentBg"):setImage("set:bed_summer.json image:content_bg.png")
    self:child("imageTitleBg"):setImage("set:bed_summer.json image:title_big.png")
    self:child("imageHeader"):setImage("set:bed_summer.json image:title_small.png")
end

function M:logInfo(rankType)
    Lib.logInfo("EVENT_RECEIVE_RANK_DATA>>>>>>>>>")
    Lib.logInfo("rankDatas", Lib.v2s(Rank.rankDatas[rankType], 5))
    Lib.logInfo("myRanks", Lib.v2s(Rank.myRanks[rankType], 5))
    Lib.logInfo("myScores", Lib.v2s(Rank.myScores[rankType], 5))
end

function M:scoreFormat(time)
    return time == "---" and time or string.format("%.2f", (time / 1000))  .. "S"
end

function M:setMyTimeScore(time)
    self.myTimeSocreText:setText(Lang:toText("my_time_score_is") .. self:scoreFormat(time))
end

function M:showTimeRank()

end

local flag

local function findMySelf(list)
    local myTeamID = Me:getValue("teamId")
    local myUserID = Me.platformUserId
    for _, value in pairs(list or {}) do
        local found = false
        if teamCfg then
            found = value.teamID == myTeamID
        else
            found = (value.userId and value.userId == myUserID)  or Me.objID == value.objID
        end
        if found then
            local temp = Lib.copy(value)
            temp.isSelf = true
            return temp
        end
    end
end


local function addLabel(super, text, font, x, width, name, color, textBorder)
    local lb = super:createChild("WindowsLook/StaticText", name)
    lb:setArea2({0, x}, {0, 0}, {0, width}, {0, itemHeight})
    -- if textBorder then
    --     lb:setTextBoader(textBorder)
    -- end
    lb:setFont(font or "DroidSans-20")
    lb:setText(Lang:toText(text or ""))
    lb:setProperty("HorzFormatting", "CentreAligned")
    lb:setProperty("VertFormatting", "CentreAligned")
    lb:setProperty("FrameEnabled", "false")

    if color then
        lb:setProperty("TextColours", color)
    end
end

local function initHeader(cell)
    local items = self.items
    cell:setArea2({0, 0}, {0, 0}, {1, -20}, {1, 0})
    cell:setProperty("HorizontalAlignment", "1")
    local xOff = 0
    local rank_w = getWidth(self, "rank")
	local color = "FFB94F1F"
    local fontSize = "DroidSans-10"
    if rank_w > 0 then
        addLabel(cell, "game_result_rank", fontSize, xOff, rank_w, "Rank", color)
        xOff = xOff + rank_w
    end
    local team_w = getWidth(self, "team")
    if items.team and team_w > 0 then
        addLabel(cell, "game_result_team", fontSize, xOff, team_w, "Team", color)
        xOff = xOff + team_w
    end
    local id_w = getWidth(self, "id")
    if items.id and id_w > 0 then
        addLabel(cell, "game_result_id", fontSize, xOff, id_w, "ID", color)
        xOff = xOff + id_w
    end
    local kill_w = getWidth(self, "killCount")
    if items.killCount and kill_w > 0 then
        addLabel(cell, "game_result_kill_count", fontSize, xOff, kill_w, "KillCount", color)
        xOff = xOff + kill_w
    end
    
    local score_w = getWidth(self, "score")
    if items.score and score_w > 0 then
        addLabel(cell, "game_result_score", fontSize, xOff, score_w, "Score", color)
        xOff = xOff + score_w
    end

    local result_w = getWidth(self, "result")
    if items.result and result_w > 0 then
        addLabel(cell, "game_result_result", fontSize, xOff, result_w, "Result", color)
    end

    local score_w = getWidth(self, "timeScore")
    if items.timeScore and score_w > 0 then
        addLabel(cell, "game_result_time", fontSize, xOff, score_w, "timeScore", color)
        xOff = xOff + score_w
    end
end


local function initCell(cell, index, item)
    cell:setArea2({0, 0}, {0, 0}, {0.95, 0}, {0, itemHeight})
    local image = cell:createChild("WindowsLook/StaticImage", "Image" .. index)
    image:setProperty("FrameEnabled", "false")
	image:setArea2({0, 0}, {0, 0}, {1, 0}, {1, 0})
    image:setImage(item.isSelf and "set:bed_summer.json image:sort_bg_self.png" or "set:bed_summer.json image:sort_bg_other.png", "_imagesets_")
    local xOff = 0
    local fontSize = "DroidSans-10"
    if item.rank then
        local w = getWidth(self, "rank")
        addLabel(cell, item.rank, fontSize, xOff, w, "Rank", "FFF1CEA0")
        xOff = xOff + w
    end
    local teamID = item.team or item.teamID
    if teamID and teamID > 0 then
        local teams = World.cfg.team or {}
        local image = Game.GetTeamIcon(teamID)
        local w = getWidth(self, "team")
        local Content = winMgr:createWindow("DefaultWindow", "Content")
        Content:setArea2({0, xOff}, {0, 0}, {0, w}, {0, itemHeight})
        xOff = xOff + w
        cell:addChild(Content)
        local team = winMgr:createWindow("WindowsLook/StaticImage", "Team")
        team:setProperty("FrameEnabled", "false")
        team:setArea2({0, 0}, {0, 0}, {0, 30}, {0, 30})
        team:setImage(image)
        team:setHorizontalAlignment(1)
        team:setVerticalAlignment(1)
        Content:addChild(team)
    end
    if item.name then
        local w = getWidth(self, "id")
        addLabel(cell, item.name, fontSize, xOff, w, "Id")
        xOff = xOff + w
    end
    if item.killCount then
        local w = getWidth(self, "killCount")
        addLabel(cell, item.killCount, fontSize, xOff, w, "KillCount")
        xOff = xOff + w
    end
    if item.score then
        local w = getWidth(self, "score")
        addLabel(cell, item.score, fontSize, xOff, w, "Score")
        xOff = xOff + w
    end
    if item.result then
        local w = getWidth(self, "result")
        local win = item.result == "WIN"
        local winText = win and "game.result.win" or "game.result.lose"
        addLabel(cell, winText, fontSize, xOff, w, "Result", win and "FFFFFFFF" or "FF9C2616")
        xOff = xOff + w
    end
    if item.timeScore then
        local w = getWidth(self, "timeScore")
        addLabel(cell, self:scoreFormat(item.timeScore), fontSize, xOff, w, "timeScore")
        xOff = xOff + w
    end

    return cell
end

local function fillListView(self, list)
    local index = 1
    local function addCell(item)
        local cell = self.list:createChild("DefaultWindow", "DefaultWindow-1" .. index)
        initCell(cell, index, item)
        index = index + 1
    end
    self.list:cleanupChildren()
    self.header:cleanupChildren()
    local header = self.header:createChild("DefaultWindow", "DefaultWindow-1")
    initHeader(header)

    local rankTypeFuncs = {}
    
    function rankTypeFuncs.initByDefaultRank(self)
        addCell(findMySelf(list))
        for _, v in ipairs(list) do
            addCell(v)
        end
    end

    function rankTypeFuncs.initByTimeRank(self)
        local myItem, timeScore
        local myRank = Rank.GetMyRanks(2)[1] or 0
        local rank = tostring(myRank) == "0" and "---" or myRank
        local score = Rank.GetMyScores(2)[1] or 0
        score = score == 0 and "---" or score
        local useInfo = UserInfoCache.GetCache(Me.platformUserId)
        local name = useInfo and useInfo.nickName
        if CGame.instance:getIsEditorEnvironment() then
            rank = "1"
            timeScore = self.myScore
            list = {{rank = rank, timeScore = timeScore, name = name or Me.name} }
        end
        local mycell = findMySelf(list)
        if mycell then
            addCell(mycell)
        else
            addCell({rank = rank, timeScore = timeScore, name = name or Me.name, isSelf = true})
        end
        for _, v in ipairs(list or {}) do
            addCell(v)
        end
    end

    local rankTypeFuncsMap = {
        Default = rankTypeFuncs.initByDefaultRank,
        Time = rankTypeFuncs.initByTimeRank,
    }

    local func = rankTypeFuncsMap[self.uiType] or rankTypeFuncsMap["Default"]
    if func then
        func(self)
    else
        Lib.logError("ui rank type is not exist")
    end
end

function M:refreshData(packet)
    local rankTypeFuncs = {}
    self.rankData = false
    function rankTypeFuncs.initByDefaultRank()
        local result = packet.result or {}
        fillListView(self, result)
        self.myTimeSocreText:setVisible(false)
    end

    function rankTypeFuncs.initByTimeRank()
        if not flag then
            Lib.subscribeEvent(Event.EVENT_RECEIVE_RANK_DATA, function(rankType)
                local data = Rank.GetRankData(rankType)[1]
                for k, v in pairs(data or {}) do
                    local score = v.score
                    v.score = nil
                    v.timeScore = score
                end
                local dataStr = Lib.v2s(data)
                if not self.rankData then
                    fillListView(self, data)
                elseif self.rankData ~= dataStr then
                    fillListView(self, data)
                end
                self.rankData = dataStr
            end)
            flag = true
        end
        if self.requestTimer then
            self.requestTimer()
        end
        self.requestTimer = World.Timer(20, function()
            Rank.RequestRankData(2)
            return true
        end)
        self.myScore = packet.result.myTime or 0
        self:setMyTimeScore(self.myScore)
        if CGame.instance:getIsEditorEnvironment() then
            local rank = "1"
            local timeScore = self.myScore
            fillListView(self, {{rank = rank, timeScore = timeScore, name = Me.name}})
        end
    end

    local rankTypeFuncsMap = {
        Default = rankTypeFuncs.initByDefaultRank,
        Time = rankTypeFuncs.initByTimeRank,
    }
    local func = rankTypeFuncsMap[self.uiType] or rankTypeFuncsMap["Default"]
    if func then
        func(self)
    else
        Lib.logError("ui rank type is not exist")
    end
end

function M:initItems(packet)

    self.items = false
    local rankTypeFuncs = {}
    function rankTypeFuncs.initByTimeRank(self)
        self.items = {rank = true, id = true, timeScore = true}
    end

    function rankTypeFuncs.initByDefaultRank(self)
        local packetDataItem = packet and packet.result or {}
        packetDataItem = packetDataItem[1] or {}
        local team = packetDataItem.team or packetDataItem.teamID
        local items = {rank = true, id = packetDataItem.name}
        if team and team > 0 then
            items.team = true
        end 
        if packetDataItem.score then
            items.score = true
        end
        if packetDataItem.killCount then
            items.killCount = true
        end
        if packetDataItem.result then
            items.result = true
        end
        self.items = items
    end

    local rankTypeFuncsMap = {
        Default = rankTypeFuncs.initByDefaultRank,
        Time = rankTypeFuncs.initByTimeRank,
    }

    local func = rankTypeFuncsMap[self.uiType] or rankTypeFuncsMap["Default"]
    if func then
        func(self)
    else
        Lib.logError("ui rank type is not exist")
    end
end

function M:onOpen(packet, uiType)
    self.uiType = uiType
    self:initItems(packet)
    self:refreshData(packet)
end

init()