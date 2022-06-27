local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local rootWidth, offset, rankData
local isTeam = World.cfg.team

function M:onOpen(packet)
    rankData = packet.rankData
    self:init()
end

local function initUiSize(self)
    rootWidth = isTeam and 0.8 or 0.6
    offset = isTeam and 0.25 or 0.33
    self.ResultRank_Layout:setWidth({rootWidth, 0})
    self.Btn_Layout:setWidth({rootWidth, 0})
    self:createRankTitle()
end

function M:init()
    self.exitBtn = self:child("Exit_Btn")
    self.againBtn = self:child("Again_Btn")
    self.rankTitleLayout = self:child("ResultRank_Content_Title_Bg")
    self.ResultRank_Layout = self:child("ResultRank_Layout")
    self.Btn_Layout = self:child("Btn_Layout")
    self.ResultRank_Content_List = self:child("VerticalLayout")

    self.exitBtn.onMouseClick = function()
        if World.CurWorld.isEditorEnvironment then
            EditorModule:emitEvent("enterEditorMode")
        else
            CGame.instance:exitGame()
        end
    end
    
    self.againBtn.onMouseClick = function()
        self:close()
        if World.CurWorld.isEditorEnvironment then
            local gameRootPath = CGame.Instance():getGameRootDir()
            CGame.instance:restartGame(gameRootPath, CGame.instance:getMapName(), 1, false)
        else
            CGame.instance:getShellInterface():nextGame()
        end
    end

    initUiSize(self)
end

local function createStaticText(textIndex, textName, textSize, teamId, parentUI)
    local teamInsName = teamId and "team_" .. teamId or ""
    local rankTitleText = winMgr:createWindow("WindowsLook/StaticText", teamInsName .. "rankTitle_" .. textIndex)
    rankTitleText:setArea2({offset * (textIndex - 1), 0}, {0, 0}, {offset, 0}, {0.8, 0})
    rankTitleText:setProperty("VerticalAlignment", "Centre")
    rankTitleText:setProperty("HorzFormatting", "CentreAligned")
    rankTitleText:setProperty("VertFormatting", "CentreAligned")
    rankTitleText:setProperty("Font_size", textSize)
    rankTitleText:setProperty("Font", "DroidSans-" .. textSize)
    rankTitleText:setVisible(true)
    rankTitleText:setProperty("TextColours", "ffffffff")
    rankTitleText:setProperty("FrameEnabled", "false")
    rankTitleText:setProperty("BackgroundEnabled", "false")
    rankTitleText:setProperty("Text", Lang:toText(textName))
    rankTitleText:setProperty("MousePassThroughEnabled", true)
    parentUI:addChild(rankTitleText)
end

function M:createRankTitle()
    local titles = {"", "ID", "收集个数", "game_result_result"}

    local function loadTeamRankData()
        for _, rankDataItem in pairs(rankData) do
            for index, data in pairs(rankDataItem.players) do
                local screenData = {
                    data.playerName,
                    data.collectPropCount,
                    rankDataItem.isSuccess and "WIN" or "LOSE",
                }
                local isSelf = data.celloctID == Me.objID
                self:createRankDataItem(screenData, index, isSelf, rankDataItem.teamId)
            end
        end
    end

    local function loadSingleRankData()
        for index, data in pairs(rankData) do
            local screenData = {
                data.playerName,
                data.collectPropCount,
                data.isSuccess and "WIN" or "LOSE",
            }
            local isSelf = data.celloctID == Me.objID
            self:createRankDataItem(screenData, index, isSelf)
        end
    end

    if isTeam then
        titles[1] = isTeam and "team"
        loadTeamRankData()
    else
        table.remove(titles, 1)
        loadSingleRankData()
    end

    for index, titleName in pairs(titles) do
        createStaticText(index, titleName, 22, nil, self.rankTitleLayout)
    end

end

function M:createRankDataItem(rankData, index, isSelf, teamId)
    local bg = isSelf and "bed_summer/sort_bg_self" or "bed_summer/sort_bg_other"
    local offset = 0

    local itemLayout = winMgr:createWindow("DefaultWindow", "RankItemLayout" .. index)
    itemLayout:setArea2({0, 0}, {0, 0}, {1, 0}, {0, 45})
    itemLayout:setProperty("MousePassThroughEnabled", true)
    itemLayout:setProperty("HorizontalAlignment", "Centre")

    local itemBg = winMgr:createWindow("Engine/StaticImage", "itemBg_" .. index)
    itemBg:setArea2({0, 0}, {0, 0}, {1, 0}, {1, 0})
    itemBg:setImage(bg)
    itemBg:setProperty("MousePassThroughEnabled", true)

    if isTeam then
        local teamIconLayout = winMgr:createWindow("DefaultWindow", "teamIconLayout" .. index)
        teamIconLayout:setArea2({0, 0}, {0, 0}, {0.25, 0}, {0, 48})
        teamIconLayout:setProperty("MousePassThroughEnabled", true)
        
        local teamIcon = winMgr:createWindow("Engine/StaticImage", "teamIcon_" .. teamId)
        teamIcon:setArea2({0, 0}, {0, 0}, {0, 48}, {0, 48})
        teamIcon:setImage(Game.GetTeamIcon(teamId) .. "_me")
        teamIcon:setProperty("HorizontalAlignment", "Centre")
        teamIcon:setProperty("VerticalAlignment", "Centre")

        teamIconLayout:addChild(teamIcon)
        itemBg:addChild(teamIconLayout)
        offset = offset + 1
    end

    for key = 1 , #rankData do
        local playerName = string.format("%s", rankData[key])
        createStaticText(key + offset, playerName, 16, teamId, itemBg)
    end

    itemLayout:addChild(itemBg)
    self.ResultRank_Content_List:addChild(itemLayout)
end