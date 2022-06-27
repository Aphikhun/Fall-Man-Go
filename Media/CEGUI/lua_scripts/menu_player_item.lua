function M:onOpen(name, userId, super)
    self:init(name, userId, super)
end

function M:init(name, userId, super)
    self.MenuPlayerItem_Friend_Icon:setVisible(false)
    self.MenuPlayerItem_Name:setText(name)
    
    local btnAddFriend = self.MenuPlayerItem_Btn_Add_Friend
    btnAddFriend:setVisible(false)
    btnAddFriend:setText(Lang:toText("gui_player_list_item_add_friend"))
    btnAddFriend.onMouseClick = function (btnAddFriend)
        super:friendOpreation(userId, 2, btnAddFriend)
    end
    
    local btnIgnore = self.MenuPlayerItem_Btn_Neglect
    btnIgnore:setVisible(false)
    btnIgnore:setText(Lang:toText("gui_player_list_item_add_friend_btn_ignore"))

    local messageVies = self.MenuPlayerItem_Message
    messageVies:setVisible(false)
    messageVies:setText(Lang:toText("gui_player_list_item_add_friend_msg"))
    btnIgnore.onMouseClick = function (btnIgnore)
        super:friendOpreation(userId, 0, btnAddFriend, messageVies)
    end
    
    local btnAgree = self.MenuPlayerItem_Btn_Agree
    btnAgree:setVisible(false)
    btnAgree:setText(Lang:toText("gui_player_list_item_add_friend_btn_agree"))
    btnAgree.onMouseClick = function (btnAgree)
        super:friendOpreation(userId, 1, btnAddFriend)
    end
end
