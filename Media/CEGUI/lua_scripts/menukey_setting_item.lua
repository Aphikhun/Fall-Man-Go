function M:onOpen(itemData, pcKeyData)
    self:initData(pcKeyData)
    self:init(itemData)
end

function M:initData(pcKeyData)
    self.keySettingTipWidget = pcKeyData.keySettingTipWidget
    self.keySettingTipMessage = pcKeyData.keySettingTipMessage
    self.keySettingTipShowTime = pcKeyData.keySettingTipShowTime
    self.needShowKeySettingTip = pcKeyData.needShowKeySettingTip
    self.keySettingTipColor = pcKeyData.keySettingTipColor
    self.keySettingMap = pcKeyData.keySettingMap
end

function M:init(itemData)
    local isTitle = itemData.IsTitle > 0
    self.MenuKeySettingItem_Bg:setVisible(not isTitle)
    self.MenuKeySettingItem_Title:setVisible(isTitle)
    
    local opText = self.MenuKeySettingItem_OpText
    opText:setVisible(not isTitle)
    
    local titleText = self.MenuKeySettingItem_TitleText
    titleText:setVisible(isTitle)
    
    local editor = self.MenuKeySettingItem_Edit
    editor.Data = {}
    editor:setVisible(not isTitle)
    --editor:SetTextColor({1, 1, 1})
    --editor:SetTextBorder(true)
    if isTitle then
        titleText:setText(Lang:toText(itemData.Language))
        editor:setText(0)
        editor.Data["DefaultKey"] = 0
    else
        opText:setText(Lang:toText(itemData.Language))
        editor:setText(Clientsetting.vkcode2String(Clientsetting.getCustomKeySettingKeyCode(itemData.KeyCode)))
        editor.Data["DefaultKey"] = itemData.KeyCode
    end
    
    local resetButton = self.MenuKeySettingItem_Reset
    resetButton:setText(Lang:toText("gui_setting_item_reset_text"))
    resetButton:setVisible(not isTitle)
    resetButton.onMouseClick = function (btn)
        self:resetKeySettingItem(editor)
        Clientsetting.saveCustomKeySetting()
    end
    self.isExecuteComplete = false
    editor.onTextChanged = function()
        if not self.isExecuteComplete then
            self:onKeySettingItemChanged(editor, itemData.KeyCode)
        end
        self.isExecuteComplete = false
    end
    if itemData.KeyCode then
        self.keySettingMap[itemData.KeyCode] = self
    end
end



function M:onKeySettingItemChanged(editor, defalutKeyCode)
    local curText = string.upper(editor:getText())
    if curText == "`" then
        curText = "~"
    end
    local msg = ""
    local tipColor = "ffff0000"
    local customKeyCode = Clientsetting.getCustomKeySettingKeyCode(defalutKeyCode)
    if Clientsetting.isInvaildString(curText) then
        local keyCode = Clientsetting.string2vkcode(curText)
        if keyCode == customKeyCode then
            return
        elseif customKeyCode then
            local isRepeat = false
            for k, v in pairs(Clientsetting:getCustomKeySetting()) do
                if v == keyCode then
                    isRepeat = true
                    break
                end
            end
            if not isRepeat then
                Clientsetting.setCustomKeySettingKeyCode(defalutKeyCode, keyCode)
                Clientsetting.saveCustomKeySetting()
                msg = Lang:toText("gui_setting_key_change_suc")
                tipColor = "ff00ff00"
                Blockman.instance.gameSettings:setKeySettingMapByKeyCode(defalutKeyCode, keyCode)
            else
                msg = Lang:toText("gui_setting_key_repeat")
                self.isExecuteComplete = true
                editor:setText(Clientsetting.vkcode2String(customKeyCode))
            end
        end
    else
        self.isExecuteComplete = true
        editor:setText(Clientsetting.vkcode2String(customKeyCode))
        msg = Lang:toText("gui_setting_key_invalid")
    end
    self:setKeySettingTipMessage(msg, tipColor)
    World.Timer(1, self.showKeySettingPanel, self, 50, self.keySettingTipMessage, 1500)
end

function M:setKeySettingTipMessage(message, color)
    self.keySettingTipMessage = message
    self.needShowKeySettingTip = true
    self.keySettingTipColor = color
end

function M:resetKeySettingItem(editor)
    local defaultKeyCode = editor.Data["DefaultKey"]
    Clientsetting.setCustomKeySettingKeyCode(defaultKeyCode, defaultKeyCode)
    editor:setText(Clientsetting.vkcode2String(defaultKeyCode))
    if Clientsetting.getCustomKeySettingKeyCode(defaultKeyCode) then
        Blockman.instance.gameSettings:setKeySettingMapByKeyCode(defaultKeyCode, defaultKeyCode) --confilt
        local tipColor = "0 1 0 1"
        self:setKeySettingTipMessage(Lang:toText("gui_setting_key_reset_suc"), tipColor)
        World.Timer(1, self.showKeySettingPanel, self, 50, self.keySettingTipMessage, 1500)
        for key, custormKeyItem in pairs(Clientsetting:getCustomKeySetting()) do
            if custormKeyItem == defaultKeyCode and key ~= defaultKeyCode then
                self:resetKeySettingItem(self.keySettingMap[key].MenuKeySettingItem_Edit)
            end
        end
    end
end

function M:showKeySettingPanel(nTimeElapse, msg, tipShwoTime)
    if self.needShowKeySettingTip and self.keySettingTipShowTime < tipShwoTime then
        self.keySettingTipShowTime = self.keySettingTipShowTime + nTimeElapse
    else
        self.needShowKeySettingTip = false
        self.keySettingTipShowTime = 0.0
        self.keySettingTipWidget:setText("")
        return false
    end
    if self.needShowKeySettingTip then
        self.keySettingTipWidget:setProperty("TextColor", self.keySettingTipColor)
        self.keySettingTipWidget:setText(msg)
    end
    return true
end

function M:invoke(funcName, ...)
    assert(self[funcName], "invoke not func, funcName: " .. funcName)
    return self[funcName](self, ...)
end