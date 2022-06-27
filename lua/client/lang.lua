---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by work.
--- DateTime: 2018/9/1 11:48
---
local strfor = string.format
local default = "en"
local defaultOnline = "en_US"

local langList = { }

local function exchangeTable(receiveTb, changeTb)
	if not changeTb then
		return
	end
	for k, v in pairs(changeTb) do
		receiveTb[v] = k
	end
end

function Lang:init()
	langList = {}
    local strs = Lib.splitString(World.Lang, "_")
    World.LangPrefix = strs[1]
    print("World.Lang: ", World.Lang, World.LangPrefix)
	local langPathList = {
		[1] = {
			loadPathType = "RootPath",
			langPath = "Media/Lang/Online/%s.lang",
			langKey = "onLine_lang",
		},
		[2] = {
			loadPathType = "RootPath",
			langPath = "Media/Lang/Online/%s.json",
			langKey = "onLine_json",
		},
		[3] = {
			loadPathType = "RootPath",
			langPath = "Media/Lang/%s.lang",
			langKey = "map",
		},
		[4] = {
			loadPathType = "RootPath",
			langPath = "Media/Lang/%s.json",
			langKey = "map_json",
		},
		[5] = {
			loadPathType = "RootPath",
			langPath = "Media/Lang/MobileEditorLang/%s.json",
			langKey = "mobileEditor_json",
		},
		[6] = {
			loadPathType = "GamePath",
			langPath = "lang/%s.lang",
			langKey = "game_lang",
		},
		[7] = {
			loadPathType = "GamePath",
			langPath = "lang/%s.json",
			langKey = "game_tip_json",
		},
		[8] = {
			loadPathType = "GamePath",
			langPath = "lang/Language/%s.json",
			langKey = "editor",
		},
		[9] = {
			loadPathType = "GamePath",
			langPath = "lang/lang.csv",
			langKey = "editor_text",
		}
	}
	self.mobileEditor_json_path_exchangeKV = {}

	local function getPathPrefix(type)
		local pathPrefix
		if type == "RootPath" then
			pathPrefix = Root.Instance():getRootPath()
		elseif type == "GamePath" then
			pathPrefix = Root.Instance():getGamePath()
		end
		return pathPrefix
	end

	local function getPathLoadFun(path)
		local loadFun
		if path:find(".json") then
			loadFun = Lib.read_json_file
		elseif path:find(".lang") then
			loadFun = Lib.read_lang_file
		end
		return loadFun
	end

	for key, value in ipairs(langPathList) do
		local pathPrefix, loadFun
		pathPrefix = getPathPrefix(value.loadPathType)
		if value.langKey == "editor_text" then
			local langMap = {}
			local csvLine,_key = Lib.read_csv_file(pathPrefix .. value.langPath)
			local cur_lang = World.LangPrefix
			if csvLine then
				local is_some = false
				for i = 1,#_key do
					if _key[i] == cur_lang then
						is_some = true
					end
				end
				if not is_some then
					cur_lang = default
				end
				for _, line in ipairs(csvLine) do
					local k = assert(line["KEY"])
					local _value = line[cur_lang]
					langMap[k] = _value
				end
				if next(langMap) then
					table.insert(langList,langMap)
				end
			end
		else
			loadFun = getPathLoadFun(value.langPath)
			local defaultLang = default
			local cur_lang = World.LangPrefix
			if value.langKey=="onLine_lang" or value.langKey == "onLine_json" then
				cur_lang = World.Lang
				defaultLang = defaultOnline
			end
			local langMap = loadFun(pathPrefix .. strfor(value.langPath, cur_lang))
			if not langMap then
				langMap = loadFun(pathPrefix .. strfor(value.langPath, defaultLang))
			end
			if value.langKey == "mobileEditor_json" then
				exchangeTable(self.mobileEditor_json_path_exchangeKV, langMap)
			end
			table.insert(langList,langMap)
		end
	end
	self:onLoad()
