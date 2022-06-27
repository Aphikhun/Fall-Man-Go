M.viewOptions = {
    [0] = "firstPersonView",
    [1] = "thridPersonView",
    [2] = "thirdPersonPositiveView",
    [3] = "flexibleView",
    [4] = "fixedView",
}

M.viewDatas = {}
M.sensitiveDatas = {
    lowerBound = 4,
    upperBound = 10,
}

function M:loadFovAngleData()
    local cameraCfg = World.cfg.cameraCfg
    local isPhoneEditorCfg =  cameraCfg and cameraCfg.selectViewBtn
    local optionalViewIdxs = {}
    if isPhoneEditorCfg then
        if cameraCfg.canSwitchView then
            optionalViewIdxs[0] = true
            optionalViewIdxs[1] = true
        else
            optionalViewIdxs[3] = true
        end
    else -- PC Editor Cfg
        for idx, _ in pairs(M.viewOptions) do
            local viewCfg = Blockman.instance:getCameraInfo(idx).viewCfg
            if viewCfg.enable then
                optionalViewIdxs[idx] = true
            end
        end
    end

    for idx, name in pairs(M.viewOptions) do
        local viewCfg = Blockman.instance:getCameraInfo(idx).viewCfg
        local enable = optionalViewIdxs[idx]
        if not enable then
            local window = M.ScrollableView.GridView:child(name)
            M.ScrollableView.GridView:removeChild(window.__window)
        else
            local viewData = {}
            M.viewDatas[idx] = viewData
            viewData.lowerBound = math.floor(viewCfg.viewFovAngle * 0.5)
            viewData.lowerBound = viewData.lowerBound < 0 and 0 or viewData.lowerBound
            viewData.upperBound = math.floor(viewCfg.viewFovAngle * 1.5)
            viewData.upperBound = viewData.upperBound > 180 and 180 or viewData.upperBound
            viewData.viewFovAngle = viewCfg.viewFovAngle
            viewData.fovAngleRange = viewData.upperBound - viewData.lowerBound
            viewData.viewCfg = viewCfg

            local settingConfig = M.settingConfig.viewDatas
            for key, val in pairs(settingConfig and settingConfig[tostring(idx)] or {}) do
                viewData[key] = val
            end
        end
    end
end

function M:loadSensitiveData()
    M.sensitiveDatas.range = M.sensitiveDatas.upperBound - M.sensitiveDatas.lowerBound
    local sensitive = Blockman.instance.gameSettings:getCameraSensitive()
    local settingConfig = M.settingConfig.sensitiveDatas
    for view, _ in pairs(M.viewDatas) do
        local sensitiveData = {}
        M.sensitiveDatas[view] = sensitiveData
        sensitiveData.sensitive = sensitive * 10
        for key, val in pairs(settingConfig and settingConfig[view] or {}) do
            sensitiveData[key] = val
        end
    end
end

function M:loadPersonView()
    local curPersonView = Blockman.instance:getPersonView()
    if M.settingConfig.curPersonView and M.viewDatas[M.settingConfig.curPersonView] then
        curPersonView = M.settingConfig.curPersonView
    end
    M.curPersonView = curPersonView
end

local function saveFovAngleData()
    local savedDatas = {}
    for view, data in pairs(M.viewDatas) do
        local fovAngleData = {}
        fovAngleData.viewFovAngle = data.viewFovAngle
        savedDatas[view] = fovAngleData
    end
    M.settingConfig.viewDatas = savedDatas
end

local function saveSensitiveData()
    local savedDatas = {}
    for view, _ in pairs(M.viewDatas) do
        local data = M.sensitiveDatas[view]
        local sensitiveData = {}
        sensitiveData.sensitive = data.sensitive
        savedDatas[view] = sensitiveData
    end
    M.settingConfig.sensitiveDatas = savedDatas
end

local function savePersonView()
    M.settingConfig.curPersonView = M.curPersonView
end

local function saveData()
    savePersonView()
    saveFovAngleData()
    saveSensitiveData()
end

local function loadData()
    M:loadFovAngleData()
    M:loadSensitiveData()
    M:loadPersonView()
    saveData()
end

function M:onOpen(instance, settingConfigManager)
    M.settingConfig = settingConfigManager:getSpecialGameConfig(World.GameName, "cameraSetting")
    loadData()
    M:init()
    M:updateView()
end

function M:setPersonView(view)
    if view  == M.curPersonView then
        return
    end
    M.prePersonView = M.curPersonView
    M.curPersonView = view
    Blockman.instance:setPersonView(view)
    savePersonView()
    M:updateCameraView()
    M:updateFovView()
    M:updateSensitiveView()
end

function M.ScrollableView.GridView.firstPersonView.BottomFrame:onMouseClick(instance)
    M:setPersonView(0)
end

function M.ScrollableView.GridView.thridPersonView.BottomFrame:onMouseClick(instance)
    M:setPersonView(1)
end

