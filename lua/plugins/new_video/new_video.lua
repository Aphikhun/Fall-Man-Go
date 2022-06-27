
require "common.event_new_video"
require "common.config.video_effect_config"

if World.isClient then
    require "client.gm_new_video"
    local Recorder = T(Lib, "Recorder")
    Recorder:LoadConfigFromJson()
end

local handlers = {}

if World.isClient then
    function handlers.updateNewVideoShow(isShow)
        if World.cfg.useNewUI then
            if isShow then
                UI:openWindow("UI/new_video/gui/win_video_mode")
            else
                UI:closeWindow("UI/new_video/gui/win_video_mode")
            end
        else
            if isShow then
                UI:openWnd("videoMode")
            else
                UI:closeWnd("videoMode")
            end
        end
    end
end

return function(name, ...)
    if type(handlers[name]) ~= "function" then
        return
    end
    return handlers[name](...)
end