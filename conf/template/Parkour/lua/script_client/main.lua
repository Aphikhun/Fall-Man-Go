print('script_client:hello world')
local GameWindow
World.Timer(3, function()
    --local guiMgr = GUIManager:Instance()
    GameWindow = UI:openWindow("GameInfo")
end)

PackageHandlers.registerClientHandler("CountdownHandler", function(player, timeInfo)
    GameWindow:refreshTimer(timeInfo)
end)

PackageHandlers.registerClientHandler("ShowRankUI", function(player, packet)
    GameWindow:refreshRankInfo(packet)
end)

