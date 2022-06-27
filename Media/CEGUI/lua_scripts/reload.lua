function M:onOpen()
    self:init()
end

function M:init()
    self.image = self:child("Reload_Image")
    self.cdMaskWnd = false
    self.shortcutBar = false
    Lib.subscribeEvent(Event.EVENT_SHOW_RELOAD_PROGRESS, function(packet)
        local cfg = packet.cfg
        local reloadTime = cfg.reloadTime or 20
        if reloadTime <= 0 then
            return
        end
        if packet.method ~= "Cancel" then
            self.image:setVisible(true)
            local pro = cfg.progress or {}
            if not self.cdMaskWnd then
                local packet = {
                    beginTime = 1, 
                    endTime = reloadTime, 
                    imageConfig = {
                        leftImage = {name = "attack_effect/reload_left"},
                        rightImage = {name = "attack_effect/reload_right"},
                        resourceGroup = "_imagesets_",
                        scale = 0.5
                    },
                    type = pro.type
                }
                self.cdMaskWnd = UI:openSystemWindow("progressMask", nil, packet)
            else
                self.cdMaskWnd:onReopen({beginTime = 1, endTime = reloadTime})
            end
            local isChild = self.image:isChildName("progressMask")
            if not isChild then
                self.image:addChild(self.cdMaskWnd:getWindow())
            end
            self.shortcutBar = UI:getWindow("shortcutBar")
            self.shortcutBar:setEnabled(false)
            self:closeProgressMask(reloadTime)
        end
    end)
end

function M:closeProgressMask(reloadTime)
    World.Timer(reloadTime, function()
        if self.cdMaskWnd then
            self.cdMaskWnd:resetWnd()
        end
        self.shortcutBar:setEnabled(true)
        self.image:setVisible(false)
    end)
end

return M