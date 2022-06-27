print("startup ui")

local Txt_rankTip = self:child('Txt_rankTip')
local Txt_nameTip = self:child('Txt_nameTip')
local Txt_captureFlagTimeTip = self:child('Txt_captureFlagTimeTip')
local Txt_flagSumTip = self:child('Txt_flagSumTip')
local Btn_exitGame = self:child('Btn_exitGame')
local Btn_replay = self:child('Btn_replay')
local V_rankListLayout = self:child('V_rankListLayout')
local Img_titel = self:child('Img_titel')
local Wnd_info = V_rankListLayout:child('Wnd_info'):clone()
local rankIconPath = "gameres|asset/Texture/icon/Rank/%s.png"

local function initText()
    Txt_rankTip:setText(Lang:toText({ 'langKey_UI_rankTip' }))
    Txt_nameTip:setText(Lang:toText({ 'langKey_UI_nameTip' }))
    Txt_captureFlagTimeTip:setText(Lang:toText({ 'langKey_UI_captureFlagTimeTip' }))
    Txt_flagSumTip:setText(Lang:toText({ 'langKey_UI_flagSumTip' }))
    Btn_exitGame.Text:setText(Lang:toText({ 'langKey_UI_exitGame' }))
    Btn_replay.Text:setText(Lang:toText({ 'langKey_UI_rePlay' }))
end

function self:setRankData(packet)
    local rankList = packet.rankData
    V_rankListLayout:cleanupChildren()
    for i, info in ipairs(rankList) do
        local teamInfo = Wnd_info:clone()
        V_rankListLayout:addChild(teamInfo)
        teamInfo:child('Txt_rank'):setText(i)
        teamInfo:child('Txt_name'):setText(info.name)
        teamInfo:child('Txt_captureFlagTime'):setText(info.handFlagTime)
        teamInfo:child('Txt_flagSum'):setText(info.captureFlagSum)
        if info.name == Me.name then
            teamInfo:child('Img_bg'):setVisible(true)
            teamInfo:child('Txt_name'):setTextColours(Color3.new(0, 1, 1))
            teamInfo:child('Txt_rank'):setTextColours(Color3.new(0, 1, 1))
            teamInfo:child('Txt_captureFlagTime'):setTextColours(Color3.new(0, 1, 1))
            teamInfo:child('Txt_flagSum'):setTextColours(Color3.new(0, 1, 1))
        end

        if i <= 3 then
            local Img_rankBG = teamInfo:child('Img_rankBG')
            Img_rankBG:setVisible(true)
            Img_rankBG:setImage(string.format(rankIconPath,i))
            teamInfo:child('Txt_rank'):setText('')
        end
    end
    if packet.isVictory then
        Img_titel:setImage(string.format(rankIconPath,'title_win'))
        Img_titel:child('Img_result'):setImage(string.format(rankIconPath,'icon_win'))
    end
end

Btn_exitGame.onMouseClick = function()
    CGame.instance:exitGame()
end

Btn_replay.onMouseClick = function()
    PackageHandlers.sendClientHandler("playerEnter", {}, function()
        Lib.emitEvent("INIT_TEAM_INFO")
        UI:closeWindow('rankListWnd')
    end)
end

function self:onOpen()
    initText()
end