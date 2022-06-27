function M:onOpen(instance, settingConfigManager)
  M:initUI()
  World.cfg.engineDefUIEnable = World.cfg.engineDefUIEnable or {}
  local engineDefUIEnable = World.cfg.engineDefUIEnable
  if not UI:isOpenWindow("actionControl") and engineDefUIEnable.actionControl then
    UI:openWnd("actionControl")
  end

  M.settingConfig = settingConfigManager:getSpecialGameConfig(World.GameName, "operationSetting")

  if M.settingConfig.curMode == nil or M.settingConfig.curMode == "" then
    if World.cfg.engineDefUIEnable.actionControlMode then
        M.settingConfig.curMode = World.cfg.engineDefUIEnable.actionControlMode
    else
        M.settingConfig.curMode = "flexibleDragControl"
    end
  end

  local func = function()
    if M.settingConfig.curMode == "newKeyboard" then
      M.KeyboardRadioButton:setSelected(true)
    elseif M.settingConfig.curMode == "dragControl" then
      M.DragRadioButton:setSelected(true)
    elseif M.settingConfig.curMode == "flexibleDragControl" then
      M.FlexibleDragRadioButton:setSelected(true)
    else
      M.KeyboardRadioButton:setSelected(true)
    end
  end

  func()

  Lib.subscribeEvent(Event.EVENT_SWITCH_MOVE_CONTROL_MODE, function(mode)
    if M.settingConfig.curMode ~= mode then
      M.settingConfig.curMode = mode
      func()
    end
  end)
end

function M:initUI()
  M.Image:setImage("setting/bg_BiaoTi")
  M.Image.Text:setText(Lang:toText("setting.operationSetting.tab"))
  local KeyboardRadioButton = M.KeyboardRadioButton
  
  KeyboardRadioButton.Text:setText(Lang:toText("setting.operationSetting.keyboard"))
  KeyboardRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  KeyboardRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  KeyboardRadioButton.TickImage:setImage("setting/DuiGou")
  KeyboardRadioButton.Image:setImage("setting/FangXiangJian")
  KeyboardRadioButton.FrameImage:setImage("setting/CaoZuo_XuanZhong")

  local DragRadioButton = M.DragRadioButton
  DragRadioButton.Text:setText(Lang:toText("setting.operationSetting.drag"))
  DragRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  DragRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  DragRadioButton.TickImage:setImage("setting/DuiGou")
  DragRadioButton.Image:setImage("setting/GuDingYaoGan")
  DragRadioButton.FrameImage:setImage("setting/CaoZuo_XuanZhong")

  
  local FlexibleDragRadioButton = M.FlexibleDragRadioButton
  FlexibleDragRadioButton.Text:setText(Lang:toText("setting.operationSetting.flexibleDrag"))
  FlexibleDragRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  FlexibleDragRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  FlexibleDragRadioButton.TickImage:setImage("setting/DuiGou")
  FlexibleDragRadioButton.Image:setImage("setting/LingHuoYaoGan")
  FlexibleDragRadioButton.FrameImage:setImage("setting/CaoZuo_XuanZhong")

end


function M:switchMoveControl(mode)
  M.settingConfig.curMode = mode
  Lib.emitEvent(Event.EVENT_SWITCH_MOVE_CONTROL_MODE, mode)
end

function M.KeyboardRadioButton:onSelectStateChanged(instance)
  if instance:isSelected() then
    M:switchMoveControl("newKeyboard")
    self.TickImage:setVisible(true)
    self.FrameImage:setVisible(true)
  else
    self.FrameImage:setVisible(false)
    self.TickImage:setVisible(false)
  end
end

function M.DragRadioButton:onSelectStateChanged(instance)
  if instance:isSelected() then
    M:switchMoveControl("dragControl")
    self.TickImage:setVisible(true)
    self.FrameImage:setVisible(true)
  else
    self.FrameImage:setVisible(false)
    self.TickImage:setVisible(false)
  end
end

function M.FlexibleDragRadioButton:onSelectStateChanged(instance)
  if instance:isSelected() then
    M:switchMoveControl("flexibleDragControl")
    self.TickImage:setVisible(true)
    self.FrameImage:setVisible(true)
  else
    self.FrameImage:setVisible(false)
    self.TickImage:setVisible(false)
  end
end