
local personRankBg = "pcGameOverConditionTex/bg_person"

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

-- 注：新UI还不能显示头像

local function createPersonWidget(weightName, info)
    return UI:openWindow("gameOverRankPersonItem", weightName, "_layouts_", info)
end

local function showPlayerModelRank(fatherWeight, data, notShowRankTextImage, isTeam)
    for i, info in ipairs(data) do
        fatherWeight:addChild(createPersonWidget("gameOverRankPersonItem"..i, {isMe = info.obj.objID == Me.objID, isTeam = isTeam, notShowRankTextImage = notShowRankTextImage, rankNum = i, showName = info.obj.name, showNumber = info.number}):getWindow())
    end
end

local function createTeamWidget(weightName, info)
    return UI:openWindow("gameOverRankTeamItem", weightName, "_layouts_", info)
end

local function showTeamModelRank(fatherWeight, teamRankingText, data)
    for i, info in pairs(data) do
        local teamWtightInstance = createTeamWidget("gameOverRankTeamItem"..i, {teamRankingText = teamRankingText, rankNum = i, rankImage = Game.GetTeamImage(info.teamId) or "", showNumber = info.number})
        showPlayerModelRank(teamWtightInstance:getPersonVertical(), info.users, true, true)
        fatherWeight:addChild(teamWtightInstance:getWindow())
    end
end

--[[
data =  {
  ["settlementType"] = "player",
  ["data"] = {
    [1] = {
      ["obj"] = ...,
      ["number"] = xx,
      ["userId"] = xx
    },
    [2] ...
  },
  ["rankingText"] = "xx"
}
or
data =  {
  ["settlementType"] = "team",
  ["data"] = {
    [1] = {
      ["teamId"] = ...,
      ["number"] = xx,
      ["users"] = {
        [1] = {
            ["obj"] = ...,
            ["number"] = xx,
            ["userId"] = xx
        },
        [2] ...
      }
    },
    [2] ...
  },
  ["rankingText"] = "xx"
}
 or
 xx
]]

function self:onOpen(data)
    if not data then
        return
    end
    self.isOpen = true
    self:setVisible(true)	

    print(Lib.v2s(data, (data.settlementType == "player") and 3 or 5), "aaaaaaaaaaaaaaaaaaaaa")

    local RankBaseVertical = self:child("RankBaseVertical")
    RankBaseVertical:cleanupChildren()
    if data.settlementType == "player" or data.settlementType == "all" then
        showPlayerModelRank(RankBaseVertical, data.data)
        self:child("RankBaseImage"):setImage(personRankBg)
        self:child("RankTitle3"):setText("")
        self:child("RankTitle3"):setXPosition({0.5, 0})
        self:child("RankTitle2"):setText(Lang:toText("pc.gameover.condition.player"))
        self:child("RankTitle2"):setXPosition({0.25, 0})
        self:child("RankTitle1"):setText(Lang:toText("pc.gameover.condition.ranking"))
    elseif data.settlementType == "team" then
        showTeamModelRank(RankBaseVertical, data.teamRankingText, data.data)
        self:child("RankBaseImage"):setImage("")
        self:child("RankTitle3"):setText(Lang:toText("pc.gameover.condition.player"))
        self:child("RankTitle3"):setXPosition({0.45, 0})
        self:child("RankTitle2"):setText(Lang:toText("pc.gameover.condition.person.ranking"))
        self:child("RankTitle2"):setXPosition({0.2, 0})
        self:child("RankTitle1"):setText("")
    end
    self:child("RankTitle4"):setText(Lang:toText(data.rankingText or ""))
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