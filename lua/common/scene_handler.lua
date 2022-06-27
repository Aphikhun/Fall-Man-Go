---@type Instance
local Instance = Instance
local sceneHandles = T(SceneHandler, "sceneHandles", {})
local lastHandleId = T(SceneHandler, "lastHandleId", 0)

local moveNodes = {}

local function getHandleId()
	lastHandleId = lastHandleId + 1
	SceneHandler.lastHandleId = lastHandleId
	return lastHandleId
end

local function bindMoveNodeFuncKey(instance)
	local moveNodeID = instance:getInstanceID()
	local funcKey = instance:getCallBackFuncKey()
	moveNodes[moveNodeID] = {
		func = MoveNode[funcKey],
		jump = MoveNode.jump,
		ins = instance
	}
end

local function unbindMoveNodeFuncKey(instance)
	local moveNodeID = instance:getInstanceID()
	if not moveNodes[moveNodeID] then
		return
	end
	moveNodes[moveNodeID] = nil
end

local function moveNodeJump(instance, dir)
	local moveNodeID = instance:getInstanceID()
	local moveNode = moveNodes[moveNodeID]
	moveNode:jump(dir)
end

local moveNodeEventHandle = {
	bind_func_key = bindMoveNodeFuncKey,
	unbind_func_key = unbindMoveNodeFuncKey,
	move_node_jump = moveNodeJump,
}

local function saveMeshPartCollisionInfo(meshPartResPath)
	local temp = meshPartResPath:gsub("/", "_")
	local dirPath = Root.Instance():getGamePath() .. "meshpart_collision"
	local path = "meshpart_collision/" .. temp .. ".json"
	local table = {}

	if not Lib.fileExists(dirPath) then
		lfs.mkdir(dirPath)
	end

	if Lib.fileExists(Root.Instance():getGamePath() .. path) then
		return
	end

	MeshPartManager.Instance():getCollisionInfoAsTable(table, meshPartResPath)
	Lib.saveGameJson(path, table)
end

local function deleteMeshPartCollisionInfo(meshPartResPath)
	local temp = meshPartResPath:gsub("/", "_")
	local filePath = Root.Instance():getGamePath() .. "meshpart_collision/" .. temp .. ".json"
	if not Lib.fileExists(filePath) then
		return
	end
	os.remove(filePath)
end

local meshMgr = {
	mesh_load = saveMeshPartCollisionInfo,
	mesh_remove = deleteMeshPartCollisionInfo,
}

function scene_event(instance, signalKey, argsTable)
	-- print("scene_event!", instance, signalKey, table.unpack(argsTable))
	if not instance or not instance:isValid() then
		return
	end
	signalKey = signalKey:lower()
	if meshMgr[signalKey] then
		meshMgr[signalKey](table.unpack(argsTable))
		return
	end

	local moveNodeFunc = moveNodeEventHandle[signalKey]
	if moveNodeFunc then
		moveNodeFunc(instance, argsTable)
		return
	end
	
	local targetID = instance:getRuntimeID()
	local signalMap = sceneHandles[targetID]
	if not signalMap then
		return
	end
	local signal = signalMap[signalKey]
	if not signal then
		return
	end
	for _, func in pairs(signal.handles) do
		func(instance, table.unpack(argsTable))
	end
end

local function disconnect(instance, signalKey, handleId)
	local targetID = instance:getRuntimeID()
	local signalMap = assert(sceneHandles[targetID], targetID)
	local signal = assert(signalMap[signalKey], signalKey)
	signal.handles[handleId] = nil
	if not next(signal.handles) then
		instance:unsubscribeSceneEvent(signalKey, signal.signalId)
		signalMap[signalKey] = nil
	end
end

-- local test = {
-- 	[InstanceID] = {
-- 		[signalKey] = {
-- 			signalId = 0,
-- 			handles = {}
-- 		}
-- 	}
-- }

local needSetCheckTouchEvent = {
	part_touch_part_begin = true,
	part_touch_part_end = true,
	part_touch_entity_begin = true,
	part_touch_entity_end = true,
}

local function connect(instance, signalKey, handle)
	signalKey = signalKey:lower()
	local targetID = instance:getRuntimeID()

	local signalMap = sceneHandles[targetID]
	if not signalMap then
		signalMap = {}
		sceneHandles[targetID] = signalMap
	end

	local signal = signalMap[signalKey]
	if not signal or not next(signal) then
		local signal1 = {
			signalId = instance:subscribeSceneEvent(signalKey),
			handles = {},
		}
		signalMap[signalKey] = signal1
	end
	signal = signalMap[signalKey]
	local handleId = getHandleId()
	signal.handles[handleId] = handle

	if needSetCheckTouchEvent[signalKey] then
		instance:setCheckTouchEvent(true)
	end
	local function cancel()
		disconnect(instance, signalKey, handleId)
	end
	return cancel
end

local function autoConnectDestroyEvent(instance)
	local signalKey = "on_destroy"
	local targetID = instance:getRuntimeID()

	local signal, signalMap

	signalMap = sceneHandles[targetID]
	if not signalMap then
		goto doDonnect
	end

	signal = signalMap[signalKey]
	if not signal or not next(signal) then
		goto doDonnect
	end

	if signalMap[signalKey] then
		--no need 
		return
	end

	::doDonnect::
	return connect(instance, signalKey, function ()
		sceneHandles[targetID] = nil
	end)
end

--signalKey, handle
function Instance:listenPropertyChange(...)
	autoConnectDestroyEvent(self)
	return connect(self, ...)
end

--signalKey, handle
function Instance:connect(...)
	autoConnectDestroyEvent(self)
	return connect(self, ...)
end

function Instance.runAllMoveNodeTick()
	for _, moveMode in pairs(moveNodes) do
		moveMode:func(moveMode.ins)
	end
end

-- 为了兼容2047，2049，2050使用的节点系统API写的临时兼容性代码
-- 兼容代码开始
local old_Instance_connect = Instance.connect
function Instance:connect(signal, target, method, ...)
	if type(target) == "function" then
		return old_Instance_connect(self, signal, target, method, ...)
	end
	local disconnector = old_Instance_connect(self, signal, function(source, ...)
		local test = {...}
		target[method](target, ...)
	end, ...)
	if target.destroyCallback then
		table.insert(target.destroyCallback, disconnector)
	end
	return disconnector
end

rawset(_G, "defineNode", function(name, nodeName)
	local nodeClass = {}
	rawset(_G, name, nodeClass)

	function nodeClass.Create(...)
		local node = Instance.Create(nodeName or "MovableNode") --Spatial
		for k, v in pairs(nodeClass) do
			if k ~= "Create" then
				node[k] = v
			end
		end

		node.destroyCallback = {}
		local real_destroy = node.destroy
		function node:destroy()
			for _, v in pairs(self.destroyCallback) do
				v()
			end
			real_destroy(self)
		end

		if node.init then
			node:init(...)
		end

		return node
	end
end)
-- 兼容代码结束