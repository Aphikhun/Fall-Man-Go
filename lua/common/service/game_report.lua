---
--- 游戏数据上报服务
--- 提供给外部开发者使用的数据上报的相关接口
--- DateTime: 2022/1/6 18:18
---

local GameReport = {}
local EVENT_NAME = "ugc_user_custom_event"
local TIMES_LIMIT = 60 -- 用户上报埋点的每分钟次数限制

local _user_record = {} -- 用户上报情况记录 userId = { time=0, times=0 }
local _log_record = {}  -- log记录，防止输出频率过高，频率与埋点频率一致

local function checkReportData(value)
    local typ = type(value)
    if typ == "nil" or typ == "table" or typ == "userdata" or typ == "function" or typ == "thread" then
        return false
    end
    return true
end

-- 检查用户次数限制是否达到上限
local function checkTimesLimit(userId)
    local record = _user_record[userId]
    if not record then
        return false
    end
    local now = World.Now()
    if record.time < now then
        return false
    end
    if record.times < TIMES_LIMIT then
        return false
    end
    return true
end

local minute2tick = 60 * 20 -- 一分钟的帧数
-- 记录用户上次次数
local function recordReportTimes(userId)
    local record = _user_record[userId]
    local now = World.Now()
    if not record then
        record = { time = now + minute2tick, times = 0 }
        _user_record[userId] = record
    end
    if record.time < now then
        record.time = now + minute2tick
        record.times = 0
        _log_record[userId] = false
    end
    record.times = record.times + 1
end

function GameReport:reportGameData(event, data, player)
    if not player or not player:isValid() or not player.isPlayer then
        if World.isClient then
            player = Me
        else
            Lib.log("The player reported by the game data does not exist", 3)
            return
        end
    end
    local userId = player.platformUserId
    if not userId and World.isClient then
        userId = CGame.instance:getPlatformUserId()
    end
    if checkTimesLimit(userId) then
        if not _log_record[userId] then
            Lib.log("The number of times the user has reported data has reached the upper limit ! " .. userId, 3)
            _log_record[userId] = true
        end
        return
    end
    if not checkReportData(event) or not checkReportData(data) then
        Lib.log("The type of reported event/data cannot be these types : nil, table, userdata, function, thread", 3)
        return
    end
    local eventMap = {
        event_name = tostring(event),
        ugc_user_custom_event_params = tostring(data)
    }

    if World.isClient then
        GameAnalytics.NewDesign(EVENT_NAME, eventMap)
    else
        GameAnalytics.NewDesign(userId, EVENT_NAME, eventMap)
    end

    recordReportTimes(userId)
end
GameReport.ReportData = GameReport.reportGameData

local engine_module = require "common.engine_module"
engine_module.insertModule("GameAnalytics", GameReport)

RETURN(GameReport)