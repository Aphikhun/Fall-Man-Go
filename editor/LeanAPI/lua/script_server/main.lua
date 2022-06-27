print('script_server:hello world')
require "script_server.calcTime"
local rankData = require "script_server.rankData"

local function partFalsh(part)
    part.isFlash = true
    local intervalTime = 10
    local interval = 1 / -intervalTime

    World.Timer(1, function()
        if part:isValid() then
            local alpha = part:getProperty("materialAlpha")
            alpha = alpha + interval
            if alpha >= 1 then
                part:setProperty("materialAlpha", 1)
                part:setProperty("useCollide", "true")
                part.isFlash = false
                return

            elseif alpha <= 0 then
                part:setProperty("materialAlpha", 0)
                interval = 1 / 30
                part:setProperty("useCollide", "false")
                return true
            end

            part:setProperty("materialAlpha", alpha)
            return true
        end
    end)

end

--Remove illegal characters from names
local function cullIllegalChar(name)
    local tempName = ''
    local array = Lib.splitString(name, "#")
    for _, line in pairs(array) do
        local arr = Lib.splitString(line, ":")
        for _, word in pairs(arr) do
            tempName = tempName..word
        end
    end
    return tempName
end

local touchFunc = {}
--Part function that fades after touch
function touchFunc.jump(part)
    if not part.isFlash then
        partFalsh(part)
    end
end

--Touch the start part to trigger the function
function touchFunc.starttime(part, player)
    local startTime = player:data('StartTime')

    if not (type(startTime) == 'number') then
        player:setData('StartTime', World.Now())
    end
end

--Touch the end part to trigger the function
function touchFunc.destination(part, player)
    local startTime = player:data('StartTime')
    if (type(startTime) == 'number') then
        local time = World.Now() - startTime
        local oldTime = player:getValue('time')
        if oldTime < 0 or (oldTime > 0 and time < oldTime) then
            player:setValue('time', time)
            local name = cullIllegalChar(player.name)
            if name == '' then
                player:sendTip(1, "Txt_illegal_name", 120)
            else
                rankData:addData(name, time, os.time())
            end
        end
        player:setData('StartTime', nil)
    end
end

local cfg = Entity.GetCfg("myplugin/player1")

--touch event with part
Trigger.addHandler(cfg, "ENTITY_TOUCH_PART_BEGIN", function(context)
    local player = context.obj1
    local part = context.part
    local partName = part.name
    --Trigger different functions based on part name
    if touchFunc[partName] then
        touchFunc[partName](part, player)
    end
end)


PackageHandlers.registerServerHandler("requireRankData", function(player, packet)
    rankData:getRankList(function(data)
        if player and player:isValid() then
            PackageHandlers.sendServerHandler(player, 'ShowRankUI', data)
        end
    end)

end)


