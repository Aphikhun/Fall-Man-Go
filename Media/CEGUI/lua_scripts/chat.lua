local widget_virtual_vert_list = require "ui.widget.widget_virtual_vert_list"

local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())
local events = {}

local STATIC_TEXT_HEIGHT = 45

local function setVertScrollPosition()
	if self.messageView:getVirtualChildCount() > 4 then
		self.messageView:setVirtualBarPosition(1)
	end
end

local autoFoldInterval = 15 * 20
local autoFoldTimer

local function stopFoldTimer()
	if autoFoldTimer then
		autoFoldTimer()
		autoFoldTimer = nil
	end
end

local function autoFoldTimerFunc(self)
	stopFoldTimer()
	local time = 0
	autoFoldTimer = World.Timer(20, function ()
		time = time + 20
		if time >= autoFoldInterval then
			self:isFoldChat(true)
			return false
		end
		return true
	end)
end

local textNamecount = 0
function M:init()
    self.chatContent = self:child("Chat_Content")
    self.chatSendLayout = self:child("Chat_SendLayout")
	self.inputEditbox = self:child("Chat_SendLayout_Input_Btn")
	self.inputEditbox:setMaxTextLength(100)
    self.sendMsgBtn = self:child("Chat_SendLayout_SendMsg")
    self.chatContentBg = self:child("Chat_Content_Bg")
    self.chatContentMask = self:child("Chat_Content_Mask")
	self.offsetX = 0
	self.sendMsgBtn.onMouseClick = function ()
		self:sendChatMessage()
		autoFoldTimerFunc(self)
		self.inputEditbox:setTipText(Lang:toText("win.main.chat.clickSendMsg"))
	end

	self.inputEditbox.EventTextAccepted = function ()
		autoFoldTimerFunc(self)
	end

	self.chatSendLayout.onShown = function ()
		autoFoldTimerFunc(self)
	end
	
	self.chatContentMask.onMouseClick = function ()
		self:isFoldChat(false)
	end

	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_CHAT_MESSAGE, function(msg, fromname, type)
		self:showChatMessage(msg, fromname, type)
	end)

	local messageView = self:child("Chat_Content_ScrollableView")
	messageView:setShowVertScrollbar(true)
	local msgList = self:child("Chat_Content_MsgList")
	messageView.onMouseButtonUp = function ()
		autoFoldTimerFunc(self)
	end

	self.messageView = widget_virtual_vert_list:init(messageView, msgList,
		function(self, parentWindow)
			textNamecount = textNamecount + 1
			local childWindow = parentWindow:createChild("WindowsLook/StaticText", "msgText_" .. textNamecount)
			childWindow:setProperty("FrameEnabled", false)
			childWindow:setProperty("Font", "DroidSans-18")
			childWindow:setProperty("TextColours","ffffffff")
			childWindow:setProperty("MousePassThroughEnabled","true")
			childWindow:getWindowRenderer():setHorizontalFormatting(4)
			childWindow:setWidth({ 0.95, 0 });
			return childWindow
		end,
		function(self, childWindow, msg)
			local transformText = childWindow:setTextAutolinefeed(msg)
			childWindow:setArea2({ 0, 0 }, { 0, 0 }, { 0.95, 0 }, { 0, childWindow:getWindowRenderer():getDocumentHeight() })
		end
	)

	Lib.subscribeEvent(Event.EVENT_CHAT_HIDE_LEFT_BTN, function(isFold)
		if not isFold then
			stopFoldTimer()
		end
	end)

	self:setVisible(false)
end

function M:onHidden()
	stopFoldTimer()
	self:isFoldChat(false)
end

function M:onShown()
	setVertScrollPosition()
	autoFoldTimerFunc(self)
	self.inputEditbox:setTipText(Lang:toText("win.main.chat.clickSendMsg"))
end

function M:setChatOffsetX(offset)
	self.offsetX = offset
end

function M:isFoldChat(isFold)
	self.chatContent:setXPosition({0, isFold and self.offsetX or 0})
	self.chatSendLayout:setVisible(not isFold)
	self.chatContentMask:setVisible(isFold)
	self.chatContentBg:setProperty("Alpha", isFold and 0.3 or 0.5)
	Lib.emitEvent(Event.EVENT_CHAT_HIDE_LEFT_BTN, not isFold)
end

function M:showChatMessage(msg, fromname, type)
	type = type or "current"

	if fromname then
		msg = ": " .. msg
		msg = "[colour='FFFF0000']\\[" .. fromname .. "\\][colour='FFFFFFFF']" .. msg
	end
	
	self.messageView:addVirtualChild(msg)
	setVertScrollPosition()
end


function M:sendChatMessage()
	local msg = self.inputEditbox.getProperties().Text
	if not msg or msg == "" then
		return
	end

	if msg == "/profiler" then
		self.inputEditbox:setProperty("Text", "")
		self:setVisible(false)
		UI:openSystemWindow("profiler")
	else
		local packet ={
			pid = "ChatMessage",
			fromname = Me.name,
			msg = msg,
			type = "current"
		}
		self.inputEditbox:setProperty("Text", "")
		Me:sendPacket(packet)
	end
end

function M:onOpen()
    self:init()
    self:setLevel(1)
end

function M:onClose()
    for _, func in pairs(events) do
		func()
	end
end
