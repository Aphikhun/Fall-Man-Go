require "common.entity"
local MAX_ANSWER = 4
local FRIST_PAGE = 1
local OPTION_LIMIT = 1
local talkType = {
    TALK = 0,
    CHOICE = 1,
}
local hasAddOption = false

local function updateTalk(self)
    local nextText = self._maxPage == self._curPage and "gui.conversation.finish" or "gui.conversation.next"
    self.nextBtn:setText(Lang:toText(nextText))
    self.contentText:setText(Lang:toText(self._talkList[self._curPage].msg))
    local npc = self._npcList[self._talkList[self._curPage].npc]
    local npcCfg = Entity.GetCfg(npc)
	local name = npcCfg.deputyName or npcCfg.name
    self.nameText:setText(Lang:toText(name))
    if npcCfg.headPic and npcCfg.headPic ~= "" then
        local image = GUILib.loadImage(npcCfg.headPic, npcCfg)
        self.headImage:setProperty("Image", image)
    end
end

local function updateChoice(self)
    
    local nextText = self._maxPage == self._curPage and "gui.conversation.ok" or "gui.conversation.next"
    self.nextBtn:setText(Lang:toText(nextText))
    self.contentText:setText("")
    local npc = self._npcList[self._optionNpc]
    local npcCfg = Entity.GetCfg(npc)
    self.nameText:setText(Lang:toText(npcCfg.name))
    if npcCfg.headPic and npcCfg.headPic ~= "" then
        local image = GUILib.loadImage(npcCfg.headPic, npcCfg)
        self.headImage:setProperty("Image", image)
    end

    local options = self._optionList
    if #options < OPTION_LIMIT then
        return
    end

    if not hasAddOption then
        local winName = "ConversationItem"
        local level = 0
        for i = 1, #options do
            local instanceName = winName .. i
            local optionUi = UI:openSystemWindowOnly(winName, instanceName)
            local x
            local y = {0, 76 * level}
            if i % 2 == 1 then
                x = {0, 0}
            else
                x = {0.6, 0}
                level = level + 1
            end

            optionUi:setArea2(x, y, {0.4, 0}, {0, 56})
            self.checkGridView:addChild(optionUi.__window)
            optionUi.onSelectStateChanged = function(optionUi)
                if optionUi:isSelected() then
                    self:selectOption(i)
                end
            end
            optionUi:setProperty("Font", "DroidSans-16")
            optionUi:setProperty("NormalTextColour", "ffffffff")
            optionUi:setProperty("PushedTextColour", "ffffffff")
            optionUi:setProperty("HoverTextColour", "ffffffff")
            optionUi:setText(Lang:toText(options[i].showText))
        end
        hasAddOption = true
    end
    self.checkGridView:setVisible(true)
end


local talkTypeF = {
    [talkType.TALK] = updateTalk,
    [talkType.CHOICE] = updateChoice
}

local function updateFunction(type, self)
    local f = talkTypeF[type]
    f(self)
end

function M:init()
    self:initUiName()
    self:registerEvent()

end

function M:initUiName()
    self.nextBtn = self.app_conversationBtn_next
    self.lastBtn = self.app_conversationBtn_back
    self.headImage = self.app_conversationBg.app_conversation2.app_conversationHeadPic
    self.nameText = self.app_conversationNameBG.app_conversationName
    self.contentText = self.app_conversationBg.app_conversationContentText
    self.checkGridView = self.app_conversationBg.app_conversationCheckGridView
    self.checkGridView:setVisible(true)
end

function M:registerEvent()
    self.nextBtn.onMouseClick = function()
        self:buttonNext()
    end
    self.lastBtn.onMouseClick = function()
        self:buttonLast()
    end

end

function M:sendAnswer()
    if self._selectResult <= 0 and #self._optionList >= OPTION_LIMIT then
        return false
    end

    if #self._optionList == 0 then
        return true
    end

    self._selectResult = self._selectResult > 0 and self._selectResult or 1
    Me:doCallBack("Conversation", self._selectResult , self._regId)
    return true
end

function M:hiheAllOption()
    self.checkGridView:setVisible(false)
end

function M:selectOption(index)
    self._selectResult = index
end

function M:buttonNext()
    self._curPage = self._curPage + 1
    if self._maxPage < self._curPage then
        local ret = not self._optionList or self:sendAnswer() 
        if ret then
            Lib.emitEvent(Event.EVENT_OPEN_CONVERSATION, false)
        end
        self._curPage = self._maxPage
        return
    end

    self:update()
end

function M:buttonLast()
    self._curPage = self._curPage - 1
    if self._curPage < FRIST_PAGE then
        return
    end
    self:hiheAllOption()
    self:update()
end

function M:update()
    local showType = talkType.TALK
    if self._curPage == self._maxPage and self._optionList and #self._optionList >= OPTION_LIMIT then
        showType = talkType.CHOICE
    elseif self._curPage > self._maxPage then
        return
    end
    self.lastBtn:setVisible(self._curPage ~= FRIST_PAGE)
    self.lastBtn:setText(Lang:toText("gui.conversation.back"))
    updateFunction(showType, self)
end

function M:onOpen(packet, ...)
    self._talkList = packet.talkList
    self._npcList = packet.npcList
    self._optionList = packet.optionList
    self._optionNpc = packet.optionNpc
    self._curPage = FRIST_PAGE
	self._regId = packet.regId
    self._selectResult = -1
    self._maxPage = self._optionList and #self._optionList >= OPTION_LIMIT  and #self._talkList + 1 or #self._talkList
    self:hiheAllOption()    
    self:update()
    self._selectResult = -1
end

M:init()