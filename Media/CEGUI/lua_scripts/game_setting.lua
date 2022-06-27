function M:onOpen()
    self:init()
end

function M:init()
    self:setVisible(false)

    self.gameSettingGrid = self.ScrollablePane.GameSetting_grid

    local defaultSettings = Clientsetting.getSetting()

    local pSett = World.cfg.personalSettingUI or {}
    if pSett.luminance then
       self:createGameSettingSilderItem("gui.setting.luminance", defaultSettings.luminance, Clientsetting.refreshLuminance)
    end

    if pSett.volume == nil or pSett.volume then
        self:createGameSettingSilderItem("gui.setting.volume", defaultSettings.volume, Clientsetting.refreshVolume)
    end

    if pSett.horizon == nil or pSett.horizon then
        self:createGameSettingSilderItem("gui.setting.horizon", defaultSettings.horizon, Clientsetting.refreshHorizon)
    end
    
    if pSett.sensitive == nil or pSett.sensitive then
        local minSize, maxSize =  0.2, 1.2
        local progress = (defaultSettings.camera_sensitive - minSize) / (maxSize - minSize)
        self:createGameSettingSilderItem("gui.setting.camera.sensitive", progress, Clientsetting.refreshCameraSensitive)
    end
    
    if pSett.guiSize == nil or pSett.guiSize then
        local guiMinSize, guiMaxSize = 0.5, 1
        local fGuiSize = math.min(guiMaxSize, math.max(guiMinSize, defaultSettings.gui_size))
        local progressGui = (fGuiSize - guiMinSize) / (guiMaxSize - guiMinSize)
        self:createGameSettingSilderItem("gui.setting.gui.size", progressGui, function(value)
            Lib.emitEvent(Event.EVENT_SET_GUI_SIZE)
            Clientsetting.refreshGuiSize(value)
        end)
    end
    
    if pSett.controlMode == nil or pSett.controlMode then
        self:createGameSettingCheckBoxItem("gui.setting.pole.toggle", defaultSettings.usePole > 0, function(isChecked)
            Clientsetting.refreshPoleControlState(isChecked and 1.0 or 0)
            Lib.emitEvent(Event.EVENT_SWITCH_MOVE_CONTROL, isChecked and 1.0 or 0)
        end)
    end

    if pSett.jumpSneakState == nil or pSett.jumpSneakState then
        self:createGameSettingCheckBoxItem("gui.setting.jump.sneak.toggle", defaultSettings.isJumpDefault > 0, function(isChecked)
            Clientsetting.refreshJumpSneakState(isChecked and 1.0 or 0)
            Lib.emitEvent(Event.EVENT_CHECKBOX_CHANGE, isChecked)
        end)
    end

    if pSett.imageQuality == nil or pSett.imageQuality then
        self:createGameQualitySettingItem("gui.setting.gui.quality", defaultSettings.saveQualityLeve or World.cfg.defaultQualityLevel or 1)
    end
end

function M:createGameSettingSilderItem(nameKey, defaltVal, handler)
    local settingItem = UI:openWidget("game_setting_item", "_layouts_", nameKey, true)
    local slider = settingItem.GameSettingItem_Item.GameSettingItem_Slider
    slider:setCurrentValue(defaltVal)
    handler(slider:getCurrentValue())

    local function update()
        local progress = slider:getCurrentValue()
        if progress > 0.9 then
            progress = 1.0
        elseif progress < 0.1 then
            progress = 0
        end
        handler(progress)
    end
    slider.onSliderValueChanged = update
    -- slider.onMouseMove = update
    -- slider.onMouseButtonUp = update
    self.gameSettingGrid:addChild(settingItem:getWindow())
end

function M:createGameSettingCheckBoxItem(nameKey, defaltVal, handler)
    local settingItem = UI:openWidget("game_setting_item", "_layouts_", nameKey, false)
    local checkBox = settingItem.GameSettingItem_Item.GameSettingItem_CheckBox
    checkBox:setSelected(defaltVal)
    checkBox.onSelectStateChanged = function ()
        handler(checkBox:isSelected())
    end
    self.gameSettingGrid:addChild(settingItem:getWindow())
end

function M:createGameQualitySettingItem(nameKey, defaltVal)
    local settingItem = UI:openWidget("game_setting_item", "_layouts_", nameKey, true)
    local quality = settingItem.GameSettingItem_Item.GameSettingItem_Slider

    quality.GameSettingItem_Low:setText(Lang:toText("gui.setting.gui.quality.low"))
    quality.GameSettingItem_Low:setVisible(true)

    quality.GameSettingItem_High:setText(Lang:toText("gui.setting.gui.quality.high"))
    quality.GameSettingItem_High:setVisible(true)

    

    local function handleQualityLevel(level)
        if 1 <= level and level <= 3 then
            quality:setCurrentValue(0.5 * (level - 1))
            self:gameSettingSetQualityLevel(level)
        end
    end
    handleQualityLevel(defaltVal)

    local function handleQualityProgress()
        local value = quality:getCurrentValue()
        if 0 <= value and value <= 1 then
            value = math.max(1, math.ceil(value * 3))
            handleQualityLevel(value)
            Lib.emitEvent(Event.EVENT_SETTING_TO_TOOLBAR_QUALITY, value)
        end
    end
    quality.onSliderValueChanged = handleQualityProgress
    -- quality.onMouseMove = handleQualityProgress
    Lib.subscribeEvent(Event.EVENT_TOOLBAR_TO_SETTING_QUALITY, handleQualityLevel)
    self.gameSettingGrid:addChild(settingItem:getWindow())
end

function M:gameSettingSetQualityLevel(level)
    -----1  2 
    local values = {
        {0, 0},
        {1, 1},
        {2, 2},
    }
    local tab = values[level]       
	Blockman.instance.gameSettings:setCurQualityLevel(tab[1])
    Clientsetting.refreshSaveQualityLeve(level)
end
