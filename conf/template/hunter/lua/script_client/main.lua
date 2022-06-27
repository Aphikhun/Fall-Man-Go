print('script_client:hello world')
local gameInfo
World.Timer(10, function()
    --local guiMgr = GUIManager:Instance()
    UI:openWindow("seleceHeroWnd")
    gameInfo = UI:openWindow("gameInfoWnd")
end)

PackageHandlers.registerClientHandler("refreshMonsterSum", function(player, packet)
    gameInfo:refreshMonsterSum(packet.sum)
end)

PackageHandlers.registerClientHandler("showNextWaveTip", function(player, packet)
    gameInfo:showNextWaveTip(packet)
end)
PackageHandlers.registerClientHandler("showOrHideWnd", function(player, packet)
    gameInfo:showOrHideWnd(packet.isShow)
end)

--Show or close the guide
PackageHandlers.registerClientHandler("showOrCloseGuide", function(player, packet)
    local pos = packet.guidePos
    if pos then
        Me:setGuideTarget(pos, 'guide.png', 0.1)
    else
        Me:delGuideTarget()
    end
end)