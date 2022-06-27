local entityCtrl = {}
local cfg = Entity.GetCfg('myplugin/player1')

local blueSkinData = {
    clothes = 'armor_chest_blue',
    shoes = 'armor_foot_blue',
    hair = 'armor_head_blue',
    pants = 'armor_thigh_blue'
}

local redSkinData = {
    clothes = 'armor_chest_red',
    shoes = 'armor_foot_red',
    hair = 'armor_head_red',
    pants = 'armor_thigh_red'
}

function entityCtrl:addDebuff(player)
    player:setProp('moveSpeed', player:data('moveSpeed') * 0.7)
    local isRed = player:getTeam().id == 1
    local skinData = {
        flag = isRed and 'blue_flag' or 'red_flag'
    }
    player:changeSkin(skinData)
end

function entityCtrl:removeDebuff(player)
    local skinData = {
        flag = ''
    }
    player:changeSkin(skinData)
    player:setProp('moveSpeed', player:data('moveSpeed'))
end

local function getNumberData(player, name)
    local data = player:data(name)
    return type(data) == 'number' and data or 0
end

local function clearCaptureFlagData(player)
    entityCtrl:removeDebuff(player)
    player:setData('flagIndex', nil)
    PackageHandlers.sendServerHandler(player, "showAndCloseGuide")
end

function entityCtrl:initPlayerData(player)
    clearCaptureFlagData(player)
    player:setData('handFlagTime', 0)
    player:setData('startCaptureFlagTime', nil)
    player:setData('captureFlagSum', 0)
    local cancelFunc = player:data('cancelCountdownFunc')
    local useless = type(cancelFunc) == 'function' and cancelFunc()
    player:setData('cancelCountdownFunc', nil)
end

function entityCtrl:addHandFlagTime(player)
    local startCaptureFlagTime = player:data('startCaptureFlagTime')
    if type(startCaptureFlagTime) ~= 'number' then
        return
    end
    local now = World.Now()

    local handFlagTime = getNumberData(player, 'handFlagTime')
    handFlagTime = handFlagTime + (now - startCaptureFlagTime)
    player:setData('handFlagTime', handFlagTime)
    player:setData('startCaptureFlagTime', nil)
end

function entityCtrl:captureFlag(player)
    local captureFlagSum = getNumberData(player, 'captureFlagSum')
    player:setData('captureFlagSum', captureFlagSum + 1)
end

function entityCtrl:getAllPlayerCaptureFlagData(playerList)
    local redRankData = {}
    local blueRankData = {}
    local redHandFlagTime, blueHandFlagTime = 0, 0
    local redCaptureSum, blueCaptureSum = 0, 0
    for id, player in pairs(playerList) do
        if player and player:isValid() then
            self:addHandFlagTime(player)
            local captureFlagSum = getNumberData(player, 'captureFlagSum')
            local handFlagTime = getNumberData(player, 'handFlagTime')
            local isRed = player:getTeam().id == 1
            local rankData = isRed and redRankData or blueRankData
            redHandFlagTime = isRed and redHandFlagTime + handFlagTime or redHandFlagTime
            blueHandFlagTime = isRed and blueHandFlagTime or blueHandFlagTime + handFlagTime
            redCaptureSum = isRed and redCaptureSum + captureFlagSum or redCaptureSum
            blueCaptureSum = isRed and blueCaptureSum or blueCaptureSum + captureFlagSum

            handFlagTime = string.format("%.2f", handFlagTime / 20)
            table.insert(rankData, { captureFlagSum = captureFlagSum, handFlagTime = handFlagTime, name = player.name })
        end
    end
    table.sort(redRankData, function(data1, data2)
        if data1.captureFlagSum > data2.captureFlagSum or
                data1.captureFlagSum == data2.captureFlagSum and
                        data1.handFlagTime > data2.handFlagTime then
            return true
        end
    end)
    table.sort(blueRankData, function(data1, data2)
        if data1.captureFlagSum > data2.captureFlagSum or
                data1.captureFlagSum == data2.captureFlagSum and
                        data1.handFlagTime > data2.handFlagTime then
            return true
        end
    end)
    local victoryTeamID
    if (redCaptureSum > blueCaptureSum
            or redCaptureSum == blueCaptureSum
            and redHandFlagTime > blueHandFlagTime) or #blueRankData == 0 then
        victoryTeamID = 1
    else
        victoryTeamID = 2
    end
    return redRankData, blueRankData, victoryTeamID
end

function entityCtrl:joinTeam(team,player)
    team:joinEntity(player)
    local skinData = team.id == 1 and redSkinData or blueSkinData
    player:changeSkin(skinData)
end

function entityCtrl:leaveTeam(team,player)
    team:leaveEntity(player)
end


Trigger.RegisterHandler(cfg, "ENTITY_DIE", function(context)
    local player = context.obj1
    if type(player:data('flagIndex')) == 'number' then
        local cancelFunc = player:data('cancelCountdownFunc')
        local useless = type(cancelFunc) == 'function' and cancelFunc()
        Lib.emitEvent('CREATE_FLAG', player)
        entityCtrl:addHandFlagTime(player)
        clearCaptureFlagData(player)
    end
end)

Trigger.RegisterHandler(cfg, "ENTITY_ENTER", function(context)
    local player = context.obj1
    local defaultMoveSpeed = player:prop('moveSpeed')
    player:setData('moveSpeed', defaultMoveSpeed)
    Lib.emitEvent('PLAYER_ENTER', player)
end)

Trigger.RegisterHandler(cfg, "ENTITY_LEAVE", function(context)
    local player = context.obj1
    Lib.emitEvent('PLAYER_EXIT', player.objID)
end)

return entityCtrl