function M:onOpen(nameKey, isSlider)
    self:init(nameKey, isSlider)
end

function M:init(nameKey, isSlider)
    self.GameSettingItem_Item.GameSettingItem_Name:setText(Lang:toText(nameKey))
    self.GameSettingItem_Item.GameSettingItem_Slider:setVisible(isSlider)
    self.GameSettingItem_Item.GameSettingItem_CheckBox:setVisible(not isSlider)
end
