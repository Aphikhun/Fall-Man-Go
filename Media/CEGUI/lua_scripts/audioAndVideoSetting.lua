local function saveAudioData()
  M.settingConfig.audioData = Lib.copy(M.audioData)
end

local function saveVideoData()
  M.settingConfig.videoData = Lib.copy(M.videoData)
end

local function saveData()
  saveAudioData()
  saveVideoData()
end

local function loadAudioData()
  M.audioData = {}
  local bgmData = {}
  local bgmConfigData = M.settingConfig.audioData and M.settingConfig.audioData["bgm"] or {}
  bgmData.enable = bgmConfigData.enable ~= false
  bgmData.volume = bgmConfigData.volume or 0
  M.audioData["bgm"] = bgmData

  local effectData = {}
  local effectConfigData = M.settingConfig.audioData and M.settingConfig.audioData["effect"] or {}
  effectData.enable = effectConfigData.enable ~= false
  effectData.volume = effectConfigData.volume or 0
  M.audioData["effect"] = effectData
end

local function loadVideoData()
  M.videoData = {}
  local videoConfigData = M.settingConfig.videoData or {}
  M.videoData.qualityLevel = videoConfigData.qualityLevel or World.cfg.defaultQualityLevel or 0
  Blockman.instance.gameSettings:setCurQualityLevel(M.videoData.qualityLevel)
end

local function loadData()
  loadAudioData()
  loadVideoData()
  saveData()
end

function M:initAudioUI()
  local audio = M.audio
  audio.audioTab.Image = "setting/bg_BiaoTi"
  audio.audioTab.setting:setText(Lang:toText("setting.audioAndVideoSetting.audioTab"))
  audio.music.desc:setText(Lang:toText("setting.audioAndVideoSetting.music.desc"))
  audio.effect.desc:setText(Lang:toText("setting.audioAndVideoSetting.effect.desc"))
  local bgmSlider = M.audio.music.Slider
  local bgmCheckbox = M.audio.music.Checkbox
  bgmSlider.TopImageStretch = "1 0 1 0"
  bgmCheckbox.selectableImage = "setting/KaiGuan_Kai"
  bgmCheckbox.unselectableImage = "setting/KaiGuan_Guan"

  local effectSlider = M.audio.effect.Slider
  local effectCheckbox = M.audio.effect.Checkbox
  effectSlider.TopImageStretch = "1 0 1 0"
  effectCheckbox.selectableImage = "setting/KaiGuan_Kai"
  effectCheckbox.unselectableImage = "setting/KaiGuan_Guan"
end

function M:initVideoUI()
  local video= M.video
  video.videoTab.setting:setText(Lang:toText("setting.audioAndVideoSetting.videoTab"))
  video.videoTab.Image = "setting/bg_BiaoTi"

  video.lowQualityRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  video.lowQualityRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  video.lowQualityRadioButton.Image:setImage("setting/DuiGou")
  video.lowQualityRadioButton.Text:setText(Lang:toText("setting.audioAndVideoSetting.lowQuality"))

  video.midQualityRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  video.midQualityRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  video.midQualityRadioButton.Image:setImage("setting/DuiGou")
  video.midQualityRadioButton.Text:setText(Lang:toText("setting.audioAndVideoSetting.midQuality"))

  video.highQualityRadioButton.selectableImage = "setting/DuiGou_DiKuang"
  video.highQualityRadioButton.unselectableImage = "setting/DuiGou_DiKuang"
  video.highQualityRadioButton.Image:setImage("setting/DuiGou")
  video.highQualityRadioButton.Text:setText(Lang:toText("setting.audioAndVideoSetting.highQuality"))
end

function M:init()
  loadData()
  M:initAudioUI()
  M:initVideoUI()
  M:updateView()
end

function M:onOpen(instance, settingConfigManager)
  M.settingConfig = settingConfigManager:getGlobalConfig("audioAndVideoSetting")
  M:init()
end

function M:setQualityLevel(level)
  M.videoData.qualityLevel = level
  Blockman.instance.gameSettings:setCurQualityLevel(level)
  saveVideoData()
end

function M.video.lowQualityRadioButton:onSelectStateChanged()
  if not self:isVisible() then
    return
  end
  if M.video.lowQualityRadioButton:isSelected() then
      M:setQualityLevel(0)
      self.Image:setVisible(true)
  else
      self.Image:setVisible(false)
  end
end

