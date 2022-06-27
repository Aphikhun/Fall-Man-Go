
--local M = UI
--local guiMgr = L("guiMgr", GUIManager:Instance())

--[[
CreateGUIWindow		创建一个UI布局的实例
getGUIWindow		根据InstanceName返回窗口实例
closeWindow			传入一个窗口实例来关闭窗口
openSceneWindow		打开一个UI布局作为场景UI
closeSceneWindow	根据InstanceName关闭场景UI
createGUIWidget		直接创建一个UI控件
]]

function UI:CreateGUIWindow(layoutPath, windowName, ...)
	local resGroup = "layouts"
	local name = windowName or layoutPath

	local window = self:loadWindowByResGroup(layoutPath, "asset")	--从 gameroot/asset/ 找
	if not window then
		window = self:loadWindowByResGroup(layoutPath, resGroup)	--从 gameroot/gui/layout 找
		if not window then
			print(layoutPath .. "----" .. " not find")
			return
		end
	else
		resGroup = "asset"
	end

	window:setName(name)
	local id = window:getID()
	local instance = UI:getWindowInstance(window)
	instance.__windowName = name
	instance.__groupName = resGroup
	if resGroup == "asset" then
		instance.__windowAssetRelPath = Lib.toFileDirName(layoutPath)
		instance.__windowAssetLuaScripts = Lib.toFileName(layoutPath)
	end
	local ok, ret = pcall(UI.loadLuaScriptByGroup, UI, instance, layoutPath)
	if not ok then
		UI:releaseWindowInstance(id)
	end
	return instance
end

--function UI:GetGUIWindow()
--end

--function UI:CloseWindow()
--end

--function UI:OpenSceneWindow()
--end

--function UI:CloseSceneWindow()
--end

local initWidgetFunc = {}
initWidgetFunc[Enum.WidgetType.Frame] = function(widget)
	--print(Enum.WidgetType.Frame)
end
initWidgetFunc[Enum.WidgetType.Text] = function(widget)
	--print(Enum.WidgetType.Text)
	widget:setText("Here is text")
	widget:setFrameEnabled(false)
end
initWidgetFunc[Enum.WidgetType.Image] = function(widget)
	--print(Enum.WidgetType.Image)
	widget:setImage("_imagesets_|def:def_image")
	widget:setFrameEnabled(false)
end
initWidgetFunc[Enum.WidgetType.Button] = function(widget)
	--print(Enum.WidgetType.Button)
	widget:setText("Button")
end
initWidgetFunc[Enum.WidgetType.ProgressBar] = function(widget)
	--print(Enum.WidgetType.ProgressBar)
end
initWidgetFunc[Enum.WidgetType.Editbox] = function(widget)
	--print(Enum.WidgetType.Editbox)
end
initWidgetFunc[Enum.WidgetType.Checkbox] = function(widget)
	--print(Enum.WidgetType.Checkbox)
	widget:setText("Checkbox")
end
initWidgetFunc[Enum.WidgetType.RadioButton] = function(widget)
	--print(Enum.WidgetType.RadioButton)
	widget:setText("RadioButton")
end
initWidgetFunc[Enum.WidgetType.HorizontalSlider] = function(widget)
	--print(Enum.WidgetType.HorizontalSlider)
end
initWidgetFunc[Enum.WidgetType.VerticalSlider] = function(widget)
	--print(Enum.WidgetType.VerticalSlider)
end
initWidgetFunc[Enum.WidgetType.ScrollableView] = function(widget)
	--print(Enum.WidgetType.ScrollableView)
	widget:setArea2({0, 0}, {0, 0}, {0, 200}, {0, 200})
end
initWidgetFunc[Enum.WidgetType.ActorWindow] = function(widget)
	--print(Enum.WidgetType.ActorWindow)
end
initWidgetFunc[Enum.WidgetType.EffectWindow] = function(widget)
	--print(Enum.WidgetType.EffectWindow)
end

local widgetCount = 1
function UI:CreateGUIWidget(widgetType)
	local name = "widget" .. widgetCount
	widgetCount = widgetCount + 1
	local widget = UI:createWindow(name, widgetType)
	if widget and initWidgetFunc[widgetType] then
		initWidgetFunc[widgetType](widget)
	end
	return widget
end