end

--插件有4个位置，先尝试当前语言业务+引擎，然后再查英文语言业务+引擎
function Lang:loadPlugin(pluginPath)
	local strs = Lib.splitString(World.Lang, "_")
	local pluginLangPath = strfor(pluginPath .. "/lang/%s.lang", strs[1])
	local pluginLang = Lib.read_lang_file(pluginLangPath)
	table.insert(langList, pluginLang)
end

local guiMgr = L("guiMgr", GUIManager:Instance())

function Lang:onLoad()
	if not guiMgr:isEnabled() then
		return
	end
	local function onLoad(tab)
		if not tab then
			return
		end
		local function changeByColor()
			for key, str in pairs(tab) do
				local newText = (type(str) == "string") and str:gsub("(▢[%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d][%a%d])", function(msk)
					msk = msk:sub(4, 12)
					return "[colour='" .. msk .. "'" .. "]"
				end) or str
				tab[key] = newText
			end
		end
		changeByColor(tab)
	end
	for _, langData in pairs(langList) do
		onLoad(langData)
	end
end

local function getMessage(key)
	for _, langData in ipairs(langList) do
		if langData[key] then
			return langData[key]
		end
	end
	return
end

function Lang:getChinaMessage(key)
	key = tostring(key) .. "_china"
	return getMessage(key)
end

---@return string
function Lang:getMessage(key)
	if GlobalProperty.Instance() and GlobalProperty.Instance():getBoolProperty("IsChina") then
		local message = self:getChinaMessage(key)
		if message then
			return message
		end
	end

	key = tostring(key)
	return getMessage(key) or key
end

function Lang:formatMessage(key, args)
	return self:toText({key,table.unpack(args or {})})
end

function Lang:toText(arg)
	local csvNewlineMark = World.cfg and World.cfg.csvNewlineMark
	if type(arg)~="table" then
		local ret = self:getMessage(arg)
		return csvNewlineMark and ret:gsub(csvNewlineMark, "\n") or ret
	end
	local msg = self:getMessage(arg[1])
	local n = 1
	local function replace(mark)
		n = n + 1
		local value = arg[n]
		if value==nil then
			return "(nil)"
		end
		local t = mark:sub(1,1)
		if t=="%" then
			local strfmt = string.format
			if mark:sub(-1) == "%" then	-- %.n% like python '.n%' format percent
				return strfmt(strfmt("%%%sf", mark:sub(2, -2)).."%%", value * 100)
			end
			return strfmt(mark, value)
        elseif mark=="." then
            return self:getMessage(value)
		elseif t=="." then
			return self:getMessage(value .. mark)
		elseif mark:sub(-1)=="." then
			return self:getMessage(mark .. value)
		else
			return tostring(value)
		end
	end
	local ret = msg:gsub("{(.-)}", replace)
	return csvNewlineMark and ret:gsub(csvNewlineMark, "\n") or ret
end

function Lang:getFuzzyLangTextList(text)
	if not self.mobileEditor_json_path_exchangeKV then
		return
	end
	local temp = {}
	for key, value in pairs(self.mobileEditor_json_path_exchangeKV) do
		if key:find(text) then
			temp[#temp + 1] = value
		end
	end
	return temp
end

function Lang:formatText(text)
	if not text then
		return ""
	end
	local function replace(mark)
		local t = mark:sub(2, -2)
		if t then
			return self:getMessage(t)
		end
		return mark
	end
	local newText = text:gsub("({.-})", replace)
	return self:getMessage(newText)
end

-- 格式为 {#sn} 中的n代表第n个参数,用这个参数替换对应位置
function Lang:formatMessageByIndex( str, ... )
	local params = table.pack(...)

	local msg = self:getMessage(str)

	local res = string.gsub(msg, "%{#s(%d+)%}", function (s)
		local index = tonumber(s)
		local param = params[index] or "{#s"..s.."}"
		return tostring(param)
	end)
	return res
end