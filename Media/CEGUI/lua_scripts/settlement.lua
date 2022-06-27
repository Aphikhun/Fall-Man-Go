function M:onOpen()
    self:init()
end

function M:initUi()
    self.finalsummaryExit = self:child("FinalSummary_Exit")
    self.finalsummaryContinue = self:child("FinalSummary_Continue")
    self.rankList = self:child("FinalSummary_AllRank_Content_List")
    self.fewardProgress = self:child("FinalSummary_Self_Reward_Slider_Slider")
    self.rewardText = self:child("FinalSummary_Self_Reward_Slider_Text")
    self.finalsummaryTitle = self:child("FinalSummary_Title")
    self.finalsummarySelfRank = self:child("FinalSummary_Self_RankTitle")
    self.finalsummarySelfRewrad = self:child("FinalSummary_Self_RewardTitle")
    self.finalsummaryRank = self:child("FinalSummary_AllRank_Title_Rank")
    self.finalsummaryName = self:child("FinalSummary_AllRank_Title_Name")
    self.finalsummaryRewrad = self:child("FinalSummary_AllRank_Title_Reward")
end

function M:initLang()
    self.finalsummaryExit:setText(Lang:toText("gui.exit"))
    self.finalsummaryContinue:setText(Lang:toText("gui.continue"))
    self.finalsummaryTitle:setText(Lang:toText("dead.summary.title"))
    self.finalsummarySelfRank:setText(Lang:toText("dead.summary.rank"))
    self.finalsummarySelfRewrad:setText(Lang:toText("dead.summary.reward"))
    self.finalsummaryRank:setText(Lang:toText("final.summary.rank"))
    self.finalsummaryName:setText(Lang:toText("final.summary.player"))
    self.finalsummaryRewrad:setText(Lang:toText("final.summary.reward"))
end

function M:initEvent()
    self.finalsummaryExit.onMouseClick = function()
        if World.CurWorld.isEditorEnvironment then
            EditorModule:emitEvent("enterEditorMode")
        else
            CGame.instance:exitGame()
        end
    end
    self.finalsummaryContinue.onMouseClick = function()
        UI:closeWindow(self)
        self.showAll()
        if self.isNextServer then
            CGame.instance:getShellInterface():nextGame()
        end
    end
end

function M:initData()
    self.isNextServer = false
    self.selfResultEntry = nil
    self.resultlist = {}
    self.showAll = nil
end

function M:init()
    self:initUi()
    self:initLang()
    self:initEvent()
    self:initData()
end

function M:receiveFinalSummary(result, isNextServer, func)
    self.resultlist = {}
    self.showAll = func
    self:getResultEntryList(result)
    self:setIsNextServer(isNextServer)
    self:refreshAllRank()
    self.reloadArg = table.pack(result, isNextServer, func)
end

function M:refreshAllRank()
    self.rankList:cleanupChildren()
    self.rankList:setSpace(66)
    for i, iter in pairs(self.resultlist) do
        if iter.isSelf then
            self.selfResultEntry = iter
            self:refreshSelf()
        end
        local bgimage, image, tenimage = self:getImageByRank(iter.playerRank)
        local imgs = {
            bgimage = bgimage,
            image = image,
            tenimage = tenimage
        }
        local psummaryitem = UI:openWidget("summary_item", "_layouts_", iter, imgs)
        psummaryitem:setArea2({ 0, 0 }, { 0, 0 }, { 1, 0 }, { 0, 66 })
        self.rankList:addChild(psummaryitem:getWindow())
    end
end

