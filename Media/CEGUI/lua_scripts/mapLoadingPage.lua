print("startup mapLoadingPage")
local imgMgr = CEGUIImageManager:getSingleton()

local enumShowType = {
	DOWNLOAD_MAP = 0,
	NETWORK_CONNECT_SUCCESSFUL = 1,
	NETWORK_CONNECT_FAILURE = 2,
	NETWORK_DISCONNECT = 3,
	NETWORK_KICK_OUT = 4,
	NETWORK_TIMEOUT = 5,
	LOAD_WORLD_START = 6,
	LOAD_WORLD_END = 7,
	LOGIN_SUCC = 8,
	LOGIN_FAILURE = 9,
	LOGIN_TOKEN_ERROR = 10,
	LOGIN_GET_USER_ATTR_FAIL = 11,
	LOGIN_RESPONSE_TIMEOUT = 12,
	DOWNLOAD_MAP_SUCCESS = 13,
	DOWNLOAD_MAP_FAILURE = 14,
	DOWNLOAD_MAP_PROGRESS = 15,
	CHECK_VERSION_SUCCESS = 16,
	CHECK_VERSION_FAILURE = 17,
	BE_KICKED = 18,
	GAMEOVER = 19,
	GAME_ALLOCATION_FAILURE = 20,
	GAME_ALLOCATION_FAILURE_VERSION_MISMATCH = 21,
	GAME_ALLOCATION_FAILURE_USER_FULL = 22,
	USER_LOGIN_TIMEOUT = 23,
	SERVER_QUITTING = 24,
	USER_LOGIN_TARGET_NOT_EXIST = 26
}

local tipMap = {
	[0] = "DOWNLOAD_MAP",
	[1] = "NETWORK_CONNECT_SUCCESSFUL",
	[2] = "NETWORK_CONNECT_FAILURE",
	[3] = "NETWORK_DISCONNECT",
	[4] = "NETWORK_KICK_OUT",
	[5] = "NETWORK_TIMEOUT",
	[6] = "LOAD_WORLD_START",
	[7] = "LOAD_WORLD_END",
	[8] = "LOGIN_SUCC",
	[9] = "LOGIN_FAILURE",
	[10] = "LOGIN_TOKEN_ERROR",
	[11] = "LOGIN_GET_USER_ATTR_FAIL",
	[12] = "LOGIN_RESPONSE_TIMEOUT",
	[13] = "DOWNLOAD_MAP_SUCCESS",
	[14] = "DOWNLOAD_MAP_FAILURE",
	[15] = "DOWNLOAD_MAP_PROGRESS",
	[16] = "CHECK_VERSION_SUCCESS",
	[17] = "CHECK_VERSION_FAILURE",
	[18] = "BE_KICKED",
	[19] = "GAMEOVER",
	[20] = "GAME_ALLOCATION_FAILURE",
	[21] = "GAME_ALLOCATION_FAILURE_VERSION_MISMATCH",
	[22] = "GAME_ALLOCATION_FAILURE_USER_FULL",
	[23] = "USER_LOGIN_TIMEOUT",
}


local function buildImage(image, imageset)
	local resourceGroup = imageset and "_imagesets_" or "_textures_"
	image = imageset and (imageset .. "/" .. image) or image
	local filename = imageset or image
	if not imageset and not imgMgr:isDefined(image) then
		imgMgr:addFromImageFile(image, filename, resourceGroup)
	end
	return image
end

local function setButtonImage(self, ...)
	local image = buildImage(...)
	self:setProperty("NormalImage", image)
	self:setProperty("HoverImage", image)
	self:setProperty("PushedImage", image)
end

local function setStaticImage(self, ...)
	self:setProperty("Image", buildImage(...))
end

local function init()
	self:setLevel(1)

	if os.getenv("IS_WORLD_EDITOR") == "true" or CGame.instance:getIsEditorEnvironment() then
		self.loadingBg:setImage(GUILib.loadImage("#loading_editor.png"))
	else
		self.loadingBg:setImage(GUILib.loadImage("#loading.png"))
	end
	
	self.backBtn = self["loadingFailure/backButton"]
	self.backBtn:setText(Lang:toText("gui.exit.game"))
	self.overMassage = self["loadingFailure/message"]

	setStaticImage(self.loadingFailure, "gui_bg", "cegui_material")
	setButtonImage(self.backBtn, "btn_bg_blue", "cegui_material")
	
	self.backBtn.onMouseClick = function ()
		UI:closeWindow(self)
		CGame.instance:exitGame("offline")
	end

	self.loginSuccess = false
	self.initMainGui = false

	self.loadingTip:setProperty("TextColours","ffffffff")
