local type = type
---@class Instance
---@field getByInstanceId fun(id : number) : Instance
---@field getByRuntimeId fun(id : number) : Instance
---@field getInstanceID fun(self : Instance) : number
---@field getRuntimeID fun(self : Instance) : number
---@field setParent fun(self : Instance, parent : Instance) : void
---@field getParent fun(self : Instance) : Instance
---@field addChild fun(self : Instance, child : Instance) : void
---@field removeChild fun(self : Instance, child : Instance) : void
---@field removeAllChildren fun(self : Instance) : void
---@field getChildrenCount fun(self : Instance) : number
---@field getChildAt fun(self : Instance, index : number) : Instance
---@field setProperty fun(self : Instance, name    : string, value : string) : void
---@field setPropertyByLuaTable fun(self : Instance, properties : table<string, string>) : void
---@field getProperty fun(self : Instance, name	: string) : string
---@field getAllChild fun(self : Instance) : Instance[]
---@field delAllChild fun(self : Instance) : void
---@field addToGroup fun(self : Instance, name : string, persistent : boolean) : void
---@field removeFromGroup fun(self : Instance, name : string) : void
---@field isInGroup fun(self : Instance, name : string) : boolean
---@field isA fun(self : Instance, class : string) : boolean
---@field isValid fun(self : Instance) : boolean
---@field destroy fun(self : Instance) : void
local Instance = Instance

local InstanceList = L("InstanceList", {})
Instance.InstanceList = InstanceList

local VarGet, VarSet

