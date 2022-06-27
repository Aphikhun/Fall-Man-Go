
--Calculate the time spent by the player
local function calcSpendTime()
  local now =  World.Now()
  for id, player in pairs(Game.GetAllPlayers()) do
    local startTime = player:data('StartTime')
    if type(startTime)=='number' and startTime >=1 then
      local timeInfo = {}
      local totalTime = now - startTime
      timeInfo.minute = math.floor(totalTime/1200) 
      timeInfo.second = math.floor(totalTime/20) % 60
      timeInfo.millisecond = (totalTime%20) *5
      PackageHandlers.sendServerHandler(player, 'CountdownHandler', timeInfo)
    end
  end
end

World.Timer(1,function()
    calcSpendTime()
    return true
  end)