function M.ScrollableView.GridView.thirdPersonPositiveView.BottomFrame:onMouseClick(instance)
    M:setPersonView(2)
end

function M.ScrollableView.GridView.flexibleView.BottomFrame:onMouseClick(instance)
    M:setPersonView(3)
end

function M.ScrollableView.GridView.fixedView.BottomFrame:onMouseClick(instance)
    M:setPersonView(4)
end


function M.ScrollableView.VerticalLayout.fovLayout.layout.Slider:onSliderValueChanged(instance)
    local fovLayout = M.ScrollableView.VerticalLayout.fovLayout.layout
    local viewData = M.viewDatas[M.curPersonView]
    local sliderVal = fovLayout.Slider:getCurrentValue()
    viewData.viewFovAngle = sliderVal * viewData.fovAngleRange + viewData.lowerBound
    Blockman.instance:setViewFovAngle(math.floor(viewData.viewFovAngle))
    saveFovAngleData()
    M:updateFovView(true)
end

function M.ScrollableView.VerticalLayout.sensitiveLayout.layout.Slider:onSliderValueChanged(instance)
    local sensitiveLayout = M.ScrollableView.VerticalLayout.sensitiveLayout.layout
    local sensitiveData = M.sensitiveDatas[M.curPersonView]
    local sliderVal = sensitiveLayout.Slider:getCurrentValue()
    sensitiveData.sensitive = sliderVal * M.sensitiveDatas.range + M.sensitiveDatas.lowerBound
    local sensitive = sensitiveData.sensitive / 10
    Blockman.instance.gameSettings:setCameraSensitive(sensitive)
    saveSensitiveData()
    M:updateSensitiveView(true)
end

function M:initGridViewUI()
    local gridView = M.ScrollableView.GridView
    local firstPersonView = gridView.firstPersonView
    if firstPersonView then
        firstPersonView.Text:setText(Lang:toText("setting.cameraSetting.firstPersonView"))
        firstPersonView.BottomFrame:setImage("setting/DuiGou_DiKuang")
        firstPersonView.TickImage:setImage("setting/DuiGou")
        firstPersonView.Image:setImage("setting/DiYiRenCheng")
    end


    local thridPersonView = gridView.thridPersonView
    if thridPersonView then
        thridPersonView.Text:setText(Lang:toText("setting.cameraSetting.thridPersonView"))
        thridPersonView.BottomFrame:setImage("setting/DuiGou_DiKuang")
        thridPersonView.TickImage:setImage("setting/DuiGou")
        thridPersonView.Image:setImage("setting/DiSanRenCheng")
    end

    local thirdPersonPositiveView = gridView.thirdPersonPositiveView
    if thirdPersonPositiveView then
        thirdPersonPositiveView.Text:setText(Lang:toText("setting.cameraSetting.thirdPersonPositiveView"))
        thirdPersonPositiveView.BottomFrame:setImage("setting/DuiGou_DiKuang")
        thirdPersonPositiveView.TickImage:setImage("setting/DuiGou")
        thirdPersonPositiveView.Image:setImage("setting/ZhengShiJiao")
    end

    local fixedView = gridView.fixedView
    if fixedView then
        fixedView.Text:setText(Lang:toText("setting.cameraSetting.fixedView"))
        fixedView.BottomFrame:setImage("setting/DuiGou_DiKuang")
        fixedView.TickImage:setImage("setting/DuiGou")
        fixedView.Image:setImage("setting/GuDingShiJiao")
    end

    local flexibleView = gridView.flexibleView
    if flexibleView then
        flexibleView.Text:setText(Lang:toText("setting.cameraSetting.flexibleView"))
        flexibleView.BottomFrame:setImage("setting/DuiGou_DiKuang")
        flexibleView.TickImage:setImage("setting/DuiGou")
        flexibleView.Image:setImage("setting/LingHuoShiJiao")
    end
end
function M:initCameraViewUI()
    M.ScrollableView.cameraTab.setting:setText(Lang:toText("setting.cameraSetting.cameraTab"))
    M.ScrollableView.cameraTab:setImage("setting/bg_BiaoTi")
    local vscrollbar = M.ScrollableView.__auto_vscrollbar__
    vscrollbar:setProperty("background", "setting/HuaDongTiao_DiBu")
    vscrollbar.__auto_thumb__:setProperty("thumb_image", "setting/HuaDongTiao_ShangBu")
    M:initGridViewUI()
end

function M:initFovUI()
    local fovLayout = M.ScrollableView.VerticalLayout.fovLayout
    local layout = fovLayout.layout
    fovLayout.Tab.setting:setText(Lang:toText("setting.cameraSetting.fovLayout.tab"))
    fovLayout.Tab:setImage("setting/bg_BiaoTi")
    layout.desc:setText(Lang:toText("setting.cameraSetting.fovLayout.desc"))
    layout.min:setText(Lang:toText("setting.cameraSetting.fovLayout.min"))
    layout.max:setText(Lang:toText("setting.cameraSetting.fovLayout.max"))
    local Slider = layout.Slider
    Slider.slider_bg = "setting/HuaGan_Xia"
    Slider.slider_top = "setting/HuaGan_Shang"
    Slider.TopImageStretch = "1 0 1 0"
    local thumb = Slider:getThumb()
    thumb:setProperty("thumb_image", "setting/HuaGan_KongZhiHuaGan")
