local autoTimer
local displayData = {}
local data = {}
local frameState = Root.Instance():frameState()

local debugMessageShown = false

local dataContext = {
	Title = 1,		--标题
	DataFormat = 2,	--数据格式
	DataFunc = 3,	--获取数据的方法
	IsShow = 4,		--是否显示
}

local function stopTimer()
	if autoTimer then
		autoTimer()
		autoTimer = nil
	end
end

local function autoTimerFunc(self)
	stopTimer()
	self:update()
	autoTimer = World.Timer(10, function ()
		self:update()
		return true
	end)
end

function M:init(...)
	self.close_btn = self:child("close_btn")
	self.close_btn.onMouseClick = function ()
		self:close()
	end

	self.item = self:child("item")
	self.basic_list = self:child("basic_list")
	self.memory_list = self:child("memory_list")

	self:init_list(...)

	self.mode = "basic"
	self.basic_list:setVisible(true)
	self.memory_list:setVisible(false)

	self.btn_bg = self:child("btn_bg")

	self.basic_btn = self:child("basic_btn")
	self.basic_btn.onSelectStateChanged = function(btn, _)
		if btn:isSelected() then
			if self.mode ~= "basic" then
				self.mode = "basic"
			end
			autoTimerFunc(self)
			local pos = btn:getPosition()
			pos[1][2] = 1
			self.btn_bg:setPosition(pos)
			btn:setAlpha(1)
			self.basic_list:setVisible(true)
		else
			btn:setAlpha(0.7)
			self.basic_list:setVisible(false)
		end
	end

	self.memory_btn = self:child("memory_btn")
	self.memory_btn.onSelectStateChanged = function(btn, _)
		if btn:isSelected() then
			if self.mode ~= "memory" then
				self.mode = "memory"
			end
			autoTimerFunc(self)
			local pos = btn:getPosition()
			pos[1][2] = 1
			self.btn_bg:setPosition(pos)
			btn:setAlpha(1)
			self.memory_list:setVisible(true)
		else
			btn:setAlpha(0.7)
			self.memory_list:setVisible(false)
		end
	end

	--self:setAlwaysOnTop(true)
end

function M:onOpen(...)
	debugMessageShown = CGame.instance:isDebugMessageShown()
	CGame.instance:toggleDebugMessageShown(false)
	PerformanceStatistics.SetCPUTimerEnabled(true)
	PerformanceStatistics.SetGPUTimerEnabled(true)
	self:init(...)
	autoTimerFunc(self)
end

function M:onClose()
	stopTimer()
	PerformanceStatistics.SetCPUTimerEnabled(false)
	PerformanceStatistics.SetGPUTimerEnabled(false)
	CGame.instance:toggleDebugMessageShown(debugMessageShown)
end

function M:onHidden()
	stopTimer()
end

function M:onShown()
	autoTimerFunc(self)
end

function M:init_list(count)
	if count then
		count = 2
	else
		count = 1
	end
	for i = 1, count do
		local table = displayData["basic"]
		for k, v in ipairs(table) do
			if v[dataContext.IsShow] == true then
				local child = self.item:clone()
				child:setVisible(true)
				self.basic_list:addChild(child)
				child:child("l_c"):setText(v[dataContext.Title])
				v.content = child:child("r_c")
			end
		end

		local table = displayData["memory"]
		for k, v in ipairs(table) do
			if v[dataContext.IsShow] == true then
				local child = self.item:clone()
				child:setVisible(true)
				self.memory_list:addChild(child)
				child:child("l_c"):setText(v[dataContext.Title])
				v.content = child:child("r_c")
			end
		end
	end
end

local function needUpdate(window, key, format_str, value)
	if not window then
		return
	end
	if data[key] ~= value then
		data[key] = value
		local content = string.format(format_str, value)
		window:setText(content)
	end
end

function M:update()
	if self.mode == "basic" then
		frameState = Root.Instance():frameState()
	end
	local table = displayData[self.mode]
	for k, v in ipairs(table) do
		local func = v[dataContext.DataFunc]
		if func then
			needUpdate(v.content, v[dataContext.Title], v[dataContext.DataFormat], func())
		end
	end
end

-- ========================================
-- basic
-- ========================================
local function getMsFormNs(ns)
	return ns/1000000
end

local function getFPS()
	return Root.Instance():getRealFPS()
end

local function getCpuMain()
	return getMsFormNs(PerformanceStatistics.GetCPULastFrameRecordTotalTime())
end

