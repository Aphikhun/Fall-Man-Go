function self:init()
    self.callback = false

    self.Sure.onMouseClick = function()
        if not self.callback then
            return
        end
        self.callback(tonumber(self.Input:getProperty("Text")))
    end
end

function self:setSureButtonCallback(cb)
    self.callback = cb
end

function self:setItemInputText(text)
    self.Input:setProperty("Text", text)
end

function self:setItemName(name)
    self.Text:setProperty("Text", name)
end

function self:setItemImage(image)
    self.ItemImage:setImage(image)
end

self:init()