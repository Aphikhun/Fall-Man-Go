function M:onOpen()
    self:init()
end

function M:init()
    self.MsgText:setText(Lang:toText("gui_menu_exit_game"))
    self.Okay:setText(Lang:toText("gui_menu_exit_game_sure"))
    self.Cancel:setText(Lang:toText("gui_menu_exit_game_cancel"))

    self.Okay.onMouseClick = function()
        if World.CurWorld.isEditorEnvironment then
            EditorModule:emitEvent("enterEditorMode")
        else
            CGame.instance:exitGame()
        end
    end

    self.Cancel.onMouseClick = function()
        UI:closeWindow(self)
    end
end
