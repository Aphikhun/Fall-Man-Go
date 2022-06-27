
local gameoverImages = {
    gameover = "pcGameOverConditionTex/tanchuang_gameover",
    victory = "pcGameOverConditionTex/tanchuang_victory",
    lose = "pcGameOverConditionTex/tanchuang_lose",
}

function self:init()
    self:child("LeftBtnText"):setText(Lang:toText("pc.gameover.condition.replay"))
    self:child("LeftBtn").onMouseClick = function()
        CGame.instance:exitGame()
    end
    self:child("RightBtnText"):setText(Lang:toText("pc.gameover.condition.exit"))
    self:child("RightBtn").onMouseClick = function()
        CGame.instance:getShellInterface():nextGame()
    end
end

function self:onOpen(packet)
    if not packet then
        packet = {}
    end
    self.isOpen = true
    local showType = packet.showType or "gameover"
    self:child("BaseImage"):setImage(gameoverImages[showType] or gameoverImages.gameover)
    self:child("TitleText"):setText(Lang:toText(packet.showTitle or "pc.gameover.condition.gameover"))
    local showMsg = packet.showMsg
    self:child("ShowText"):setText(Lang:toText(showMsg and {showMsg.langKey, showMsg.value} or "pc.gameover.condition.showText"))
    self:setVisible(true)	
end

function self:refresh(packet)
    if not self.isOpen then
        return
    end
    self:onOpen(packet)
end

function self:onClose()
    self.isOpen = false
    self:setVisible(false)
end

self:init()