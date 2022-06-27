
local rankTextImages = World.cfg.rankTextImages or {
    [1] = "pcGameOverConditionTex/img_1st",
    [2] = "pcGameOverConditionTex/img_2nd",
    [3] = "pcGameOverConditionTex/img_3rd",
}

local rankFrameImages = World.cfg.rankFrameImages or {
    [1] = "pcGameOverConditionTex/icon_team1st",
    [2] = "pcGameOverConditionTex/icon_team2nd",
    [3] = "pcGameOverConditionTex/icon_team3rd",
}

function self:onOpen(data)
    if not data then
        return
    end
    self.isOpen = true
    local rankNum, teamRankingText, rankImage, showNumber = data.rankNum, data.teamRankingText, data.rankImage, data.showNumber
    local showNumberImage = rankTextImages[rankNum or 0]
    local showFrameImage = rankFrameImages[rankNum or 0]
    if showNumberImage then
        self:child("TeamRankText"):setText("")
        self:child("TeamRankImage"):setImage(showNumberImage or "")
    else
        self:child("TeamRankText"):setText(Lang:toText(rankNum or ""))
        self:child("TeamRankImage"):setImage("")
    end
    self:child("TeamIconFrame"):setImage(showFrameImage or "")
    self:child("TeamIconImage"):setImage(rankImage or "")
    self:child("TeamShowTextTitle"):setText(Lang:toText(teamRankingText or ""))
    self:child("TeamShowTextDesc"):setText(Lang:toText(showNumber or ""))
end

function self:refresh(data)
    if not self.isOpen then
        return
    end
    self:onOpen(data)
end

function self:onClose()
    self.isOpen = false
end

function self:getPersonVertical()
    return self:child("PersonVertical")
end