local function _getDef(list, name)
	local def = rawget(_G, name)
	if not def then
		return false
	end
	list[#list+1] = def
	for i = 0, 99 do
		local pn = def["__parent" .. i]
		if not pn then
			break
		end
		if not _getDef(list, pn) then
			break
		end
	end
	return true
end

local InstanceType = {}
for name, id in pairs(Instance.getInstanceClasses()) do
	InstanceType[name] = {}
	_getDef(InstanceType[name], name)
	if not next(InstanceType[name]) then
		print("Unknow instance type:", name)
	end
end

function Instance:initData()
	-- do nothing

	-- SceneUI 默认值
	if self.className == "SceneUIClient" then
		self:setIsTop(true)
		self:setIsFaceCamera(true)
		self:setRangeDistance(128)
		--self:setPosition(Lib.v3(5.45, 2.5, 25.76))
		self:setSize(Lib.v2(1, 1))
		self:setScaleWithDistance(true)
	end
end

local RootDir = Root.Instance():getGamePath()
local triggerParser = require "common.trigger_parser"

local function loadTrigger(cfg, btsPath)
	if World.isClient then
		return
	end
	cfg._btsTime = {}

	local path = btsPath
	if not path then
		assert(cfg.btsKey, "must have btsKey!!!")
		local _, fullFilePath = FileUtil.getBTSFilePathsByKey(cfg.btsKey)
		path = fullFilePath
	end

	if path and Lib.fileExists(path) then
		local triggers, msg = triggerParser.parse(path)
		if not triggers then
			--error(string.format("triggerParser parse file: '%s' error: %s", path, msg))
			return
		else
			cfg.triggers = triggers
		end
	--else
	--	print(string.format("triggerParser parse file error, bts file not found, btsKey = %s", cfg.btsKey))
	end

	Trigger.LoadTriggers(cfg)
end

local needConnect = {--注意：c++触发的事件需要先connect
	enter_scene = function(self)
		Trigger.CheckTriggers(self._cfg, "ENTER_SCENE", {part1 = self})
	end,
	ready = function(self)
		Trigger.CheckTriggers(self._cfg, "READY", {part1 = self})
	end,
	part_touch_part_begin = function(self, target)
		Trigger.CheckTriggers(self._cfg, "PART_TOUCH_PART_BEGIN", {part1 = self, part2 = target})
	end,
	part_touch_entity_begin = function(self, target)
		Trigger.CheckTriggers(self._cfg, "PART_TOUCH_ENTITY_BEGIN", {part1 = self, obj2 = target})
	end,
	part_touch_part_end = function(self, target)
		Trigger.CheckTriggers(self._cfg, "PART_TOUCH_PART_END", {part1 = self, part2 = target})
	end,
	part_touch_entity_end = function(self, target)
		Trigger.CheckTriggers(self._cfg, "PART_TOUCH_ENTITY_END", {part1 = self, obj2 = target})
	end,
}

function Instance.checkNeedConnectEvent(instance, triggerSet)
	if not instance or not triggerSet or not triggerSet[trigger_exec_type.NORMAL] then
		return
	end
	for key in pairs(triggerSet[trigger_exec_type.NORMAL]) do
		key = key:lower()
		if needConnect[key] then
			instance:connect(key, needConnect[key])
		end
	end
end

function Instance:loadTriggerByExtendCfg(extendCfg)
	if not extendCfg or not extendCfg.triggers then
		return
	end

	local cfg = self._cfg
	if not cfg then
		cfg = {}
		self._cfg = cfg
	end

	cfg._btsTime = {}
	cfg.triggers = {}
	for _, trigger in pairs(extendCfg.triggers) do
		table.insert(cfg.triggers,{type = trigger, actions = {}})
	end
	Trigger.LoadTriggers(cfg)
	cfg.instance = self
	return cfg.triggers and true or false
end

function Instance:loadTrigger(path, isKey)
	if World.isClient then
		return
	end

	if not path or path == "" then
		return
	end

	local cfg = self._cfg
	if not cfg then
		cfg = {}
		self._cfg = cfg
	end

	local btsPath
	
	if isKey then
		cfg.btsKey = path
	else
		btsPath = path
	end

	loadTrigger(cfg, btsPath)
	cfg.instance = self

	return cfg.triggers and true or false
end

function Instance:loadTriggerOnCreate(extendCfg, properties)
	if extendCfg.triggers then
		return self:loadTriggerByExtendCfg(extendCfg)
	end
	return self:loadTrigger(properties.btsKey, true)
end

function Instance:onCreated(params, map)
end

local EMPTY = setmetatable({}, { __newindex = error })
function Instance.newInstance(params, map)
	if not next(params) then
		return
	end
	Profiler:begin("Instance.newInstance")
	---@type Instance
	local instance
	local class = params.class
	local properties = params.properties or EMPTY
	local extendCfg = params.extendCfg or EMPTY
	local attributes = params.attributes or { }
	if class == "Entity" then
		instance = Instance.createEntity({
			cfgName = params.config,
			name = params.name or properties.name or "",
			map = params.map or map,
			pos = params.pos or Lib.deserializerStrV3(properties.position),
			scale = params.scale or properties.scale or nil --[["x:1 y:1 z:1"]],
			ry = params.ry,
			rp = params.rp,
		})
	elseif class == "DropItem" then
		local item = Item.CreateItem(params.config, params.count or 1, function(dropItem)
			if params.fullName == "/block" then
				dropItem:set_block_id(params.block_id or 0)
			end
		end)
		local fixRotation
		if properties.fixRotation ~= nil then
			fixRotation = properties.fixRotation
			properties.fixRotation = nil -- 使用完不再需要，防止在后面的setPropertyByLuaTable中设置脏属性
		elseif params.fixRotation ~= nil then
			fixRotation = params.fixRotation
		end
		instance = Instance.createDropItem({
			item = item,
			map = params.map or (map and map.name ),
			pos = params.pos,
			pitch = params.pitch or 0,
			yaw = params.yaw or 0,
			lifeTime = params.lifeTime,
			moveSpeed = params.moveSpeed, -- { x = 0, y = 0, z = 0 }
			moveTime = params.moveTime,
			guardTime = params.guardTime or 0,
			fixRotation = fixRotation,
		})
	elseif class == "Missile" then	-- TODO
		assert(false, "create Missile instance")
		-- instance = Missile.Create(params.config, { map = params.map, fromID = 0, targetID = 0, targetDir = 0 })
	elseif class == "VoxelTerrain" then
		assert(params.scene, "terrain needs scene!")
		instance = params.scene:getTerrain(true) -- params: isCreate
	else
		instance = Instance.Create(class)
		if instance then
			local ok = instance:loadTriggerOnCreate(extendCfg, properties)
			if ok and instance._cfg.triggerSet then
				Instance.checkNeedConnectEvent(instance, instance._cfg.triggerSet)
			end
		end
	end

	if not instance then
		Lib.logError("can not create instance: ", class)
		Profiler:finish("Instance.newInstance")
		return
	end

	local propertiesList = {}
	for key, value in pairs(properties) do
		if key ~= "customColor" then
			propertiesList[#propertiesList + 1] = key
			propertiesList[#propertiesList + 1] = value
		end
	end
	if #propertiesList > 1 then 
		instance:setPropertyByLuaTable(propertiesList, false)
	end
	
	local cusPropertiesList = {}
	for key, value in pairs(params.customProperties  or EMPTY) do
		cusPropertiesList[#cusPropertiesList + 1] = key
		cusPropertiesList[#cusPropertiesList + 1] = value
	end
	if #cusPropertiesList > 1 then 
		instance:setCustomPropertyByLuaTable(class, cusPropertiesList)
	end

	for key, value in pairs(attributes) do
		instance:setAttribute(key, value)
	end

	instance.properties = Lib.copy(properties)
	instance.isInsteance = true
	instance.extendCfg = Lib.copy(extendCfg)

	if not IS_EDITOR then
		--进入游戏加载Folder DataSet数据
		if params.class=="Folder" and (properties.isDataSet or "false") =="true" then
			params.children = Lib.read_json_file(RootDir..map.dir.."DataSet/"..properties.id..".json") or EMPTY
		end
	end

	local children = params.children or EMPTY
	for _, params in ipairs(children) do
		local child = Instance.newInstance(params, map)
		if child then
			child:setParent(instance)
			if child:isA("RegionPart") then -- region为子节点时没有加入map, 比如region在Folder对象中
				map:addSceneRegionByRegionPart(child)
			end
		end
	end
	instance:onCreated(params, map)
	
	if map then
		if class == "Entity" then
			Trigger.CheckTriggers(instance:cfg(), "ENTITY_ENTER", {obj1 = instance, key=instance:getRuntimeID()})
		end
	end
	Profiler:finish("Instance.newInstance")
	return instance
end

function Instance:clearData()
    InstanceList[self.runtimeId] = nil
end

local PropertyTypeCacheList = {}
local function getPropertyValueByType(self, key)
	local data = self:getProperty(key)
	local dataType
	if not PropertyTypeCacheList[key] then
		PropertyTypeCacheList[key] = self:getPropertyDataTypeString(key)
	end
	dataType = PropertyTypeCacheList[key]
	if data == "" or dataType == "" then
		return
	end

	local function toVector3(data)
		local vec3 = Lib.splitString(data, ": ", true)
		return {x = vec3[1], y = vec3[2], z = vec3[3]}
	end

	local function toQuaternion(data)
		local quaternion = Lib.splitString(data, ": ", true)
		return {x = quaternion[1], y = quaternion[2], z = quaternion[3], w = quaternion[4]}
	end

	if dataType:find("Vector3") then
		return toVector3(data)
	elseif dataType:find("Quaternion") then
		return toQuaternion(data)
	elseif dataType:find("float") or dataType:find("int") then
		return tonumber(data)
	elseif dataType:find("bool") then
		return data:find("true") and true or false
	else
		return data
	end
end

local function changeValueByPropertyType(self, key, value)
	if not PropertyTypeCacheList[key] then
		PropertyTypeCacheList[key] = self:getPropertyDataTypeString(key)
	end
	local valueType = PropertyTypeCacheList[key]
	local function vectorToString(data)
		return string.format("x: %s y: %s z: %s", tostring(data.x), tostring(data.y), tostring(data.z))
	end

	local function quaterniontoString(data)
		return string.format("x: %s y: %s z: %s w: %s", tostring(data.x), tostring(data.y), tostring(data.z), tostring(data.w))
	end

	local function colorToString(data)
		return string.format("r: %s g: %s b: %s a: %s", tostring(data.r), tostring(data.g), tostring(data.b), tostring(data.a))
	end

	if valueType:find("Vector3") then
		return vectorToString(value)
	elseif valueType:find("Quaternion") then
		return quaterniontoString(value)
	elseif valueType:find("Color") then
		return colorToString(value)
	else
		return tostring(value)
	end
end
local function getWindowInstance(window)
	if(window) then
		return UI:getWindowInstance(window)
	else
		return nil
	end
end

local function setWindowInstance(instance)
	if(instance) then
		return instance:getWindow()
	else
		return nil
	end
end

local function getVector3(vector3)
	return Lib.v3(vector3.x, vector3.y, vector3.z)
end

local PropertyFuncMap = 
{
	--SceneUI
	Window = {get = "getLayoutWindow", set = "setLayoutWindow", getTypeFunc = getWindowInstance, setTypeFunc = setWindowInstance},
	Layout = {get = "getLayoutFile", set = "setLayoutFile"},
	AlwaysOnTop = {get = "getIsTop", set = "setIsTop"},
	AlwaysFaceCamera = {get = "getIsFaceCamera", set = "setIsFaceCamera"},
	ViewDistance = {get = "getRangeDistance", set = "setRangeDistance"},
	ScaleWithDistance = {get = "isScaleWithDistance", set = "setScaleWithDistance"},
	Position = {get = "getPosition", set = "setPosition", getTypeFunc = getVector3},
	Rotation = {get = "getRotation", set = "setRotation", getTypeFunc = getVector3},
	LockWorldRotation = {get = "getIsLock", set = "setIsLock"},
}
local InstanceMT = L("InstanceMT", {})
function InstanceMT:__index(key)
	if not key then
		--error("Invalid instance index: "..tostring(key))
		Lib.logError("Invalid instance index: "..tostring(key))
		return
	end
	if not next(self.typeDef) then
		return
	end
	if self.removed then
	    if World.cfg.enableInstanceValidityCheck then
			error("Tried to read property \"" .. key .. "\" of an instance, but the instance is already destroyed");
		end
		
		for _, def in ipairs(self.typeDef) do
			local mem = def[key]
			if mem~=nil then
				if type(mem)=="userdata" then
					return nil
				else
					return mem
				end
			end
		end
		return nil
	end
	for _, def in ipairs(self.typeDef) do
		local mem = def[key]
		if mem~=nil then
			if type(mem)=="userdata" then
				return VarGet(self, mem)
			else
				return mem
			end
		end
	end
	if self:hasProperty(key) then
		return getPropertyValueByType(self, key)
	end
	local child = self:findFirstChild(key)
	if child then
		return child
	end
	if PropertyFuncMap[key] then
		if PropertyFuncMap[key].getTypeFunc then
			return PropertyFuncMap[key].getTypeFunc(self[PropertyFuncMap[key].get](self))
		end
		return self[PropertyFuncMap[key].get](self)
	end
	return nil
end
function InstanceMT:__newindex(key, value)
	if not next(self.typeDef) then
		return
	end
	if self.removed then
		if World.cfg.enableInstanceValidityCheck then
			error("Tried to write property \"" .. key .. "\" of an instance, but the instance is already destroyed");
		end
		rawset(self, key, value)
		return
	end
	if self.removed and not World.cfg.disableInstanceValidityCheck then
		error("Tried to write property \"" .. key .. "\" of an instance, but the instance is already destroyed");
	end
	for _, def in ipairs(self.typeDef) do
		local mem = def[key]
		if type(mem)=="userdata" then
			return VarSet(self, mem, value)
		end
	end
	if self:hasProperty(key) then
		local changeValue = changeValueByPropertyType(self, key, value)
		self:setProperty(key, changeValue)
		return
	end
	if PropertyFuncMap[key] then
		if PropertyFuncMap[key].setTypeFunc then
				local v = PropertyFuncMap[key].setTypeFunc(value)
				if v then
					return self[PropertyFuncMap[key].set](self,PropertyFuncMap[key].setTypeFunc(value))
				end
		end
		return self[PropertyFuncMap[key].set](self,value)
	end
	rawset(self, key, value)
end
function InstanceMT:__tostring()
	return string.format("%s[%d]", self.typeDef[1].__name, self.runtimeId)
end

local function InstanceWriter(runtimeId, className, isRemoved)
	local instance = InstanceList[runtimeId]
	if instance then
		return instance
	end
	instance = {
		runtimeId = runtimeId,
		className = className,
		typeDef = assert(InstanceType[className], className),
		removed = isRemoved,
		isValid = function(self)
			return not self.removed
		end,
	}
	InstanceList[runtimeId] = setmetatable(instance, InstanceMT)
	if isRemoved then
		return instance
	end
	if next(instance.typeDef) then
		instance:initData()
	end
	return instance
end

local tb = { writer = InstanceWriter, idKey = "runtimeId" }
World.CurWorld:regInstanceWriter(tb)
VarGet = tb.var_get
VarSet = tb.var_set

RETURN()
