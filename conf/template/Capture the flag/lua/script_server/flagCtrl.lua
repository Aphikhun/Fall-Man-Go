local entityCtrl = require "script_server.entityCtrl"

local cfgName = 'myplugin/flag'
local checkLayEntityCfgName = 'myplugin/checkLay'
local flagCfg = Entity.GetCfg(cfgName)
local checkLayEntityCfg = Entity.GetCfg(checkLayEntityCfgName)
local minPos = 13

local totalCaptureFlagTime = 5    --Capture the Flag Duration(seconds)

local flagResetTime = 15    --flag reset time(seconds)

local flagActor = {
    [1] = 'red.actor', --red
    [2] = 'blue.actor', --blue
}

--Red flag generation location point
local redFlagPos = {
    Lib.v3(55.88, 44.58, 21.03),
    Lib.v3(55.38, 57.2, 17.54),
    Lib.v3(55.38, 96.17, 19.35)
}

--Blue flag generation location point
local blueFlagPos = {
    Lib.v3(56, 44.64, -139.9),
    Lib.v3(55.72, 57.2, -137),
    Lib.v3(55.99, 96.17, -135.9)
}

--total number of flags
local totalFlagSum = #redFlagPos
local curFlagSum
local curTeamScore

local flagPosTb = {
    [1] = redFlagPos,
    [2] = blueFlagPos
}

--Placing a flag triggers entity location
local checkLayEntityPos = {
    [1] = Lib.v3(102.97, 26.88, -96.19), --blue
    [2] = Lib.v3(102.9, 26.73, -22.16)     --red
}

--red flag placement point
local redFlagLayPos = {
    Lib.v3(102.97, 26.88, -98.19),
    Lib.v3(102.97, 26.88, -96.19),
    Lib.v3(102.97, 26.88, -94.19)
}

--blue flag placement point
local blueFlagLayPos = {
    Lib.v3(102.9, 26.73, -24.16),
    Lib.v3(102.9, 26.73, -22.16),
    Lib.v3(102.9, 26.73, -20.16)
}

local flagLayPosTb = {
    [1] = redFlagLayPos,
    [2] = blueFlagLayPos
}

local function teamSendServerHandler(team, name, packet)
    local playerList = team:getEntityList()
    for i, player in pairs(playerList) do
        PackageHandlers.sendServerHandler(player, name, packet)
    end
end

local function createFlagEntity(pos, map, teamID, index)
    local createParams = { cfgName = cfgName, pos = pos, map = map }
    local entity = EntityServer.Create(createParams)
    local actorName = flagActor[teamID]
    entity:changeActor(actorName)       --Set the flag's actor
    entity:setData('teamID', teamID)    --Set the flag's team ID
    entity:setData('index', index)      --Set the flag's position index
    return entity
end

local function createFlag(posTb, map, teamID)
    for i, pos in ipairs(posTb) do
        createFlagEntity(pos, map, teamID, i)
    end
end

local function createCheckLayEntity(map, teamID)
    local pos = checkLayEntityPos[teamID]
    local createParams = { cfgName = checkLayEntityCfgName, pos = pos, map = map }
    local entity = EntityServer.Create(createParams)
    entity:setData('teamID', teamID)
end

local function initEntity(map)
    createFlag(redFlagPos, map, 1)
    createFlag(blueFlagPos, map, 2)
    createCheckLayEntity(map, 1)
    createCheckLayEntity(map, 2)
end

local function showFlagSumTip(teamID)
    local team = Game.GetTeam(teamID)
    local enemyId = ((teamID + 2) % 2) + 1

    local enmeyScore = curTeamScore[enemyId]
    local sum = totalFlagSum - curFlagSum[teamID]
    if enmeyScore ~= sum then
        teamSendServerHandler(team, 'UI_setFlagSumTip', { langKey = 'langKey_Flag_taken_tip', sum = sum - enmeyScore })
    else
        teamSendServerHandler(team, 'UI_setFlagSumTip', { langKey = 'langKey_Flag_residue_sum_tip', sum = curFlagSum[teamID] })
    end

end

local function flagSumChange(teamID, sum)
    curFlagSum[teamID] = curFlagSum[teamID] + sum

    showFlagSumTip(teamID)
end

local function teamScoreChange(teamID, sum)
    curTeamScore[teamID] = curTeamScore[teamID] + sum

    PackageHandlers.sendServerHandlerToAll("UI_scoreChange", { redScore = curTeamScore[1], blueScore = curTeamScore[2] })
    if curTeamScore[teamID] == totalFlagSum then
        Lib.emitEvent("GAME_OVER")
    end
end

local function captureFlag(player, flag)
    if player and player:isValid() then
        local flagTeamID = flag:data('teamID')
        local pos = checkLayEntityPos[flagTeamID] + Lib.v3(0, 1, 0)
        local index = flag:data('index')
        flagSumChange(flagTeamID, -1)

        teamSendServerHandler(Game.GetTeam(flagTeamID), 'UI_addInfoWnd', { langKey = 'langKey_Taken_flag', index = index })
        teamSendServerHandler(Game.GetTeam(flagTeamID), 'playSound', { soundName = 'takenFlag' })

        entityCtrl:addDebuff(player)
        player:setData('flagIndex', index)           --Set data, the player holds the flag
        player:setData('startCaptureFlagTime', World.Now())
        
        PackageHandlers.sendServerHandler(player, "closeCaptureFlagProcess")
        PackageHandlers.sendServerHandler(player, "showAndCloseGuide", { guidePos = pos })
        PackageHandlers.sendServerHandler(player, "playSound", { soundName = 'pickFlag' })
        
        flag:destroy()
    end
end

