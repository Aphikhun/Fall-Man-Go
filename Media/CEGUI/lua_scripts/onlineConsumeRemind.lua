function M:onOpen()
    self:init()
end

function M:init()
    self.callbackFunc = false
	self.title = self:child("Online_Consume_Remind_Title")
	self.txt = self:child("Online_Consume_Remind_Text")
	self.checkTxt = self:child("Online_Consume_Remind_CheckTxt")
	self.checkBox = self:child("Online_Consume_Remind_Check")
	self.yesBtn = self:child("Online_Consume_Remind_Yes")
self.noBtn = self:child("Online_Consume_Remind_No")
	self.closeBtn = self:child("Online_Consume_Remind_Close")

	self.title:setText(Lang:toText("win.main.online.consume.remind.title"))
	self.txt:setText(string.format( Lang:toText("win.main.online.consume.remind.txt"), 1 ))
	self.checkTxt:setText(Lang:toText("win.main.online.consume.remind.checktxt"))
	self.yesBtn:setText(Lang:toText("global.sure"))
	self.noBtn:setText(Lang:toText("global.cancel"))
	self.checkBox:setSelected(true)

    self.yesBtn.onMouseClick = function()
        if self.callbackFunc then
			self.callbackFunc()
			self.callbackFunc = nil
		end
		if self.checkBox:isSelected() then
			Clientsetting.refreshRemindConsume(0)
		else
			Clientsetting.refreshRemindConsume(1)
		end
		self.close()
    end

    self.noBtn.onMouseClick = function()
        self.callbackFunc = nil
        self.close()
    end

    self.closeBtn.onMouseClick = function()
        self.callbackFunc = nil
        self.close()
    end
end

function M:setPrice(price)
	self.txt:setText(string.format( Lang:toText("win.main.online.consume.remind.txt"), price or 1 ))
end

function M:setCallBack(func)
	self.callbackFunc = func
end