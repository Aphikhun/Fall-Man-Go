local RankBg = self:child('RankBg')
local BestTime = self:child('BestTime')
local CloseButton = self:child('CloseButton')
local TimeText = self:child('TimeText')
local NameText = self:child('NameText')
local RankButton = self:child('RankButton')
local CountdownText = self:child('CountdownText')
local CountdownBG = self:child('CountdownBG')
local InfoLayout = self:child('InfoLayout')
local RankText = self:child('RankText')
local Logo = self:child('Logo')
local tempRank = RankBg:child('Rank'):clone()

--zero-fill the single-digit time unit
local function zeroFill(timeInfo)
  for index, v in pairs(timeInfo) do
    timeInfo[index] = v > 9 and v or ("0" .. v)
  end
end

--Remove illegal characters from names
local function cullIllegalChar(name)
  local tempName = ''
  local array = Lib.splitString(name, "#")
  for _, line in pairs(array) do
    local arr = Lib.splitString(line, ":")
    for _, word in pairs(arr) do
      tempName = tempName .. word
    end
  end
  return tempName
end

--convert time to characters
local function conversionTime(time)
  if not time or tonumber(time) == -1 then
    return
  end
  local timeInfo = {}
  timeInfo.minute = math.floor(time / 1200)
  timeInfo.second = math.floor(time / 20) % 60
  timeInfo.millisecond = (time % 20) * 5
  zeroFill(timeInfo)
  return timeInfo.minute .. ":" .. timeInfo.second .. ":" .. timeInfo.millisecond
end

local function initText()
  TimeText:setText(Lang:toText('UI_Text_Time'))
  NameText:setText(Lang:toText('UI_Text_Name'))
  RankText:setText(Lang:toText('UI_Text_Ranking'))
  Logo.Text:setText(Lang:toText('UI_Text_Rank_Upper'))
  CloseButton.Text:setText(Lang:toText('UI_Button_Close'))
  RankButton.Text:setText(Lang:toText('UI_Button_Rank'))
end

--Refresh leaderboard display
function self:refreshRankInfo(data)
  RankBg:setVisible(true)
  InfoLayout:cleanupChildren()
  for i = 1, 10 do
    local rankData = data[i] or {}
    local newRank = tempRank:clone()

    newRank.Index:setText(i)
    newRank.Name:setText(rankData.name or '---')
    newRank.Time:setText(conversionTime(rankData.time) or '---')

    --Current player information highlighted
    if rankData.name == cullIllegalChar(Me.name) then
      newRank.Bg:setVisible(true)
      newRank.Name:setTextColours(Color3.new(0, 1, 1))
      newRank.Time:setTextColours(Color3.new(0, 1, 1))
    end

    if i <= 3 then
      newRank.LogoBg:setVisible(true)
      newRank.LogoBg:setImage(string.format("gameres|asset/file/ui/%s.png",i))
      newRank.Index:setText('')
    end
    InfoLayout:addChild(newRank)
  end
  local myBestTime = conversionTime(Me:getValue('time'))
  BestTime:setText(Lang:toText('UI_Text_BestTime') .. ' : ' .. (myBestTime or ''))
end

RankButton.onMouseClick = function()
  RankButton:setVisible(false)
  PackageHandlers.sendClientHandler("requireRankData", {})
end
CloseButton.onMouseClick = function()
  RankButton:setVisible(true)
  RankBg:setVisible(false)

end

function self:refreshTimer(timeInfo)
  CountdownBG:setVisible(true)
  zeroFill(timeInfo)
  CountdownText:setText(timeInfo.minute .. ":" .. timeInfo.second .. ":" .. timeInfo.millisecond)
end

function self:onOpen()
  initText()
end