local function getCpuRenderThread()
	return getMsFormNs(PerformanceStatistics.GetGPULastFrameRecordTotalTime())
end

local function getBatches()
	return frameState:getDrawCalls()
end

local function getTris()
	return frameState:getTriangleNum()
end

local function getVerts()
	return frameState:getVertexNum()
end

local function getSetPassCalls()
	return frameState:getSwitchShaderTimes()
end

displayData["basic"] = {
	{"FPS:",					"%.0f",		getFPS,				true},
	{"CPU-Main:",				"%.2fms",	getCpuMain,			true},
	{"CPU-Render thread:",		"%.2fms",	getCpuRenderThread,	true},
	{"Batches:",				"%s",		getBatches,			true},
	{"Tris:",					"%s",		getTris,			true},
	{"Verts:",					"%s",		getVerts,			true},
	{"SetPass calls:",			"%s",		getSetPassCalls,	true}
}

-- ========================================
-- memory
-- enum ClassIDType
-- {
-- 	DefineClassID(ObjectStat, 0)
-- 	DefineClassID(Part,1)
-- 	DefineClassID(PartOperation, 2)
-- 	DefineClassID(MeshPart, 3)
-- 	DefineClassID(Texture, 4)
-- 	DefineClassID(Mesh, 5)
--	DefineClassID(Entity, 6)
--	DefineClassID(Animation, 7)
-- };
-- 1.根据内存量自动换算单位：0B≤内存<1024B，则使用单位B；1KB≤内存<1024KB，则使用单位KB；以此类推。
-- 2.保留两位小数。
-- ========================================
local size_data = {}
local classIDType = {
	ObjectStat = 0,
	Part = 1,
	PartOperation = 2,
	MeshPart = 3,
	Texture = 4,
	Mesh = 5,
	Entity = 6,
	Animation = 7,
	Audio = 8,

	End = 8
}
local memoryProfiler = MemoryProfiler.Instance()
local tdAudioEngine = TdAudioEngine.Instance()

local function getMemoryCount(type)
	if type == classIDType.Audio then
		return tdAudioEngine:getPlaySoundNum()
	else
		return memoryProfiler:getCount(type)
	end
end

local function getMemorySize(type)
	if type == classIDType.Audio then
		return tdAudioEngine:getMemorySize()
	else
		return memoryProfiler:getMemorySize(type)
	end
end

local format_list = {
	"%.0fB",
	"%.2fKB",
	"%.2fMB",
	"%.2fGB",
	"%.2fTB",
}
local function toMemorySizeString(size)
	local index = 1
	while(size >= 1024 and index + 1 <= #format_list) do
		size = size / 1024
		index = index + 1
	end
	return string.format(format_list[index], size)
end

local function toMemoryString(size)
	return getMemoryCount(size) .. "/" .. toMemorySizeString(size_data[size])
end

local function getTotalMemory()
	local total = 0
	for i = 1, classIDType.End do
		size_data[i] = getMemorySize(i)
		total = total + size_data[i]
	end
	return toMemorySizeString(total)
end

local function getTexturesMemory()
	return toMemoryString(classIDType.Texture)
end

local function getMeshesMemory()
	return toMemoryString(classIDType.Mesh)
end

local function getPartsMemory()
	return toMemoryString(classIDType.Part)
end

local function getMeshPartsMemory()
	return toMemoryString(classIDType.MeshPart)
end

local function getUnionsMemory()
	return toMemoryString(classIDType.PartOperation)
end

local function getEntitiesMemory()
	return toMemoryString(classIDType.Entity)
end

local function getAnimationMemory()
	return toMemoryString(classIDType.Animation)
end

local function getAudioMemory()
	return toMemoryString(classIDType.Audio)
end

displayData["memory"] = {
	{"Total:",					"%s",		getTotalMemory,		false},
	{"Textures Count/Memory:",	"%s",		getTexturesMemory,	true},
	{"Meshes Count/Memory:",	"%s",		getMeshesMemory,	true},
	{"Parts Count/Memory:",		"%s",		getPartsMemory,		true},
	{"MeshParts Count/Memory:",	"%s",		getMeshPartsMemory,	true},
	{"Unions Count/Memory:",	"%s",		getUnionsMemory,	true},
	{"Entities Count/Memory:",	"%s",		getEntitiesMemory,	true},
	{"Animation Count/Memory:",	"%s",		getAnimationMemory,	true},
	{"Audio Count/Memory:",		"%s",		getAudioMemory,		true}
}
