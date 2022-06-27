local DBHandler = require "dbhandler"

local rankData = {}
rankData.subKey = 2
rankData.gameName = World.GameName
rankData.rankName = 3

--Convert character data to table
local function deCode(data, func)
    local data1 = {}
    local array = Lib.splitString(data, "#")  --name:time:timeindex#name:time:timeIndex
    for _, line in pairs(array) do
        local arr = Lib.splitString(line, ":")  --name:time:timeIndex
        local info = { name = arr[1], time = tonumber(arr[2]), timeIndex = tonumber(arr[3]) }
        table.insert(data1, info)
    end
    func(data1)
end

--Convert table to character data
local function enCode(data)
    local str = ''
    for i, info in ipairs(data) do
        local char = i == 1 and '' or '#'
        str = str .. char .. string.format("%s:%s:%s", info.name, info.time, info.timeIndex)
    end
    return str
end

--Determine if a player is in the leaderboard
local function hasName(data, name)
    for i, info in ipairs(data) do
        if info.name == name then
            return i
        end
    end
end

--Get leaderboard data
function rankData:getRankList(func)
    DBHandler:getDataByUserId(self.rankName, self.subKey, function(userId, data)
        deCode(data, func)
    end, function(data)
        func({})
    end)
end

--Add leaderboard data
function rankData:addData(name, time, timeIndex)
    self:getRankList(function(data)
        local index = hasName(data, name)
        if index then
            data[index].time = time
            data[index].timeIndex = timeIndex
        else
            table.insert(data, { name = name, time = time, timeIndex = timeIndex })
        end
        table.sort(data, function(data1, data2)
            -- Ascending by time
            -- If time is equal, in ascending order by timeIndex
            if data1.time < data2.time or data1.timeIndex == data2.timeIndex and data1.timeIndex < data2.timeIndex then
                return true
            end
        end)

        --Only record the first 10 data
        if #data == 11 then
            table.remove(data, 11)
        end
        local str = enCode(data)
        DBHandler:setData(self.rankName, self.subKey, str, true)
    end)
end

return rankData


