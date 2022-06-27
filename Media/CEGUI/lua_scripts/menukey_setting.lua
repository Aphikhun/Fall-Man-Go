function M:onOpen()
    self:initMenuKeyItem()
end

function M:initMenuKeyItem()
    self:setVisible(false)
    local keySettingItemList = self.MenuPlayer_PlayerList.MenuKeySetting_List
    local keySettingTipWidget = self.MenuKeySetting_Tip_Message
    keySettingTipWidget:setVisible(true)
    keySettingTipWidget:setText("")

    local pcKeyData = {
        keySettingTipWidget = keySettingTipWidget,
        keySettingTipMessage = "",
        keySettingTipShowTime = 0.0,
        needShowKeySettingTip = false,
        keySettingTipColor = "",
        keySettingMap = {},
    }
    self.keyItems = {}
    for _, itemData in pairs(Clientsetting.getKeySettingDefault()) do
        local item = UI:openWidget("menukey_setting_item", "_layouts_", itemData, pcKeyData)
        keySettingItemList:addChild(item:getWindow())
        self.keyItems[#self.keyItems + 1] = item
    end
end

function M:resetAllKeySetting()
    for k, keyItem in pairs(self.keyItems) do
        keyItem:invoke("resetKeySettingItem", keyItem.MenuKeySettingItem_Edit)
    end
end


function M:invoke(funcName, ...)
    assert(self[funcName], "invoke not func, funcName: " .. funcName)
    return self[funcName](self, ...)
end