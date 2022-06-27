--single shop 
local setting = require "common.setting"
local guiMgr = L("guiMgr", GUIManager:Instance())
local winMgr = L("winMgr", CEGUIWindowManager:getSingleton())

local setButtonAllImage = function (button, image)
	button:setNormalImage(image)
	button:setPushedImage(image)
end
local merchantGroup
local commoditys
local selectTypeIndex
local invalidated
local limitIndex = {}
self.limitType = {
	{lang = "person_limit"},
	{lang = "team_limit"}
}
function self:updateCurrency()
	local i = 0
	for _, item in ipairs(Coin:GetCoinCfg()) do
		self:findCurrentViewByCoinId(item.coinName, i)
		i = i + 1
	end
end

function self:findCurrentViewByCoinId(coinName, index)
	if not self.currencyMap[coinName] then
		local currencyItem = self.currencyContent:createChild("Engine/StaticImage")
		currencyItem:setArea2({ 0, index * 120 + 20 }, { 0, 12 }, { 0, 110 }, { 0.75, 0 })
		currencyItem:setProperty("Image", "shop/currency_bg")
		local currencyIcon = currencyItem:createChild("Engine/StaticImage")
		currencyIcon:setArea2({ 0, 10 }, { 0, 0 }, { 0, 30 }, { 0, 30 })
		currencyIcon:setVerticalAlignment(1)
		local icon = Coin:iconByCoinName(coinName)
		currencyIcon:setProperty("Image", icon)

		local currencyValue = currencyItem:createChild("Engine/StaticText")
		currencyValue:setArea2({ 0, 50}, { 0, 0 }, { 0, 90 }, { 1, 0 })
		currencyValue:setText(Coin:countByCoinName(Me, coinName))
		currencyValue:setVerticalAlignment(1)

		self.currencyMap[coinName] = currencyValue
	end
	self.currencyMap[coinName]:setText(Coin:countByCoinName(Me, coinName))
end

function self:showItemIcon(itemIcon, itemName, blockId)
	local item
	if itemName == "/block" then
		item = Item.CreateItem(itemName, 1, function(_item)
			if tonumber(blockId) then
				_item:set_block_id(blockId)
			else
				_item:set_block(blockId)
			end
		end)
		--todo:block icon!!
	else
		item = Item.CreateItem(itemName)
	end
	if item and item:cfg().icon ~= "" then
		itemIcon:setImage(GUILib.loadImage(item:icon(), item:cfg()))
		return
	end
end

local function switchCurrentGood(old, new)
	if old then
		old:child("itemBg"):setImage("shop/commodity")
	end
	if new then
		new:child("itemBg"):setImage("shop/select")
	end
end

function self:updateTip(item)
	local content = self.itemTipContent
	content:setVisible(true)
	self:showItemIcon(content:child("itemSlotIcon"), item.itemName, item.blockName)
	content:child("itemSlotName"):setText(Lang:formatText(item.desc))
	content:child("itemDesc"):getWindowRenderer():setHorizontalFormatting(4)
	content:child("itemDesc"):setText(Lang:formatText(item.tipDesc))
	content:child("tipCoinPrice"):setText(tostring(item.price))
	content:child("tipCoinIcon"):setImage(Coin:iconByCoinName(item.coinName))

	content:child("tipBuyButton").onMouseClick = function ()
		self:onBtnBuy(item)
	end
	
	content:child("tipBuyButton"):setEnabled(not limitIndex[item.index])
	content:child("tipBuyButton"):setMousePassThroughEnabled(limitIndex[item.index])
end

function self:onBtnBuy(item)
	if self.shopType == SingleShop.types.COMMODITY then
		Me:syncBuyCommodityGood(item.index)
	elseif self.shopType == SingleShop.types.SHOP then
		Shop:requestBuyStop(item.index, 1)
	else
	
	end
end

function self:selectGood(goodsItem, item)
	if self.currentSelectGood == goodsItem then
		return
	else
		switchCurrentGood(self.currentSelectGood, goodsItem)
		self.currentSelectGood = goodsItem
	end

	-- print("selectGood>>>>>>>>>>>>>", Lib.v2s(item))
	self:updateTip(item)
end