end


init()

self.onOpen = function ()
	self.loadingFailure:setVisible(false)
end

self.onClose = function ()
end

function self:showLoadingPage(showType)
	print("showLoadingPage", tipMap[showType]) 
	if showType == enumShowType.NETWORK_DISCONNECT then
		self:showLoadingFailure("gui.message.network.connection.disconnect")
	elseif showType == enumShowType.NETWORK_KICK_OUT then
		self:showLoadingFailure("gui.message.network.connection.kick.out")
	elseif showType == enumShowType.NETWORK_TIMEOUT then
		self:showLoadingFailure("gui.message.network.connection.network.error")
	elseif showType == enumShowType.BE_KICKED then
		self:showLoadingFailure("gui.message.account.be.kicked")
	elseif showType == enumShowType.NETWORK_CONNECT_SUCCESSFUL then
		self:showLoadingSuccess("gui.loading.page.player.login.loggingin")
	elseif showType == enumShowType.NETWORK_CONNECT_FAILURE then
		self:showLoadingFailure("gui.loading.page.connected.server.failed")
	elseif showType == enumShowType.LOAD_WORLD_START then
		if CGame.instance:getIsEditor() then
			self:showLoadingSuccess("gui.message.enter.editor")
		else
			self:showLoadingSuccess("gui.loading.page.player.entering.map")
		end
	elseif showType == enumShowType.LOAD_WORLD_END then
		if not UI.initMainGui then
			Blockman.Instance():onGameReady()
			UI.initMainGui = true
		end
		UI:closeWindow(self)
	elseif showType == enumShowType.LOGIN_FAILURE then
		self:showLoadingFailure("gui.loading.page.player.login.failure")
	elseif showType == enumShowType.LOGIN_TOKEN_ERROR then
		self:showLoadingFailure("gui.loading.page.player.login.token.error")
	elseif showType == enumShowType.LOGIN_GET_USER_ATTR_FAIL then
		self:showLoadingFailure("gui.loading.page.player.login.get.user.attr.fail")
	elseif showType == enumShowType.CHECK_VERSION_SUCCESS then
		self:showLoadingSuccess("gui.loading.page.player.login.loggingin")
	elseif showType == enumShowType.CHECK_VERSION_FAILURE then
		self:showLoadingFailure("gui.loading.page.check.version.failure")
	elseif showType == enumShowType.LOGIN_SUCC then
		self.loginSuccess = true
	elseif showType == enumShowType.DOWNLOAD_MAP_SUCCESS then
		self:showLoadingSuccess("gui.loading.page.connected.server.connecting")
	elseif showType == enumShowType.DOWNLOAD_MAP_FAILURE then
		self:showLoadingFailure("gui.loading.page.download.map.failure")
	elseif showType == enumShowType.GAMEOVER then
		--do nothing
	elseif showType == enumShowType.DOWNLOAD_MAP_PROGRESS then
		--do nothing
	elseif showType == enumShowType.GAME_ALLOCATION_FAILURE then
		self:showLoadingFailure("game_allocation_failure")
	elseif showType == enumShowType.GAME_ALLOCATION_FAILURE_VERSION_MISMATCH then
		self:showLoadingFailure("game_allocation_failure_version_mismatch")
	elseif showType == enumShowType.GAME_ALLOCATION_FAILURE_USER_FULL then
		self:showLoadingFailure("game_allocation_failure_user_full")
	elseif showType == enumShowType.USER_LOGIN_TIMEOUT then
		self:showLoadingFailure("user_login_timeout")
	elseif showType == enumShowType.SERVER_QUITTING then
		self:showLoadingFailure("system.message.close.server.loading.tip")
	elseif showType == enumShowType.USER_LOGIN_TARGET_NOT_EXIST then
		self:showLoadingFailure("login_error_target_user_not_exist")
	end
end

function M:showLoadingSuccess(msg)
	self.loadingBg:setVisible(true)
	self.loadingTip:setVisible(true)
	self.loadingFailure:setVisible(false)
	self.loadingTip:setProperty("Text", Lang:toText(msg))
end

function M:showLoadingFailure(msg)
	self.loadingBg:setVisible(true)
	self.loadingTip:setVisible(false)
	self.loadingFailure:setVisible(true)
	self.overMassage:setProperty("Text", Lang:toText(msg))
end