end

function M:initSensitiveUI()
    local sensitiveLayout = M.ScrollableView.VerticalLayout.sensitiveLayout
    local layout = sensitiveLayout.layout
    sensitiveLayout.Tab.setting:setText(Lang:toText("setting.cameraSetting.sensitiveLayout.tab"))
    sensitiveLayout.Tab:setImage("setting/bg_BiaoTi")
    layout.desc:setText(Lang:toText("setting.cameraSetting.sensitiveLayout.desc"))
    layout.min:setText(Lang:toText("setting.cameraSetting.sensitiveLayout.min"))
    layout.max:setText(Lang:toText("setting.cameraSetting.sensitiveLayout.max"))
    local Slider = layout.Slider
    Slider.slider_bg = "setting/HuaGan_Xia"
    Slider.slider_top = "setting/HuaGan_Shang"
    Slider.TopImageStretch = "1 0 1 0"
    local thumb = Slider:getThumb()
    thumb:setProperty("thumb_image", "setting/HuaGan_KongZhiHuaGan")
end


function M:init()
    M:initCameraViewUI()
    M:initFovUI()
    M:initSensitiveUI()

    Blockman.instance:setPersonView(M.curPersonView)

    local viewData = M.viewDatas[M.curPersonView]
    Blockman.instance:setViewFovAngle(math.floor(viewData.viewFovAngle))

    local sensitiveData = M.sensitiveDatas[M.curPersonView]
    local sensitive = sensitiveData.sensitive / 10
    Blockman.instance.gameSettings:setCameraSensitive(sensitive)
end

function M:onShown()
    World.Timer(1, function()
        local GridView = M.ScrollableView.GridView
        local yPos = GridView:getYPosition()
        local size = GridView:getPixelSize()
        local interval = 20
        local offset = yPos[2] + interval + size.height
        M.ScrollableView.VerticalLayout:setYPosition(UDim.new(yPos[0], offset))
    end)
    M:updateView(true)
end

function M:updateData()
    M:setPersonView(Blockman.instance:getPersonView())
    local viewData = M.viewDatas[M.curPersonView]
    local sensitiveData = M.sensitiveDatas[M.curPersonView]
    viewData.viewFovAngle = Blockman.instance:getViewFovAngle()
    local sensitive = Blockman.instance.gameSettings:getCameraSensitive()
    sensitiveData.sensitive = sensitive * 10
    saveData()
end

function M:updateCameraView()
    if M.prePersonView then
        local preWindowName = M.viewOptions[M.prePersonView]
        local preWindow = M.ScrollableView.GridView:child(preWindowName)
        preWindow.TickImage:setVisible(false)
    end

    local curWindowName = M.viewOptions[M.curPersonView]
    local curWindow = M.ScrollableView.GridView:child(curWindowName)
    curWindow.TickImage:setVisible(true)

    local canSwitchView = Blockman.instance:getCanSwitchView()
    if M.canSwitchView ~= canSwitchView then
        for idx, _ in pairs(M.viewDatas) do
            local name = M.viewOptions[idx]
            local window = M.ScrollableView.GridView:child(name):child("BottomFrame")
            window:setEnabled(canSwitchView)
        end
        M.canSwitchView = canSwitchView
    end
end

function M:updateFovView(triggerBySlider)
    local viewData = M.viewDatas[M.curPersonView]
    local fovLayout = M.ScrollableView.VerticalLayout.fovLayout.layout
    local curValText = string.format("x%.2f", viewData.viewFovAngle / viewData.viewCfg.viewFovAngle)
    fovLayout.curValue:setText(curValText)
    if not triggerBySlider then
        local sliderVal = (viewData.viewFovAngle - viewData.lowerBound) / viewData.fovAngleRange
        fovLayout.Slider:setCurrentValue(sliderVal)
    end
end

function M:updateSensitiveView(triggerBySlider)
    local sensitiveLayout = M.ScrollableView.VerticalLayout.sensitiveLayout.layout
    local sensitiveData = M.sensitiveDatas[M.curPersonView]
    local curValText = string.format("%.1f", sensitiveData.sensitive)
    sensitiveLayout.curValue:setText(curValText)
    if not triggerBySlider then
        local sensitiveSliderVal = (sensitiveData.sensitive - M.sensitiveDatas.lowerBound) / M.sensitiveDatas.range
        sensitiveLayout.Slider:setCurrentValue(sensitiveSliderVal)
    end
end

function M:updateView(updateData)
    if updateData then
        M:updateData()
    end

    M:updateCameraView()
    M:updateFovView()
    M:updateSensitiveView()
end