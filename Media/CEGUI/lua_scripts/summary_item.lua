function M:onOpen(rankdate, imgs)
    self:init(rankdate, imgs)
end

function M:init(rankdate, imgs)
    local rankBgImage = self.SummaryItem_RankBg
    local rankImage = self.SummaryItem_Rank
    local itemName = self.SummaryItem_Name
    local rewardIcon = self.SummaryItem_RewardIcon
    local rewrd = self.SummaryItem_Reward

    local doubleRank = self.SummaryItem_DoubleRank
    local doubleRankTen = doubleRank.SummaryItem_DoubleRank_Ten
    local doubleRankOne = doubleRank.SummaryItem_DoubleRank_One

    local result = self.SummaryItem_Result
    local vipIcon = self.SummaryItem_VipIcon
    local awaldMaxIcon = self.SummaryItem_Max
    local score = self.SummaryItem_Score

    rankBgImage:setProperty("Image", imgs.bgimage)
    itemName:setText(rankdate.playerName)

    if rankdate.playerRank > 9 then
        doubleRank:setVisible(true)
        rankImage:setVisible(false)
        doubleRankTen:setProperty("Image", imgs.tenimage)
        doubleRankOne:setProperty("Image", imgs.image)
    else
        doubleRank:setVisible(false)
        rankImage:setVisible(true)
        rankImage:setProperty("Image", imgs.image)
    end

    result:setVisible(true)
    if rankdate.isWin == 1 then
        result:setProperty("Image", "cegui_summary/SmallWin")
    elseif rankdate.isWin == 0 then
        result:setProperty("Image", "cegui_summary/SmallLose")
    else
        result:setProperty("Image", "cegui_summary/SmallDogfall")
    end

    local vipImgs = {
        "cegui_summary/VIP",
        "cegui_summary/VIPPlus",
        "cegui_summary/MVP",
    }
    local vipIconRes = vipImgs[rankdate.vip] or ""
    vipIcon:setProperty("Image", vipIconRes)
    awaldMaxIcon:setVisible(rankdate.todayGetRewarld >= rankdate.canGetReward)
    rewrd:setText(rankdate.reward)

    if rankdate.score then
        rewardIcon:setVisible(false)
        rewrd:setVisible(false)
        score:setVisible(true)
        score:setText(rankdate.score)
        self.finalsummaryRewrad:setText("final.summary.score")
    end
end