local function captureFlagCountdown(player, flag)
    local time = 0
    local totalTime = totalCaptureFlagTime * 20
    PackageHandlers.sendServerHandler(player, "playSound", { soundName = 'captureFlag' })
    local cancelCountdownFunc = flag:timer(1, function()
        time = time + 1
        
        --Update client progress bar step size
        PackageHandlers.sendServerHandler(player, "refreshCaptureFlagProcess", { curTime = time, totalTime = totalTime })
        if time >= totalTime then
            captureFlag(player, flag)         --capture the flag success
            return
        end
        return true
    end)
    player:setData('cancelCountdownFunc', cancelCountdownFunc)   --Cancel capture the flag timer
end

Lib.subscribeEvent("GAME_START", function(map)
    curFlagSum = {
        totalFlagSum,
        totalFlagSum
    }
    curTeamScore = {
        0,
        0
    }
    initEntity(map)
    teamSendServerHandler(Game.GetTeam(1), 'UI_setFlagSumTip', { langKey = 'langKey_Flag_residue_sum_tip', sum = curFlagSum[1] })
    teamSendServerHandler(Game.GetTeam(2), 'UI_setFlagSumTip', { langKey = 'langKey_Flag_residue_sum_tip', sum = curFlagSum[1] })
end)

--Capture the flag, according to the state of the flag and the player team, there are different processing methods
Trigger.RegisterHandler(flagCfg, "ENTITY_TOUCH_ALL", function(context)
    local flag = context.obj1
    local player = context.obj2

    --The flag that has been placed at the end cannot be operated
    if flag:data('isLay') == true then
        return
    end

    local teamID = player:getTeam().id
    if player.isPlayer and teamID ~= flag:data('teamID') and type(player:data('flagIndex')) ~= 'number' then
        if flag:data('outside') == true then
            local cancelFunc = player:data('cancelCountdownFunc')
            local useless = type(cancelFunc) == 'function' and cancelFunc()
            
            --Flags dropped outside can be picked up directly
            captureFlag(player, flag)
        else
            captureFlagCountdown(player, flag)
        end
    end
end)

--Leave the capture flag area cancel the capture flag
Trigger.RegisterHandler(flagCfg, "ENTITY_APART", function(context)
    local flag = context.obj1
    local player = context.obj2

    --The flag that has been placed at the end cannot be operated
    if flag:data('isLay') == true then
        return
    end

    local teamID = player:getTeam().id
    if player.isPlayer and teamID ~= flag:data('teamID') then
        local cancelFunc = player:data('cancelCountdownFunc')
        --If the flag is being captured, cancel the capture of the flag
        local useless = type(cancelFunc) == 'function' and cancelFunc()    
        
        PackageHandlers.sendServerHandler(player, "stopSound", { soundName = 'captureFlag' })
        PackageHandlers.sendServerHandler(player, "closeCaptureFlagProcess")
    end
end)

--Place the flag at the end point, and update the data, etc.
Trigger.RegisterHandler(checkLayEntityCfg, "ENTITY_TOUCH_ALL", function(context)
    local checkLayEntity = context.obj1
    local player = context.obj2

    local teamID = checkLayEntity:data('teamID')
    if player.isPlayer and player:getTeam().id ~= teamID and type(player:data('flagIndex')) == 'number' then
        local posTb = flagLayPosTb[teamID]
        local index = player:data('flagIndex')
        local pos = posTb[index]
        local entity = createFlagEntity(pos, player.map, teamID)   --Generate flag at target point
        entity:setData('isLay', true)           --set the state of that flag

        player:setData('flagIndex', nil)        --Changed stats, players no longer have flags
        entityCtrl:addHandFlagTime(player)
        entityCtrl:removeDebuff(player)
        entityCtrl:captureFlag(player)          --Player Capture the Flag successfully processed data
        
        teamScoreChange(player:getTeam().id, 1) --Change team score
        showFlagSumTip(teamID)
        
        teamSendServerHandler(Game.GetTeam(teamID), 'UI_addInfoWnd', { langKey = 'langKey_lose_flag', index = index })
        teamSendServerHandler(Game.GetTeam(teamID), 'playSound', { soundName = 'loseFlag' })
        teamSendServerHandler(player:getTeam(), 'playSound', { soundName = 'addScore' })
        PackageHandlers.sendServerHandler(player, "showAndCloseGuide")
    end
end)

--The player holding the flag dies, the handling of the flag
Lib.subscribeEvent("CREATE_FLAG", function(player)
    local pos = player:getPosition()
    local enemyTeamID = player:getTeam().id == 1 and 2 or 1
    local index = player:data('flagIndex')
    local posTb = flagPosTb[enemyTeamID]
    local map = player.map
    if pos.y < minPos then
        --Fall into the void and die. The flag goes straight back to the starting point
        pos = posTb[index]
        createFlagEntity(pos, map, enemyTeamID, index)
        flagSumChange(enemyTeamID, 1)
    else
        local entity = createFlagEntity(pos, map, enemyTeamID, index)
        entity:setData('outside', true)

        --After 15 seconds, no one picked up the flag, and the flag returned to the initial position
        entity:timer(flagResetTime * 20, function()
            if map and map:isValid() then
                pos = posTb[index]
                createFlagEntity(pos, map, enemyTeamID, index)
                flagSumChange(enemyTeamID, 1)
                entity:destroy()
            end
        end)
    end
end)

Lib.subscribeEvent("SET_FLAG_SUM", function(player)
    local teamID = player:getTeam().id
    PackageHandlers.sendServerHandler(player,'UI_setFlagSumTip', { langKey = 'langKey_Flag_residue_sum_tip', sum = curFlagSum[teamID]})
end)