function M.video.midQualityRadioButton:onSelectStateChanged()
  if not self:isVisible() then
    return
  end
  if M.video.midQualityRadioButton:isSelected() then
      M:setQualityLevel(1)
      self.Image:setVisible(true)
  else
      self.Image:setVisible(false)
  end
end

function M.video.highQualityRadioButton:onSelectStateChanged()
  if not self:isVisible() then
    return
  end
  if M.video.highQualityRadioButton:isSelected() then
      M:setQualityLevel(2)
      self.Image:setVisible(true)
  else
      self.Image:setVisible(false)
  end
end

function M.audio.music.Checkbox:onSelectStateChanged(instance)
  local type = 0
  local data = M.audioData["bgm"]
  data.enable = instance:isSelected()
  saveAudioData()
  TdAudioEngine.Instance():mute(type, not data.enable)
  M:updateAudioView(type, true)
end

function M.audio.effect.Checkbox:onSelectStateChanged(instance)
  local type = 1
  local data = M.audioData["effect"]
  data.enable = instance:isSelected()
  saveAudioData()
  TdAudioEngine.Instance():mute(type, not data.enable)
  M:updateAudioView(type, true)
end

function M.audio.music.Slider:onSliderValueChanged(instance)
  local bgmData = M.audioData["bgm"]
  local volume = instance:getCurrentValue() / 100
  TdAudioEngine.Instance():setBgmVolume(volume)
  bgmData.volume = volume
  saveAudioData()
end

function M.audio.effect.Slider:onSliderValueChanged(instance)
  local effectData = M.audioData["effect"]
  local volume = instance:getCurrentValue() / 100
  TdAudioEngine.Instance():setEffectVolume(volume)
  effectData.volume = volume
  saveAudioData()
end

function M:updateAudioView(type, triggerByCheckbox)
  local data
  local Audio
  if type == 0 then
    Audio = M.audio:child("music")
    data = M.audioData["bgm"]
  elseif type == 1 then
    Audio = M.audio:child("effect")
    data = M.audioData["effect"]
  end
  local Slider = Audio:child("Slider")
  local Thumb = Slider:getThumb()
  local Checkbox = Audio:child("Checkbox")
  local enable = data.enable
  if enable then
    Slider.slider_bg = "setting/HuaGan_Xia"
    Slider.slider_top = "setting/HuaGan_Shang"
    Thumb:setProperty("thumb_image", "setting/HuaGan_KongZhiHuaGan")
  else
    Slider.slider_bg = "setting/HuaGan_Xia_Hui"
    Slider.slider_top = "setting/HuaGan_Shang_Hui"
    Thumb:setProperty("thumb_image", "setting/HuaGan_KongZhiHuaGan_Hui")
  end

  if not triggerByCheckbox then
    Checkbox:setSelected(enable)
  end
  Slider:setEnabled(enable)
  Slider:setCurrentValue(data.volume*100)
end

function M:updateData()
  local bgmData = M.audioData["bgm"]
  local effectData = M.audioData["effect"]
  local videoData = M.videoData
  TdAudioEngine.Instance():getBgmVolume(function(volume)
    bgmData.volume = volume
    M:updateAudioView(0)
    saveData()
  end)
  TdAudioEngine.Instance():getMute(0, function(isMute)
    bgmData.enable = not isMute
    M:updateAudioView(0)
    saveData()
  end)

  TdAudioEngine.Instance():getEffectVolume(function(volume)
    effectData.volume = volume
    M:updateAudioView(1)
    saveData()
  end)
  TdAudioEngine.Instance():getMute(1, function(isMute)
    effectData.enable = not isMute
    M:updateAudioView(1)
    saveData()
  end)
  videoData.qualityLevel = Blockman.instance.gameSettings:getCurQualityLevel()
  M:updateVideoView()
  saveData()
end

function M:onShown()
  M:updateView(true)
end

function M:updateVideoView()
  local videoData = M.videoData
  local curQualityLevel = videoData.qualityLevel
  local RadioButton
  if curQualityLevel == 0 then
    RadioButton = M.video.lowQualityRadioButton
  elseif curQualityLevel == 1 then
    RadioButton = M.video.midQualityRadioButton
  elseif curQualityLevel == 2 then
    RadioButton = M.video.highQualityRadioButton
  end
  RadioButton:setSelected(true)
end

function M:updateView(updateData)
  if updateData then
    M:updateData()
    return 
  end
  M:updateAudioView(0)
  M:updateAudioView(1)
  M:updateVideoView()
end