function M:refreshSelf()
    local bgimage = ""
    local image = ""
    local tenimage = ""
    bgimage, image, tenimage = self:getImageByRank(self.selfResultEntry.playerRank)
    local nameText = self:child("FinalSummary_Self_Name")
    nameText:setText(self.selfResultEntry.playerName)
    local rankBgImage = self:child("FinalSummary_Self_RankBg")
    rankBgImage:setProperty("Image", bgimage)
    local rankimage = self:child("FinalSummary_Self_Rank")
    local doubleRank = self:child("FinalSummary_Self_DoubleRank")
    if tonumber(self.selfResultEntry.playerRank) > 9 then
        doubleRank:setVisible(true)
        rankimage:setVisible(false)
        self:child("FinalSummary_Self_DoubleRank_Ten"):setProperty("Image", tenimage)
        self:child("FinalSummary_Self_DoubleRank_One"):setProperty("Image", image)
    else
        doubleRank:setVisible(false)
        rankimage:setVisible(true)
        rankimage:setProperty("Image", image)
    end

    local FinalSummaryWin = "cegui_summary/BigWinEn"
    local FinalSummaryLose = "cegui_summary/BigLoseEn"
    local FinalSummaryDraw = "cegui_summary/BigDogfallEn"

    if World.Lang == "zh_CN" then
        FinalSummaryWin = "cegui_summary/BigWinCN"
        FinalSummaryLose = "cegui_summary/BigLoseCN"
        FinalSummaryDraw = "cegui_summary/BigDogfallCN"
    end
    local result = self:child("FinalSummary_Result")
    if self.selfResultEntry.isWin == 1 then
        result:setProperty("Image", FinalSummaryWin)
    elseif self.selfResultEntry.isWin == 0 then
        result:setProperty("Image", FinalSummaryLose)
    else
        result:setProperty("Image", FinalSummaryDraw)
    end

    local rewardTxt = self:child("FinalSummary_Self_Reward")
    local txt = tostring(self.selfResultEntry.reward)
    rewardTxt:setText(txt)

    self.fewardProgress:setProgress(self.selfResultEntry.todayGetRewarld == 0 and 0 or self.selfResultEntry.todayGetRewarld / self.selfResultEntry.canGetReward)
    txt = string.format("%d/%d", self.selfResultEntry.todayGetRewarld, self.selfResultEntry.canGetReward)
    self.rewardText:setText(txt)

    local vipIconRes = ""
    if self.selfResultEntry.vip == 1 then
        vipIconRes = "cegui_summary/VIP"
    elseif self.selfResultEntry.vip == 2 then
        vipIconRes = "cegui_summary/VIPPlus"
    elseif self.selfResultEntry.vip == 3 then
        vipIconRes = "cegui_summary/MVP"
    else
        vipIconRes = ""
    end
    self:child("FinalSummary_Self_VipIcon"):setProperty("Image", vipIconRes)
end

function M:getResultEntryList(result)
    if result == nil then
        self.resultlist = {}
    end
    if result.own == nil or result.players == nil then
        error("The game result content missed some field.")
    end
    local userId = result.own.userId
    for _, player in pairs(result.players) do
        if (not player.name or not player.userId or not player.rank or not player.iswin or not player.gold
                or not player.hasGet or not player.available or not player.vip) then
            error("The game result content missed some field.")
        end
        local item = {}
        item.playerName = player.name
        item.playerRank = tonumber(player.rank)
        item.isWin = tonumber(player.iswin)
        item.playerKillNum = tonumber(player.skills)
        item.isSelf = player.userId == userId
        item.reward = tonumber(player.gold)
        item.todayGetRewarld = tonumber(player.hasGet)
        item.canGetReward = tonumber(player.available)
        item.vip = tonumber(player.vip)
        item.score = tonumber(player.score) or nil
        self.resultlist[#self.resultlist + 1] = item
    end
    table.sort(self.resultlist, function(a, b)
        if a.playerRank == b.playerRank then
            error("ERROR:rank = rank")
        end
        return a.playerRank < b.playerRank
    end)
end

local rankImg = {
    "new_gui_material/brown_icon",
    "new_gui_material/red_icon",
    "new_gui_material/yellow_icon",
    "new_gui_material/blue_icon",
}

function M:getImageByRank(rank)
    local bgimage = rank and rankImg[rank + 1] or rankImg[1]
    local image, tenimage = ""
    local _rank = rank % 100
    if _rank > 9 then
        image = self:getNumImage((_rank % 10))
        tenimage = self:getNumImage(math.floor(_rank / 10))
    else
        image = self:getNumImage(_rank)
    end
    return bgimage, image, tenimage
end

local numImg = {
    "new_gui_material/number_zero",
    "new_gui_material/number_one",
    "new_gui_material/number_two",
    "new_gui_material/number_three",
    "new_gui_material/number_four",
    "new_gui_material/number_five",
    "new_gui_material/number_six",
    "new_gui_material/number_seven",
    "new_gui_material/number_eight",
    "new_gui_material/number_nine"
}

function M:getNumImage(num)
    return numImg[num + 1] or numImg[1]
end

function M:setIsNextServer(isNextServer)
    if isNextServer == nil then
        self.isNextServer = isNextServer or false
    else
        self.isNextServer = isNextServer
    end
    self.finalsummaryContinue:setVisible(self.isNextServer)
end

function M:onReload(reloadArg)
	local result, isNextServer = table.unpack(reloadArg or {}, 1, reloadArg and reloadArg.n)
	self:receiveFinalSummary(result, isNextServer)
end