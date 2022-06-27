
local rankTextImages = World.cfg.rankTextImages or {
    [1] = "pcGameOverConditionTex/img_1st",
    [2] = "pcGameOverConditionTex/img_2nd",
    [3] = "pcGameOverConditionTex/img_3rd",
}

function self:onOpen(data)
    if not data then
        return
    end
    self.isOpen = true
    local rankNum, notShowRankTextImage, showName, showNumber = data.rankNum, data.notShowRankTextImage, data.showName, data.showNumber
    local showNumberImage = not notShowRankTextImage and rankTextImages[rankNum or 0] or nil
    self:child("CenterText"):setText(Lang:toText(showName))
    if showNumberImage then
        self:child("LeftText"):setText("")
        self:child("LeftImage"):setImage(showNumberImage or "")
    else
        self:child("LeftText"):setText(Lang:toText(rankNum or ""))
        self:child("LeftImage"):setImage("")
    end
    self:child("RightText"):setText(Lang:toText(showNumber or ""))
    self:child("FrameImage"):setVisible(data.isMe or false)
    self:child("Center"):setXPosition(data.isTeam and {0.4, 0} or {0.25, 0})
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