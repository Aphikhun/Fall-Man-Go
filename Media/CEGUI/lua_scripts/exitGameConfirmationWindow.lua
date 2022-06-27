function M:onOpen()
    M:init()
end

function M:init()
    M:setAlwaysOnTop(true)
    M.Text:setText(Lang:toText("gui_menu_exit_game"))
    M.YesImage:setImage("setting/icon_YES")
    M.NoImage:setImage("setting/icon_NO")
    M.BgImage:setImage("setting/bg_TanChuang")
end

function M.YesImage:onMouseClick()
    if World.CurWorld.isEditorEnvironment then
        EditorModule:emitEvent("enterEditorMode")
    else
        CGame.instance:exitGame()
    end
end

function M.NoImage:onMouseClick()
    M:setVisible(false)
end