print("startup ui")

--Reward data table
local giftDataTb = {
    { iconPath = 'gameres|asset/apple.png', sum = 1 },
    { iconPath = 'gameres|asset/apple.png', sum = 2 },
    { iconPath = 'gameres|asset/apple.png', sum = 3 },
    { iconPath = 'gameres|asset/apple.png', sum = 4 },
    { iconPath = 'gameres|asset/apple.png', sum = 5 },
    { iconPath = 'gameres|asset/apple.png', sum = 6 },
    { iconPath = 'gameres|asset/apple.png', sum = 7 },
}

local Btn_signIn = self:child('Btn_signIn')
local Btn_close = self:child('Btn_close')

function self:initText()
    local teamDayData
    local teamGiftData

    self:child('Txt_describe'):setText(Lang:toText('LangKey_UI_loginDescribe'))
    self:child('Img_bg_title').Text:setText(Lang:toText('LangKey_UI_bgTitle'))
    Btn_signIn:child('Text'):setText(Lang:toText('LangKey_UI_signInTxt'))
    for i = 1, 7 do
        teamDayData = self:child('Wnd_dayData' .. i)
        teamGiftData = giftDataTb[i]
        teamDayData:child('Img_icon'):setImage(teamGiftData.iconPath)
        teamDayData:child('Txt_sum'):setText('X' .. teamGiftData.sum)
    end
end

self:initText()

function self:updateDayData(index, haveGot)
    local teamDayData
    local count = index
    for i = 1, count do
        teamDayData = self:child('Wnd_dayData' .. i)
        teamDayData:child('Img_haveGotIcon'):setVisible(true)     --Less than login days to open the received icon
    end
    if not haveGot then
        teamDayData = self:child('Wnd_dayData' .. count + 1)      --The number of login days plus one is the reward for this login
        teamDayData:child('Img_selectIcon'):setVisible(true)
    end
    Btn_signIn:setProperty('Disabled', tostring(haveGot))

    Btn_signIn.onMouseClick = function()
        PackageHandlers.sendClientHandler("giveLoginGift", {}, function()
            Lib.emitEvent("HIDE_SEVEN_LOGIN_RED_DOT")
            teamDayData:child('Img_haveGotIcon'):setVisible(true)
            teamDayData:child('Img_selectIcon'):setVisible(false)
            Btn_signIn:setProperty('Disabled', 'true')
        end)
    end
end

Btn_close.onMouseClick = function()
    print(debug.traceback())
   UI:closeWindow('sevenLoginWnd')
end
