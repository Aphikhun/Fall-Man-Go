
function self:setSelect(select)
    self.CellImage:setVisible(select)
end

function self:setTextColor(color)
    self.Text:setProperty("TextColours", color)
end

function self:setText(text)
    self.Text:setText(text)
end

function self:setClickCallBack(callback)
    self.clickCallBackFunc = callback
end

function self:init()
    self.CellImage:setMousePassThroughEnabled(true)
    self.Text:setMousePassThroughEnabled(true)
    self.clickCallBackFunc = false
    self.BG.onMouseClick = function()
        if self.clickCallBackFunc then
            self.clickCallBackFunc()
        end
    end
end

self:init()
-- print("rolePanelCell startup ui")