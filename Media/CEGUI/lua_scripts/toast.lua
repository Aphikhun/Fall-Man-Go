local defaultTime = 40

function M:onOpen()
    self.isOpen = true
    self:init()
end

function M:onClose()
    self.isOpen = false
end

function M:init()
    self.toastLayout = self:child("Edit_Toaster")
    self.toastText = self:child("Edit_Toast_Tip_Text")
end

local function resetToast(self)
    if not self.isOpen then
        return false
    end
    self.toastLayout:setVisible(false)
    self:close()
    self.isOpen = false
end

local function toastDisappearAct(self, time, delayCloseTime)
    -- toastUI的缓动动画，向上移动且缓慢透明  等引擎新UI的动画系统做出来后再进行更换
    local function task(offset)
        self.toastLayout:setYPosition({0, -(offset * 6)})
    end
    local function closeTimer()
        if not delayCloseTime then
            resetToast(self)
            return 
        end
        local closeTimerCount = 1
        World.Timer(1, function ()
            closeTimerCount = closeTimerCount + 1
            if closeTimerCount >= delayCloseTime then
                resetToast(self)
                return false
            end
            return true
        end)
    end
    local count = 0
    World.Timer(1, function ()
        if not self.isOpen then
            return false
        end
        count = count + 1
        if count >= (time or defaultTime) then
            closeTimer()
            return false
        else
            task(count)
            return true
        end
    end)
end

function M:setToast(text, time, delayCloseTime, originalText)
    if not self.isOpen then
        return false
    end
    self.toastText:setProperty("TextColours","ffffffff")
    local width = self.toastText:getFont():getTextExtent(originalText and originalText or text,1) + 140
    self.toastLayout:setWidth({0 , width })
    text = "[colour='FF3C4657']" .. text
    self.toastText:setText(text)
    self.toastLayout:setVisible(true)
    toastDisappearAct(self, time, delayCloseTime)
end