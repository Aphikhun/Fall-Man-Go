local giftDataTb = {
    { itemPath = 'myplugin/apple', sum = 1 },
    { itemPath = 'myplugin/apple', sum = 2 },
    { itemPath = 'myplugin/apple', sum = 3 },
    { itemPath = 'myplugin/apple', sum = 4 },
    { itemPath = 'myplugin/apple', sum = 5 },
    { itemPath = 'myplugin/apple', sum = 6 },
    { itemPath = 'myplugin/apple', sum = 7 },
}

local function judgeCanGetGift(dateData)
    local time1 = tonumber(dateData.lastDay)
    local time2 = tonumber(Lib.getYearDayStr(os.time()))
    return time1 == time2                                --Incity means that no reward has been received today
end

local function judgeCanUpdateWeekData(dateData, player)
    local time1 = tonumber(dateData.curtWeek)
    local time2 = tonumber(Lib.getYearWeekStr(os.time()))
    if time1 ~= time2 then                              --The incupities indicate that the date data is reset for different weeks
        dateData.curtWeek = time2                       --The number of update weeks
        dateData.totalLoginCount = 0                    --Reset the number of login days
        player:setValue('DateData', dateData)            --Update data
    end
end

local function UpdateDateData(dateData, player)
    dateData.totalLoginCount = dateData.totalLoginCount + 1  --The cumulative number of login days plus one
    dateData.lastDay = Lib.getYearDayStr(os.time())          --Record today's date
    player:setValue('DateData', dateData)                    --Save the data
end

--Get player data, update the seven-day login interface
PackageHandlers.registerServerHandler("getSevenLoginData", function(player, packet)
    local dateData = player:getValue("DateData")
    PackageHandlers.sendServerHandler(player, 'UI_openSevenLoginWnd', { index = dateData.totalLoginCount, haveGot = judgeCanGetGift(dateData) })
end)

--Give out rewards
PackageHandlers.registerServerHandler("giveLoginGift", function(player, packet)
    local dateData = player:getValue("DateData")

    local totalLoginCount = tonumber(dateData.totalLoginCount) + 1
    local curDayGift = giftDataTb[totalLoginCount]
    player:addItem(curDayGift.itemPath, curDayGift.sum, nil, "enter")
    UpdateDateData(dateData, player)
end)

local function checkDateData(player)
    local dateData = player:getValue("DateData")
    if not judgeCanGetGift(dateData) then
        judgeCanUpdateWeekData(dateData, player)                              -- Check to see if it is the same week
        PackageHandlers.sendServerHandler(player, 'showSevenLoginRedDot')     -- Turn on the red dot prompt
    end
end

Lib.subscribeEvent("PLAYER_ENTER", checkDateData)

--When the computing server is turned on, the deadline of today is used to refresh the seven-day login prompt
local hour = tonumber(os.date("%H"))
local minute = tonumber(os.date("%M"))
local second = tonumber(os.date("%S"))

local dayEndTime = (24 - hour - 1) * 60 * 60 * 20 + (60 - minute - 1) * 60 * 20 + (60 - second) * 20

World.Timer(dayEndTime, function()
    for i, player in pairs(Game.GetAllPlayers()) do
        checkDateData(player)
    end
    return 24 * 60 * 60 * 20
end)
