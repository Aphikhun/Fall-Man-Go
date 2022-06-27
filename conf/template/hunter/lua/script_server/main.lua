print('script_server:hello world')
require "script_server.monsterMgr"

local heroWeapon = { [1] = 'myplugin/epee', [2] = 'myplugin/The magic book', [3] = 'myplugin/The_wizard_rod' }
local skin = {[1] = 'warrior',[2] = 'master', [3] = 'warlock' }

--Determine Occupation Sending Weapons
PackageHandlers.registerServerHandler("seleWeapon", function(player, packet)
    local index = packet.index
    player:addItem(heroWeapon[packet.index], 1, nil, 'gift')
    local skinData = {
        def = skin[index]
    }
    player:changeSkin(skinData)
    player:setData('job',packet.index)
end)

Trigger.addHandler(Entity.GetCfg('myplugin/player1'), "ENTER_MAP", function(context)

    local player = context.obj1
    local map = context.map
    local iscopy = 'copy'== map.name

    if iscopy then  --Battle map trigger logic
        PackageHandlers.sendServerHandlerToAll("showOrHideWnd",{isShow = iscopy})
        Lib.emitEvent('CreateMonster', map,player)
    else
        PackageHandlers.sendServerHandlerToAll("showOrCloseGuide",{})
        PackageHandlers.sendServerHandlerToAll("showOrHideWnd",{isShow = false})
    end

end)

