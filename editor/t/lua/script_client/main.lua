print('script_client:hello world')
local Audio = require "script_client.audioMgr"

local mainWnd = UI:openWindow("mainWnd")
UI:openWindow("Help")


World.Timer(10, function()
    --local guiMgr = GUIManager:Instance()

end)

Lib.subscribeEvent("INIT_TEAM_INFO", function(...)
    mainWnd:initTeamInfo()
end)

Lib.subscribeEvent("HIDE_SEVEN_LOGIN_RED_DOT", function(...)
    mainWnd:hideSevenLoginRedDot()
end)

PackageHandlers.registerClientHandler("showSevenLoginRedDot", function(player, packet)
    mainWnd:showSevenLoginRedDot()
end)

PackageHandlers.registerClientHandler("refreshCaptureFlagProcess", function(player, packet)
    mainWnd:refreshCaptureFlagProcess(packet.totalTime,packet.curTime)
end)

PackageHandlers.registerClientHandler("closeCaptureFlagProcess", function(player, packet)
    mainWnd:closeCaptureFlagProcess()
end)

PackageHandlers.registerClientHandler("UI_setTipText", function(player, packet)
    mainWnd:setTipText(packet)
end)

PackageHandlers.registerClientHandler("UI_setTime", function(player, packet)
    mainWnd:setTime(packet)
end)

PackageHandlers.registerClientHandler("UI_scoreChange", function(player, packet)
    mainWnd:setTeamScore(packet.redScore,packet.blueScore)
end)

PackageHandlers.registerClientHandler("UI_setFlagSumTip", function(player, packet)
    mainWnd:setFlagSumTip(packet.langKey,packet.sum)
end)

PackageHandlers.registerClientHandler("UI_addInfoWnd", function(player, packet)
    mainWnd:addInfoWnd(packet.langKey,packet.index)
end)

PackageHandlers.registerClientHandler("showAndCloseGuide", function(player, packet)
    local pos = packet and packet.guidePos
    if pos then
        Me:setGuideTarget(pos, 'guide.png', 0.1)
    else
        Me:delGuideTarget()
    end
end)

PackageHandlers.registerClientHandler("UI_openRankWnd", function(player, packet)
    local rankWnd = UI:openWindow("rankListWnd")
    rankWnd:setRankData(packet)
    mainWnd:setTime()
end)

PackageHandlers.registerClientHandler("UI_openSevenLoginWnd", function(player, packet)
    local sevenLoginWnd = UI:openWindow("sevenLoginWnd")
    sevenLoginWnd:updateDayData(packet.index, packet.haveGot)
end)

--Audio
PackageHandlers.registerClientHandler("playSound", function(player, packet)
    Audio.PlaySound(packet.soundName, packet.pos)
end)

PackageHandlers.registerClientHandler("playGlobalSound", function(player, packet)
    Audio.PlayGlobalSound(packet.soundName, packet.pos)
end)

PackageHandlers.registerClientHandler("stopSound", function(player, packet)
    Audio.StopSound(Audio.GetSoundIDByName(packet.soundName))
end)

Lib.subscribeEvent(Event.EVENT_FINISH_DEAL_GAME_INFO, function(...)
    --DebugDraw.Instance():setDrawColliderEnabled(true)
end)