function self:updateItem(cell, item)
	cell:child("itemBg"):setImage("shop/commodity")
	cell:child("iconBg"):setImage("shop/item_icon")
	
	local itemName = cell:child("itemName")
	local countText = cell:child("countText")
	local limitImage = cell:child("limitImage")
	local limitText = cell:child("limitText")

	limitImage:setImage("shop/limit")
	limitImage:setVisible(false)
	local limitType = item.limitType
	if limitType and self.limitType[limitType] and item.limit > 0 then
		limitImage:setVisible(true)
		limitText:setText(Lang:toText({self.limitType[limitType].lang, item.limit}))
	end
	
	local tipButton = cell:child("tipButton")
	tipButton.onMouseClick = function ()
		self:selectGood(cell, item)
	end

	local buyButton = cell:child("buyButton")
	setButtonAllImage(buyButton, "shop/buy_btn")

	buyButton:setEnabled(not limitIndex[item.index])
	buyButton:setMousePassThroughEnabled(limitIndex[item.index])

	buyButton.onMouseClick = function ()
		self:onBtnBuy(item)
	end

	self:showItemIcon(cell:child("iconImage"), item.itemName, item.blockName)
	itemName:setText(Lang:toText(item.desc))
	local buyCoinImage= cell:child("buyCoinImage")
	buyCoinImage:setImage(Coin:iconByCoinName(item.coinName))
	buyCoinImage:setMousePassThroughEnabled(true)
	cell:child("buyPriceText"):setText(item.price)
	cell:child("buyPriceText"):setMousePassThroughEnabled(true)

	countText:setText(tostring(item.num))
	
	if self.needSelectFirstGood then
		self:selectGood(cell, item)
		self.needSelectFirstGood = false
	end
end


function self:addGoodsItem(item)
	local cell = UI:loadLayoutInstance("goodItem", "_layouts_")
	self.gridView:addChild(cell.__window)
	self:updateItem(cell, item)

	return cell
end

function self:updateItemView(typeIndex)
	if typeIndex == 0 then
		return
	end
	self.currentSelectGood = false--todo: can crash
	self.itemTipContent:setVisible(false)
	if not commoditys[typeIndex] then
		return
	end
	self.curTypeGoods = {}
	for _, item in pairs(commoditys[typeIndex].commoditys or {}) do
		local ret = self:addGoodsItem(item)
		self.curTypeGoods[#self.curTypeGoods + 1] = {cell = ret, coinItemName = Coin:GetCoinItemByCoinName(item.coinName), price = item.price, item = item, index = item.index}
	end
end

function self:onRadioChange(typeIndex)
	self.needSelectFirstGood = true
	self.gridView:cleanupChildren()
	selectTypeIndex = typeIndex
	self:updateItemView(typeIndex)
end

function self:getTabItem(type, index)
	local typeIndex, typeName, typeIcon = type[1], type[2], type[3]
	local tabButton = self.tabLayout:createChild("Engine/RadioButton")
	tabButton = UI:getWindowInstance(tabButton)
	tabButton:setArea2({ 0, 0 }, { 0, 0 }, { 0.8, 0 }, { 0, 70 })
	tabButton:setNormalImage("shop/tab_normal")
	tabButton:setProperty("SelectedImage", "shop/tab_push")
	tabButton:setProperty("HorizontalAlignment", "Centre")
	
	local staticText = tabButton:createChild("Engine/StaticText")
	staticText:setText(Lang:toText(typeName))
	staticText:getWindowRenderer():setHorizontalFormatting(2)
	staticText:setMousePassThroughEnabled(true)
	staticText:setProperty("BorderEnable", "true")
	staticText:setProperty("BorderColor", "ff000000")
	staticText:setProperty("BorderWidth", "0.5")
	staticText:setProperty("Font", "DroidSans-16")
	
	if typeIcon and #typeIcon > 0 then
		local staticImage = tabButton:createChild("Engine/StaticImage")
		staticImage:setProperty("Image", GUILib.loadImage(typeIcon))
		staticImage:setProperty("VerticalAlignment", "Centre")
		staticImage:setArea2({ 0, 30 }, { 0, 0 }, { 0, 30 }, { 0, 30 })
		staticText:setArea2({ 0.2, 0 }, { 0, 0 }, { 0.8, 0 }, { 1, 0 })
	else
		staticText:setArea2({ 0, 0 }, { 0, 0 }, { 1, 0 }, { 1, 0 })
	end
	tabButton.onSelectStateChanged = function (wnd)
		if wnd:isSelected() then
			self:onRadioChange(typeIndex)
		else
			--set text color
		end
	end
	if index == 0 then
		tabButton:setSelected(true)
	end
	return tabButton
end

function self:initTabView()
	local indexCfg = merchantGroup.typeIndex
	local index = 1
	for _, type in pairs(indexCfg) do
		local typeIndex = type[1]
		local radioItem = self:getTabItem(type, index - 1)
		index = index + 1
	end
	if index == 1 and self.itemTipContent then
		self.itemTipContent:setVisible(false)
	end
end

function self:onBuyGoodsResult(msg)
	if self.showBuyResultTipTimer then
		self.showBuyResultTipTimer()
	end
	if invalidated then
		return
	end
	self.showTipTime = 20
	self.textTip = self:child("buyResultTip")
	self.textTip:setText(Lang:toText(msg))
	self.showBuyResultTip = World.Timer(self.showTipTime, function ()
		if invalidated then
			return
		end
		self.textTip:setText("")
		self.showBuyResultTip = false
	end)
end

function self:showGoods(index)
	if self.showBuySuccessTipTimer then
		self.showBuySuccessTipTimer()
	end
	if invalidated then
		return
	end
	local commodity = SingleShop.goods[self.shopType][index]
	local buySuccessTip = self:child("buySuccessTip")
	buySuccessTip:setImage("shop/buy_success_bg")
	buySuccessTip:child("buySuccessTipText"):setText("+" .. commodity.num)
	self:showItemIcon(buySuccessTip:child("buySuccessTipImage"), commodity.itemName, commodity.blockName)
	buySuccessTip:setVisible(true)

	self.showBuySuccessTipTimer = World.Timer(10 , function()
		if invalidated then
			return
		end
		--todo: tween
		self.buySuccessTip:setVisible(false)
	end)
end

local events = {}

local function subscribeEvent()
	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_SEND_BUY_COMMODITY_RESULT, function(msg, index, result)
		self:onBuyGoodsResult(msg)
		self:onRadioChange(selectTypeIndex)
		if result then
			-- todo: play2DSound(buySound)
			self:showGoods(index)
		end
	end)
	
	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_SHOP_GOOD_IS_LIMIT, function(shopType, shopGroup, index)
		if self.shopType ~= shopType then
			return
		end

		if self.shopGroup ~= shopGroup then
			return
		end

		limitIndex[index] = true
		self:onRadioChange(selectTypeIndex)
	end)
	
	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_PLAYER_ITEM_MODIFY, function()
		self:updateCurrency()
	end)

	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_SEND_BUY_SHOP_RESULT, function(index, limit, msg, _, success)
		if not success then
			limitIndex[index] = true
			self:onBuyGoodsResult(msg)
			self:onRadioChange(selectTypeIndex)
			return
		end
		self:onRadioChange(selectTypeIndex)
		self:showGoods(index)
	end)


	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_BUY_APPSHOP_TIP, function(msg)
		self:onBuyGoodsResult(msg)
	end)

	events[#events + 1] = Lib.subscribeEvent(Event.EVENT_PLAYER_ITEM_MODIFY_GTA, function(tid, slot, itemData)
		local full_name = itemData:is_block() and "/block" or itemData:full_name()
		local block_name = itemData:block_name()
		local tempItemName = block_name or full_name or ("tid:"..tid.."_slot"..slot)
		local count = Me:tray():find_item_count(full_name, block_name) or -1
		for _, info in pairs(self.curTypeGoods) do
			if info.coinItemName and info.coinItemName == tempItemName then
				limitIndex[info.index] = (info.price or 0) > count
				self:updateItem(info.cell, info.item)
			end
		end
	end)
