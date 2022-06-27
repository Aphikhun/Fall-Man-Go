print("startup ui")

local PB_captureFlag = self:child('PB_captureFlag')
local Txt_timer = self:child('Txt_timer')
local Txt_tip = self:child('Txt_tip')
local Txt_redScore = self:child('Txt_redScore')
local Txt_blueScore = self:child('Txt_blueScore')
local Btn_sevenLogin = self:child('Btn_sevenLogin')
local Img_redDot = self:child('Img_redDot')
local DW_left = self:child('DW_left')
local DW_info = self:child('DW_info'):clone()

local layerLangKey = {
    'langKey_down',
    'langKey_mid',
    'langKey_up'
}

local function zeroFill(timeInfo)
    for index, v in pairs(timeInfo or {}) do
        timeInfo[index] = v > 9 and v or ("0" .. v)
    end
end


function self:refreshCaptureFlagProcess(totalTime, curTime)
    PB_captureFlag:setVisible(true)
    local progress = curTime / totalTime
    PB_captureFlag:setProperty("CurrentProgress", progress)
end

function self:closeCaptureFlagProcess()
    PB_captureFlag:setVisible(false)
end

--txt is table
function self:setTipText(txt)
    Txt_tip:setText(Lang:toText(txt))
end

function self:setFlagSumTip(langKey,sum)
    local txt = Lang:toText({ langKey, sum })
    Txt_tip:setText(txt)
end

function self:setTime(timeInfo)
    zeroFill(timeInfo)
    Txt_timer:setText(timeInfo and timeInfo.minute .. ":" .. timeInfo.second)
end

function self:setTeamScore(redScore, blueScore)
    Txt_redScore:setText(redScore)
    Txt_blueScore:setText(blueScore)
end

function self:initTeamInfo()
    self:setTeamScore(0, 0)
    self:setFlagSumTip(0)
    self:setTipText('langKey_Waiting_player_enter')
end

function self:showSevenLoginRedDot()
    Img_redDot:setVisible(true)
end

function self:hideSevenLoginRedDot()
    Img_redDot:setVisible(false)
end

Btn_sevenLogin.onMouseClick = function()
    PackageHandlers.sendClientHandler("getSevenLoginData")
end

function self:onOpen()
    DW_left:cleanupChildren()
end

local infoWndList = {}
local infoLayoutInterval = 3
local infoHeight = 50

local infoWndMaxSum = 3
local intervalTime = 5    --移动时间（帧）

local totalLiveTime = 8  --消息存在总时间
local normalShowTime = 2  --正常显示时间
local function posTween(wnd, posY, func)
    local detailPosY = -(infoHeight + infoLayoutInterval) / intervalTime
    local rate = 1
    local minPosY = posY
    local useless = wnd.posTweenTimer and wnd.posTweenTimer()
    wnd.posTweenTimer = World.Timer(1,function()

        if not wnd:isAlive() then
            return
        end

        local pos = wnd:getYPosition()
        pos[2] = pos[2] + (detailPosY * rate)
        pos[2] = math.max(minPosY, pos[2])

        if pos[2] < minPosY then
            rate = 0.8
        end

        if minPosY == pos[2] then
            wnd:setYPosition(pos)
            func()
            return false
        else
            wnd:setYPosition(pos)
            return true
        end
    end)
end

local function removeInfoWnd(wnd)
    if wnd:isAlive() then
        DW_left:removeChild(wnd)
        wnd:close()
        table.remove(infoWndList, 1)
    end
end

local function alphaTween(wnd)
    local time = (totalLiveTime - normalShowTime) * 20
    local rate = 1
    local intervalAlpha = 1 / time
    World.Timer(1,function()

        if not wnd:isAlive() then
            return
        end

        local alpha = tonumber(wnd:getProperty('Alpha'))
        alpha = alpha - (intervalAlpha * rate)

        alpha = math.max(0, alpha)
        if alpha < 0.7 then
            --rate = 0.7
        end

        if alpha == 0 then
            wnd:setProperty('Alpha', tostring(alpha))
            removeInfoWnd(wnd)
            return
        else
            wnd:setProperty('Alpha', tostring(alpha))
            return true
        end
    end)
end

function self:addInfoWnd(langKey,index)
    local teamWnd = DW_info:clone()
    table.insert(infoWndList, teamWnd)
    DW_left:addChild(teamWnd)

    local txt = Lang:toText({langKey,layerLangKey[index]})

    teamWnd:child('Txt_width'):setText(txt)

    local width = teamWnd:child('Txt_width'):getWidth()
    teamWnd:child('Txt_width'):setText('')
    teamWnd:child('Txt_width'):setWidth(width)
    teamWnd:child('Txt_info'):setText(txt)

    local curSum = #infoWndList
    if curSum == infoWndMaxSum + 1 then
        removeInfoWnd(infoWndList[1])
        curSum = infoWndMaxSum
    end

    teamWnd:setVisible(false)
    for i, infoWnd in ipairs(infoWndList) do
        if i ~= curSum then
            local posY = -(curSum - i) * (infoHeight + infoLayoutInterval)
            posTween(infoWnd, posY, function()
                if teamWnd:isAlive() then
                    teamWnd:setVisible(true)
                end
            end)
        end
    end
    if curSum == 1 then
        teamWnd:setVisible(true)
    end

    World.Timer(normalShowTime * 20, function()
        alphaTween(teamWnd)
    end)
end

function self:clearAllInfoWnd()
    DW_left:cleanupChildren()
    infoWndList = {}
end

self:initTeamInfo()

