local wave = 1          --The current wave of monsters
local monsterCount = -1 --Current number of monsters
local index = 1

--Generate the location point of the portal
local portalPos = Lib.v3(28, 13, -11.5)

--The weapon configuration name corresponding to the occupation
local weaponTb = {
    'myplugin/sword',
    'myplugin/wand',
    'myplugin/High_sorcerer\'s_staff',
}

--Random monster spawn location point
local randomList = {}
table.insert(randomList, Lib.v3(-16, 1, -12.5))
table.insert(randomList, Lib.v3(-13, 1, -8))
table.insert(randomList, Lib.v3(-3, 1, -6))
table.insert(randomList, Lib.v3(-3, 1, -13))
table.insert(randomList, Lib.v3(1, 1, -22))
table.insert(randomList, Lib.v3(-6, 1, -32))
table.insert(randomList, Lib.v3(-2, 1, -33))
table.insert(randomList, Lib.v3(-3, 1, -40))

--Monster configuration table, how many waves of monsters there are according to the length of the table
local monsterList = {
    {
        [1] = { name = 'myplugin/fier_devil', num = 2 },
        [2] = { name = 'myplugin/ice_devil', num = 2 },
    },
    {
        [1] = { name = 'myplugin/thunder_devil', num = 1 },
        [2] = { name = 'myplugin/ents', num = 1 },
        [3] = { name = 'myplugin/ice_devil', num = 2 },
        [4] = { name = 'myplugin/fier_devil', num = 2 },
    },
    {
        [1] = { name = 'myplugin/Fire_guys', num = 1, pos = Lib.v3(-25, 11, -74) },
        [2] = { name = 'myplugin/ice _blame', num = 1, pos = Lib.v3(-53, 10, 5) },
        [3] = { name = 'myplugin/ice_devil', num = 2 },
        [4] = { name = 'myplugin/ents', num = 2 },
        [5] = { name = 'myplugin/thunder_devil', num = 2, },
        [6] = { name = 'myplugin/fier_devil', num = 2 },
    },
}

--update random number seed
local function updateRandom()
    index = index + 1
    if index > 100 then
        index = 1
    end
end

local function getRandomPos()
    local _i = index
    updateRandom()
    math.randomseed(tostring(os.time()):reverse():sub(1, 7) + _i)
    local n = math.random(1, #randomList)
    return randomList[n]
end

--Generate a wave of monsters
local function createMonster(map)
    if map and map:isValid() then
        monsterCount = 0

        --clear map entity
        for id, object in pairs(map.objects) do
            if object and object:isValid() and not object.isPlayer then
                object:destroy()
            end
        end

        --Create monsters
        for _, info in pairs(monsterList[wave]) do
            monsterCount = monsterCount + info.num
            for i = 1, info.num do
                local createParams = { cfgName = info.name, pos = info.pos or getRandomPos(), map = map }
                local entity = EntityServer.Create(createParams)
            end
        end
    end
    --client update ui
    PackageHandlers.sendServerHandlerToAll("refreshMonsterSum", { sum = monsterCount })
end

Lib.subscribeEvent("CreateMonster", createMonster)

--Death callback event, handling monster death logic
Trigger.addHandler(World.cfg, "ENTITY_DIE", function(context)
    local entity = context.obj1
    local player = context.obj2
    local map = entity.map
    local name = entity.name
    
    if not player then
        for i, _player in pairs(Game.GetAllPlayers() ) do
            player = _player
        end
    end

    --monster death handling
    if not entity.isPlayer then
        monsterCount = monsterCount - 1
        PackageHandlers.sendServerHandlerToAll("refreshMonsterSum", { sum = monsterCount })
        if monsterCount == 0 then
            wave = wave + 1
            if wave > #monsterList then  --Victory deal
                wave = 1
                local createParams = { cfgName = 'myplugin/transfer2', pos = Lib.copy(portalPos), map = map }
                local entity = EntityServer.Create(createParams)
                PackageHandlers.sendServerHandlerToAll("showOrHideWnd", { isShow = false })
                PackageHandlers.sendServerHandlerToAll("showOrCloseGuide", { guidePos = portalPos })

            else    --Spawn the next wave of monsters
                PackageHandlers.sendServerHandlerToAll("showNextWaveTip")
                World.Timer(20 * 5, function()
                    createMonster(map)
                end)
            end
        end

        --Special monster drop equipment handling
        if name == 'entity_ice _blame' or name == 'entity_Fire_guys' then
            local itemName = weaponTb[player:data('job')]
            local params = {
                item = Item.CreateItem(itemName, 1),
                map = player.map,
                pos = entity:getPosition()
            }
            local dropItem = DropItemServer.Create(params)
        end
    end
end)