end

local function init()
	self.IS_OPEN = false
	self.curTypeGoods = {}
	self.buySuccessTip:setVisible(false)
	self.closeButton = self:child("close")
	setButtonAllImage(self.closeButton, "new_gui_material/page_btn_close")

	self.closeButton.onMouseClick = function ()
		self.close()
	end
	
	self.shopContent:setImage("shop/bg")
	self:child("tabContent"):setImage("shop/tab_bg")
	self:child("tipBg"):setImage("shop/tip_bg")
	self:child("itemSlotBg"):setImage("shop/item_icon")
	self:child("itemDescBg"):setImage("shop/desc_tip")
	setButtonAllImage(self:child("tipBuyButton"), "shop/buy_btn")
	self:child("tipBuyButton"):setProperty("DisabledImage", "shop/buy_btn")
	self:child("buyResultTip"):setText("")
	
	self.needSelectFirstGood = false
	self.currentSelectGood = false
	selectTypeIndex = 0
	self.showBuyResultTipTimer = false
	self.showBuySuccessTipTimer = false
	
	
	self.itemTipContent = self:child("itemTipContent")
	self.tabLayout = self:child("tabLayout")
	self.gridView = self:child("gridView")
	self.gridView:setProperty("rowSize", "4")
	
	subscribeEvent()
	
	self.currencyMap = {}
	self.currencyContent = self:child("currencyContent")
	self:updateCurrency()
end

function self:onOpen(shopType, shopGroup)
	self.IS_OPEN = true
	self.shopType = shopType
	self.shopGroup = shopGroup

	commoditys = SingleShop.typeGoods[shopType]
	merchantGroup = SingleShop.groups[shopType][shopGroup]
	local title = merchantGroup.showTitle or "gui_merchant_titleName"
	self:child("title"):setText(Lang:toText(title))

	self:initTabView()
end

function self:onClose()
	self.IS_OPEN = false
	invalidated = true
	for _, func in pairs(events) do
		func()
	end
end

init()