local function init()
	local uiNavigation = World.cfg.uiNavigation
	--todo: self not click
	--temp
	local image = "cegui_new_gameUI/icon_shop"
	self.shopButton:setProperty("NormalImage", image)
	self.shopButton:setProperty("HoverImage", image)
	self.shopButton:setProperty("PushedImage", image)
	local showShop = uiNavigation and uiNavigation[1] and uiNavigation[1].name == "shop"
	local showButtonShopName = World.cfg.showButtonShopName
	local validButtonShopName = showButtonShopName and (showButtonShopName ~= "")
	if not showShop and not validButtonShopName then
		self.shopButton:setVisible(false)
	else
		self.shopButton:setVisible(true)
		self.shopButton.onMouseClick = function ()
			Lib.emitEvent(Event.EVENT_OPEN_APPSHOP, true, showButtonShopName, World.cfg.showButtonShopType)
		end
	end
end

init()

self.onOpen = function ()

end

