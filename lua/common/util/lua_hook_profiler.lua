---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wangpq.
--- DateTime: 2020/8/18 17:41
---
local misc = require("misc")

---@class LuaHookProfiler
local LuaHookProfiler = T(Lib, "LuaHookProfiler")

local result = {}

local start_time = 0

-- get the function title
local function _func_title(funcinfo)

    -- check
    assert(funcinfo)

    -- the function name
    local name = funcinfo.name or 'anonymous'

    -- the function line
    local line = string.format("%d", funcinfo.linedefined or 0)

    -- the function source
    local source = funcinfo.short_src or 'C_FUNC'
    --[[if os.isfile(source) then
        source = path.relative(source, xmake._PROGRAM_DIR)
    end]]--

    -- make title
    return string.format("[%-30s: %s: %s]", name, source, line)
end

local function formatTime(time)
    return string.format("%0.2f", time * 0.001)
end

function LuaHookProfiler.start()
    collectgarbage("collect")
    collectgarbage("collect")
    collectgarbage("stop")

    start_time = misc.now_microseconds()

    debug.sethook(function(event)
        local info = debug.getinfo(2)
        info.name = _func_title(info)

        result[info.name] = result[info.name] or {
            name = info.name,
            min_time = 999999,
            max_time = 0,
            total_time = 0,
            call_count = 0,
        }

        if event == "call" then
            result[info.name].call_time = misc.now_microseconds()
        elseif event == "return" then
            if not result[info.name].call_time then
                return
            end

            local cost_time = (misc.now_microseconds() - result[info.name].call_time) --us
            result[info.name].min_time = math.min(cost_time, result[info.name].min_time)
            result[info.name].max_time = math.max(cost_time, result[info.name].max_time)
            result[info.name].avg_time = result[info.name].avg_time and ((cost_time + result[info.name].avg_time) * 0.5) or cost_time
            result[info.name].total_time = result[info.name].total_time + cost_time
            result[info.name].call_count = result[info.name].call_count + 1
        end
        --print(Lib.inspect(info), event)
    end, "cr")
end

function LuaHookProfiler.stop()
    debug.sethook()
    result = {}
    collectgarbage("restart")
    collectgarbage("collect")
    collectgarbage("collect")
end

function LuaHookProfiler.dump(dump_count)
    dump_count = dump_count or 20

    local cost_time = misc.now_microseconds() - start_time

    print("name", "total_time(ms)", "min_time(ms)", "max_time(ms)", "avg_time(ms)", "percent", "call_count")
    local i = 1
    for _, info in Lib.pairsByValues(result, function(a, b)
        return a.total_time > b.total_time
    end) do
        if info.total_time and info.min_time and info.max_time and info.avg_time then
            print(string.format("%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5d", info.name, formatTime(info.total_time),
                    formatTime(info.min_time), formatTime(info.max_time), formatTime(info.avg_time),
                    string.format("%0.2f%%", (info.total_time / cost_time) * 100), info.call_count))
        end
        if i >= dump_count then
            break
        end
        i = i + 1
    end
end

return LuaHookProfiler