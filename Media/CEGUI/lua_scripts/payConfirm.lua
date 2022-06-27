function M:init()
    local content = self.content
    self.titleName = content.title.title_text
    self.titleName:setText(Lang:toText("pay.confirm.title"))
    self.closeBtn = content.title.closeBtn
    self.closeBtn.onMouseClick = function()
        self:cancelDeal()
    end

    self.tipText = content.pay_tip.tip_text
    self.tipText:setText(Lang:toText("pay.confirm.tip"))
    self.count = content.pay_tip.gdiamond.x.count
    self.count:setText("0")

    self.confirmBtn = content.confirm
    self.confirmBtnCount = self.confirmBtn.btn_count
    self.confirmBtnCount:setText("0")
    self.confirmBtn.onMouseClick = function()
        self:confirmDeal()
    end

    self.cancelBtn = content.cancel
    self.cancelBtn:setText(Lang:toText("pay.confirm.cancel"))
    self.cancelBtn.onMouseClick = function()
        self:cancelDeal()
    end
end

function M:onOpen(price)
    self:init()
    self.count:setText(price)
    self.confirmBtnCount:setText(price)
end

function M:updatePrice(price)
    self.count:setText(price)
    self.confirmBtnCount:setText(price)
end

function M:confirmDeal()
    --确认支付
    Me:sendPacket({
        pid = "ConfirmPayMoney"
    })
    self.close()
end

function M:cancelDeal()
    --取消支付
    Me:sendPacket({
        pid = "CancelPayMoney"
    })
    self.close()
end

function M:onClose()
    self.count:setText("0")
    self.confirmBtnCount:setText("0")
end