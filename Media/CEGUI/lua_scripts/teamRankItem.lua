local leaveIcon = World.cfg.leaveIcon

function M:onOpen(rankData, showGameTimeRank, textColor)
    self:init(rankData, showGameTimeRank, textColor)
end

local function setAllTextColor(self, color)
    self:child("Team_Rank_Item_Name"):setProperty("TextColours", color)
    self:child("Team_Rank_Item_rank"):setProperty("TextColours", color)
    self:child("Team_Rank_Item_killCount"):setProperty("TextColours", color)
    self:child("Team_Rank_Item_score"):setProperty("TextColours", color)
end

local function formatTime(gameTime)
    if math.tointeger(gameTime) then
        gameTime = string.format("%.02fs", gameTime / 1000)
    end
    return gameTime
end

function M:init(rankData, showGameTimeRank, textColor)
    local teamID, rank, killCount, score = rankData.teamID, rankData.rank, rankData.killCount, rankData.score
    local name, isLeave = rankData.name, rankData.isLeave
    setAllTextColor(self, textColor)
    if teamID then--team rank
        self:child("Team_Rank_Item_Icon"):setImage(Game.GetTeamIcon(teamID), "_imagesets_")
    else--player rank
        if isLeave then
            self:child("Team_Rank_Item_LeaveIcon"):setImage(leaveIcon or "cegui_material/guanbianniu", "_imagesets_")
            self:child("Team_Rank_Item_Name"):setProperty("TextColours", "ffff0000")
        else
            self:child("Team_Rank_Item_LeaveIcon"):setImage("")
        end
        if Lib.getStringLen(name) > 10 then
            name = Lib.subString(name, 8) .. "..."
        end
        self:child("Team_Rank_Item_Name"):setText(name)
    end

    local gameTime = formatTime(rankData.score)
    self:child("Team_Rank_Item_rank"):setText(rank)
    self:child("Team_Rank_Item_killCount"):setText(not showGameTimeRank and (killCount or "") or gameTime)
    self:child("Team_Rank_Item_score"):setText(not showGameTimeRank and (score or "") or "")
end