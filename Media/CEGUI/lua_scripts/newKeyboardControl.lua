local Blockmaninstance = L("Blockmaninstance", Blockman.instance)

local DirectionButtonInfoMap = {
    ["key.forward"] =       { window = M.CenterTop, pressedImage = "actionControl/up_act", unpressedImage = "actionControl/up_nor"},
    ["key.back"] =          { window = M.CenterBottom, pressedImage = "actionControl/down_act", unpressedImage = "actionControl/down_nor"},
    ["key.left"] =          { window = M.LeftCenter, pressedImage = "actionControl/left_act", unpressedImage = "actionControl/left_nor"},
    ["key.right"] =         { window = M.RightCenter, pressedImage = "actionControl/right_act", unpressedImage = "actionControl/right_nor"},
    ["key.top.left"] =      { window = M.LeftTop, pressedImage = "actionControl/top-left_act", unpressedImage = "actionControl/top-left_nor"},
    ["key.top.right"] =     { window = M.RightTop, pressedImage = "actionControl/top-right_act", unpressedImage = "actionControl/top-right_nor"},
    ["key.bottom.left"] =   { window = M.LeftBottom, pressedImage = "actionControl/bottom-left_act", unpressedImage = "actionControl/bottom-left_nor"},
    ["key.bottom.right"] =  { window = M.RightBottom, pressedImage = "actionControl/bottom-right_act", unpressedImage = "actionControl/bottom-right_nor"},
}

function M:setKeyPressing(key, setting)
    if setting then
        if M.lastPressKey and M.lastPressKey ~= key then
            Blockmaninstance:setKeyPressing(M.lastPressKey, false)
            local info = DirectionButtonInfoMap[M.lastPressKey]
            if info then
                info.window.Image = info.unpressedImage
            end
        end
        M.lastPressKey = key

    end

    local info = DirectionButtonInfoMap[key]
    if info then
        info.window.Image = setting and info.pressedImage or info.unpressedImage
    end
    Blockmaninstance:setKeyPressing(key, setting)

end


function M:showNewActionControl(show)
    if not show and M.lastPressKey then
        Blockmaninstance:setKeyPressing(M.lastPressKey, false)
        M.lastPressKey = nil
    end

    if M.isShowingNewActionControl ~= show then
        M.LeftTop:setVisible(show)
        M.LeftTopTouch:setVisible(show)
        M.RightTop:setVisible(show)
        M.RightTopTouch:setVisible(show)
        M.LeftBottom:setVisible(show)
        M.LeftBottomTouch:setVisible(show)
        M.RightBottom:setVisible(show)
        M.RightBottomTouch:setVisible(show)
        M.isShowingNewActionControl = show
    end
end

M.CenterTop.onMouseButtonDown = function(instance, window, ...)
    M:setKeyPressing("key.forward", true)
    M:showNewActionControl(true)
    M.buttonDown = true
end
M.CenterTop.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then 
        return
    end
    M:setKeyPressing("key.forward", true)
    M:showNewActionControl(true)
end
M.CenterTop.onMouseButtonUp = function(instance, window, ...)
    M:setKeyPressing("key.forward", false)
    M:showNewActionControl(false)
    M.buttonDown = false
end

M.CenterBottom.onMouseButtonDown = function(instance, window, ...)
    M.buttonDown = true
    M:showNewActionControl(true)
    M:setKeyPressing("key.back", true)
end
M.CenterBottom.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:showNewActionControl(true)
    M:setKeyPressing("key.back", true)
end
M.CenterBottom.onMouseButtonUp = function(instance, window, ...)
    M:showNewActionControl(false)
    M.buttonDown = false
    M:setKeyPressing("key.back", false)
end

M.LeftCenter.onMouseButtonDown = function(instance, window, ...)
    M:showNewActionControl(true)
    M:setKeyPressing("key.left", true)
    M.buttonDown = true
end
M.LeftCenter.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:setKeyPressing("key.left", true)
    M:showNewActionControl(true)
end
M.LeftCenter.onMouseButtonUp = function(instance, window, ...)
    M:setKeyPressing("key.left", false)
    M:showNewActionControl(false)
    M.buttonDown = false
end

M.RightCenter.onMouseButtonDown = function(instance, window, ...)
    M:showNewActionControl(true)
    M:setKeyPressing("key.right", true)
    M.buttonDown = true
end
M.RightCenter.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:setKeyPressing("key.right", true)
    M:showNewActionControl(true)
end
M.RightCenter.onMouseButtonUp = function(instance, window, ...)
    M:showNewActionControl(false)
    M:setKeyPressing("key.right", false)
    M.buttonDown = false
end

M.LeftTopTouch.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:setKeyPressing("key.top.left", true)
    M:showNewActionControl(true)
end

M.RightTopTouch.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:showNewActionControl(true)
    M:setKeyPressing("key.top.right", true)
end

M.RightBottomTouch.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:setKeyPressing("key.bottom.right", true)
    M:showNewActionControl(true)
end

M.LeftBottomTouch.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    M:setKeyPressing("key.bottom.left", true)
    M:showNewActionControl(true)
end

M.Center.onMouseButtonDown = function(instance, window, ...)
    M.buttonDown = true
    M.lastPressKey = nil
end
M.Center.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    if M.lastPressKey and M.lastPressKey ~= "key.forward" then
        M:setKeyPressing(M.lastPressKey, false)
    end
    M:showNewActionControl(true)
end
M.Center.onMouseButtonUp = function(instance, window, ...)
    if M.lastPressKey then
        M:setKeyPressing(M.lastPressKey, false)
    end
    M.buttonDown = false
    M.lastPressKey = nil
    M:showNewActionControl(false)
end

M.InvalidArea.onMouseEntersArea = function(instance, window, ...)
    if not M.buttonDown then
        return
    end
    if M.lastPressKey then
        M:setKeyPressing(M.lastPressKey, false)
    end
    M:showNewActionControl(false)
    M.lastPressKey = nil
end

function M:onOpen()
    M:initUI()
end

function M:initUI()
    M.RightCenter.Image = "actionControl/right_nor"
    M.LeftCenter.Image = "actionControl/left_nor"
    M.CenterTop.Image = "actionControl/up_nor"
    M.CenterBottom.Image = "actionControl/down_nor"
    M.LeftBottom.Image = "actionControl/bottom-left_nor"
    M.RightBottom.Image = "actionControl/bottom-right_nor"
    M.LeftTop.Image = "actionControl/top-left_nor"
    M.RightTop.Image = "actionControl/top-right_nor"
end