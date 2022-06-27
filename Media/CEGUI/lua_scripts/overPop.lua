function M:onOpen(packet)
    self:init()
    self.regKey = packet.regKey
    self.regId = packet.regId
    self:updateUI(packet.type, packet.bedBreak)
end

local function exitGame()
    if World.CurWorld.isEditorEnvironment then
        EditorModule:emitEvent("enterEditorMode")
    else
        CGame.instance:exitGame()
    end
end

function M:init()
    self.topImg = self:child("OverPop_Top_Img")
    self.downTip = self:child("OverPop_Content1")
    self.reviveCountTip = self:child("OverPop_Content2")
    self.leftBtn = self:child("OverPop_LeftBtn")
    self.rightBtn = self:child("OverPop_RightBtn")
    self.centerBtn = self:child("OverPop_CenterBtn")
    self.leftBtn:setText(Lang:toText("exit_game"))
    self.rightBtn:setText(Lang:toText("revive_right_now"))
    self.centerBtn:setText(Lang:toText("exit_game"))

    self.leftBtn.onMouseClick = function()
        exitGame()
    end

    self.rightBtn.onMouseClick = function()
        self:doCallBack("yes")
    end

    self.centerBtn.onMouseClick = function()
        exitGame()
    end
end

function M:doCallBack(key)
    Me:doCallBack(self.regKey, key, self.regId)
    self.close()
end

function M:updateUI(type, bedBreak)
    if type == "time_over" then
        self.topImg:setImage("over_pop/game_over")
        self.topImg:setArea2({0, 0}, {0, -30}, {0, 276}, {0, 109})
        self.downTip:setYPosition({0, -10})
        self.downTip:setText(Lang:toText("game_time_out"))
        self.reviveCountTip:setText("")
    elseif type == "can_revive" then
        self.topImg:setImage("over_pop/title_die1")
        self.topImg:setArea2({0, 0}, {0, -75}, {0, 241}, {0, 196})
        self.downTip:setYPosition({0, -10})
        self.downTip:setText(Lang:toText("player_die_tip"))
        self.reviveCountTip:setText("")
    else
        self.topImg:setImage("over_pop/title_die")
        self.topImg:setArea2({0, 0}, {0, -75}, {0, 276}, {0, 167})
        self.downTip:setYPosition({0, -40})
        self.downTip:setText(Lang:toText("player_die_tip"))
        self.reviveCountTip:setText(Lang:toText(bedBreak and "bed_or_egg_break" or "player_die_over"))
    end
    self.leftBtn:setVisible(type == "can_revive")
    self.rightBtn:setVisible(type == "can_revive")
    self.centerBtn:setVisible(type ~= "can_revive")
end