local entityCtrl = require "script_server.entityCtrl"

local gameState = {
    'wait',
    'readyStart',
    'start',
}

local rebirthPos = {
    Lib.v3(100, 26.5, -3), --red
    Lib.v3(100, 26.5, -116)  --blue
}

local minPlayerSum = 2  --Minimum number of people to start the game

local gameTotalTime = 10 * 60 --Game duration (seconds)

local gameReadyTime = 10 --Preparation time (seconds)

local curGameState = gameState[1]

local readyPlayerList = {}

local curMap

local function sendServerHandlerToReadyPlayer(name, pakcet)
    for i, player in pairs(readyPlayerList) do
        if player and player:isValid() then
            PackageHandlers.sendServerHandler(player, name, pakcet)
        else
            readyPlayerList[i] = nil
        end
    end
end

local function gameStateChange(index)
    curGameState = gameState[index]
    sendServerHandlerToReadyPlayer("playGlobalSound", { soundName = curGameState })
end

--Balance the number of teams
local function balaneceTeam(team1, team2)
    for i, player in pairs(team1:getEntityList()) do
        entityCtrl:leaveTeam(team1, player)
        entityCtrl:joinTeam(team2, player)
        player:setData('teamID', team2.id)
        return
    end
end

-- Compare the number of teams
local function compareTeamPlayerNum()
    local team1 = Game.GetTeam(1, true)
    local team2 = Game.GetTeam(2, true)

    local count1 = team1.playerCount
    local count2 = team2.playerCount
    if math.abs(count1 - count2) > 1 then
        if count1 > count2 then
            balaneceTeam(team1, team2)
        else
            balaneceTeam(team2, team1)
        end
    end
end

local function allPlayerExitTeam()
    for id, player in pairs(readyPlayerList) do
        local team = player:getTeam()
        entityCtrl:leaveTeam(team, player)
    end
end

local cancelCountdownFunc --Cancel the countdown to start the game
local cancelGameEndCountdownFunc

local function gameOver()
    local useless = cancelGameEndCountdownFunc and cancelGameEndCountdownFunc()
    local redRankData, blueRankData, victoryTeamID = entityCtrl:getAllPlayerCaptureFlagData(readyPlayerList)
    for i, player in pairs(readyPlayerList) do
        if player and player:isValid() then
            local teamID = player:getTeam().id
            local rankData = player:getTeam().id == 1 and redRankData or blueRankData
            PackageHandlers.sendServerHandler(player, "UI_openRankWnd", { rankData = rankData, isVictory = victoryTeamID == teamID })
            PackageHandlers.sendServerHandler(player, "playGlobalSound", { soundName = 'finish' })
        end
    end
    allPlayerExitTeam()
    --sendServerHandlerToReadyPlayer("UI_openRankWnd", rankData)
    readyPlayerList = {}
    gameStateChange(1)
end

local function gameEndCountdown(map)
    local time = gameTotalTime
    cancelGameEndCountdownFunc = World.Timer(20, function()
        if map and map:isValid() then
            time = time - 1
            local timeInfo = {}
            timeInfo.minute = math.floor(time / 60)
            timeInfo.second = math.floor(time) % 60
            sendServerHandlerToReadyPlayer("UI_setTime", timeInfo)
            if time <= 0 then
                gameOver()
                return
            end
            return true
        end
    end)
end

local function setRebirthPos(map,player)
    local id = player:getTeam().id
    local pos = Lib.copy(rebirthPos[id])
    player:setRebirthPos(pos, map)
    player:serverRebirth()
end

local function gameStart()
    Game.SendStartGame()
    curMap = World.CurWorld:createDynamicMap("map001", true) --New map
    for i, player in pairs(readyPlayerList) do
        --Start the game and transfer the map
        setRebirthPos(curMap,player)
    end
    local useless = cancelCountdownFunc and cancelCountdownFunc()
    cancelCountdownFunc = nil
    Lib.emitEvent('GAME_START', curMap)
    gameEndCountdown(curMap)
    gameStateChange(3)
end

--Countdown to the start of the game
local function startGameCountdown()
    local time = gameReadyTime
    cancelCountdownFunc = World.Timer(20, function()
        time = time - 1
        sendServerHandlerToReadyPlayer("UI_setTipText", { 'langKey_Start_game_countdwon', time })
        if time <= 0 then
            gameStart()
            return
        end
        return true
    end)
end

--player enter game
local function playerEnter(player)
    entityCtrl:initPlayerData(player)
    readyPlayerList[player.objID] = player --Add players to the ready list
    --Assign team
    local team = player:getTeam()
    local useless = team and entityCtrl:leaveTeam(team, player)
    local team1 = Game.GetTeam(1, true)
    local team2 = Game.GetTeam(2, true)

    if team1.playerCount >= team2.playerCount then
        entityCtrl:joinTeam(team2, player)
        player:setData('teamID', 1)
    else
        entityCtrl:joinTeam(team1, player)
        player:setData('teamID', 2)
    end

    local count = Lib.getTableSize(readyPlayerList)

    --Whether to meet the conditions to start the game
    if count >= minPlayerSum and curGameState == 'wait' then
        gameStateChange(2)
        startGameCountdown()
    elseif curGameState == 'start' then
        setRebirthPos(curMap,player)
        Lib.emitEvent('SET_FLAG_SUM', player)
    else
        PackageHandlers.sendServerHandler(player, "UI_setTipText", { 'langKey_Waiting_player_enter' })
    end
    PackageHandlers.sendServerHandler(player, "playGlobalSound", { soundName = curGameState })
    useless = curMap and player:setMap(curMap)

end

Lib.subscribeEvent("PLAYER_ENTER", playerEnter)

PackageHandlers.registerServerHandler("playerEnter", function(player, packet)
    curMap = World.CurWorld:getMap("map001", true) --New map
    playerEnter(player)
end)

-- player exit game
local function playerExit(objID)
    local player = readyPlayerList[objID]
    if player and player.isPlayer then
        readyPlayerList[objID] = nil     --Remove the player from the ready list
        if curGameState == 'start' then
            local team1 = Game.GetTeam(1, true)
            local team2 = Game.GetTeam(2, true)

            if team1.playerCount == 0 or team2.playerCount == 0 then
                gameOver()
            end
        else
            compareTeamPlayerNum()
        end

        local count = Lib.getTableSize()
        if count < minPlayerSum and curGameState == 'readyStart' then
            --Insufficient people cancel to start the game
            gameStateChange(1)
            sendServerHandlerToReadyPlayer("UI_setTipText", { 'langKey_Waiting_player_enter' })
            local useless = cancelCountdownFunc and cancelCountdownFunc()
        end
    end
end

Lib.subscribeEvent("PLAYER_EXIT", playerExit)

Lib.subscribeEvent("GAME_OVER", gameOver)