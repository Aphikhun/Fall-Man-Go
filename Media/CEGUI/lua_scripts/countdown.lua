function M:init()
  self.timeTextUI = self.Text
  self.Text1:setText(Lang:toText("gui.wait.rebirth"))
  self.setTimer = false
  self.backFuncs = {}
end

function M:setTime(time, backFunc)
  if self.setTimer then
    self.setTimer()
    self.setTimer = false
  end
  self.backFuncs[#self.backFuncs + 1] = backFunc
  self.timeTextUI:setText(tostring(math.floor(time / 20)))
  self.setTimer = World.Timer(20, function() 
    time = time - 20
    self.timeTextUI:setText(tostring(math.floor(time / 20)))
    if time > 0 then
      return true
    end
    for _, bf in ipairs(self.backFuncs) do
      if bf then
        bf()
      end
    end
    self.backFuncs = {}
    self:close()
  end)
end

self:init()