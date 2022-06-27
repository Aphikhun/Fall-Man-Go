print("startup ui")
local bg = self:child("bg")
local nullWnd = self:child("nullWnd")
local infoText1 = self:child("infoText1")
local infoText2 = self:child("infoText2")
local infoText3 = self:child("infoText3")


local function initText()
    infoText1:setText(Lang:toText('UI_curMonsterSum'))
    infoText3:setText(Lang:toText('UI_NextWaveTip'))
end

function self:showOrHideWnd(isShow)
    bg:setVisible(isShow)
end

function self:refreshMonsterSum(sum)
    nullWnd:setVisible(true)
    infoText3:setVisible(false)
    infoText2:setText(sum)
end

function self:showNextWaveTip()
    nullWnd:setVisible(false)
    infoText3:setVisible(true)
end

function M:onOpen()
    initText()
end