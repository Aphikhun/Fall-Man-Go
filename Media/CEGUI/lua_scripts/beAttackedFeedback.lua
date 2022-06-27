local beAttackedFeedback = {
    fromNpc = true,
    fromPlayer = true,
    hideSmooth = true,
    hideTime = 15
}

function M:onOpen()
    self:init()
end

function M:init()
    self.fb_image = self:child("BeAttackFeedback_Image")
    self.alphaTimer = false
end

local function hideFeedbackImage(self, cfg)
    if self.alphaTimer then
        self.alphaTimer()
    end
    local totalTime = cfg.hideTime
    self.timeLeft = totalTime
    self.alphaTimer = World.Timer(1, function()
        self.timeLeft = self.timeLeft - 1
        if self.timeLeft > 0 then
            if cfg.hideSmooth ~= false then
                self.fb_image:setAlpha(self.timeLeft/totalTime)
            end
            return true
        else
            self.fb_image:setAlpha(0)
            self.fb_image:setVisible(false)
            self.close()
            return false
        end
    end)
end

function M:updateAttackerDirection(packet)
    local from = World.CurWorld:getEntity(packet.fromId)
    if not from then
        return
    end
    local cfg = Me:cfg().beAttackedFeedback or beAttackedFeedback
    if cfg.fromPlayer == false and from:isControl() then
        return
    end
    if cfg.fromNpc == false and not from:isControl() then
        return
    end
    self.fb_image:setImage(cfg.image or "attack_effect/hurt")
    self.fb_image:setVisible(true)
    self.fb_image:setAlpha(1)
    hideFeedbackImage(self, cfg)
end

return M