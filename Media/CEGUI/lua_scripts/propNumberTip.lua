local setting = require "common.setting"
function M:onOpen(params)
    local Condition = World.cfg.gameOverCondition
    local PCCondition = World.cfg.pcGameOverCondition
    local text = self:child("Text")
    local icon = self:child("icon")
    local iconImage
    if Condition then
        iconImage = Condition.propsCollection.propCfg.icon
    elseif PCCondition then
        local collectConfig = PCCondition.collectConfig
        if collectConfig then
            local cfg = setting:fetch(collectConfig.collectType or "item", collectConfig.fullName)
            iconImage = cfg.icon or cfg.image or cfg.iconImage
            if not iconImage and collectConfig.type == "block" then
                iconImage = "block:"..collectConfig.fullName
            end
        end
    end
    if iconImage and iconImage:find("block:") then
        -- 暂时先再load一次解决方块图片因为没有生成方块而不显示的问题
        GUILib.loadImage(iconImage)
    end
    if iconImage and iconImage ~= "" then
        World.Timer(10, function ()
            icon:setImage(GUILib.loadImage(iconImage))
        end)
    end
    local number = params and params.propNumberText or 0
    text:setText(number)
end
