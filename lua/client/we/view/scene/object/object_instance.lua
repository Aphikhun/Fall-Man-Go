local Def = require "we.def"
local Signal = require "we.signal"

local Meta = require "we.gamedata.meta.meta"
local VN = require "we.gamedata.vnode"
local Recorder = require "we.gamedata.recorder"

local Bunch = require "we.view.scene.bunch"
local Utils = require "we.view.scene.utils"

local Object = require "we.view.scene.object.object"
local Receptor = require "we.view.scene.receptor.receptor"

local IWorld = require "we.engine.engine_world"
local IScene = require "we.engine.engine_scene"
local IInstance = require "we.engine.engine_instance"

local Base = require "we.view.scene.object.object_base"
local CW = World.CurWorld
local M = Lib.derive(Base)

M.SIGNAL = {
	DESTROY				= "DESTROY",
	GEOMETRIC_CHANGED	= "GEOMETRIC_CHANGED",
	NAME_CHANGED		= "NAME_CHANGED",
	SELECTED_CHANGED	= "SELECTED_CHANGED"
}

M.ABILITY = {
	MOVE				= 1 << 1,
	SCALE				= 1 << 2,
	ROTATE				= 1 << 3,
	TRANSFORM			= 1 << 1 | 1 << 2 | 1 << 3,
	AABB				= 1 << 4,
	HAVELENGTH			= 1 << 5,
	ANCHORSPACE			= 1 << 6,
	FOCUS 				= 1 << 7,
	FORCE_UPRIGHT		= 1 << 8,
	SELECTABLE			= 1 << 9,
}

local CLASS_ABILITY = {
	["Part"] = M.ABILITY.TRANSFORM | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["PartOperation"] = M.ABILITY.TRANSFORM | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["Model"] = M.ABILITY.TRANSFORM | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["MeshPart"] = M.ABILITY.TRANSFORM | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["AudioNode"] = M.ABILITY.MOVE | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["RodConstraint"] = M.ABILITY.HAVELENGTH | M.ABILITY.ANCHORSPACE,
	["SpringConstraint"] = M.ABILITY.HAVELENGTH | M.ABILITY.ANCHORSPACE,
	["RopeConstraint"] = M.ABILITY.HAVELENGTH | M.ABILITY.ANCHORSPACE,
	["SliderConstraint"] = M.ABILITY.ANCHORSPACE,
	["Entity"] = M.ABILITY.TRANSFORM | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.FORCE_UPRIGHT | M.ABILITY.SELECTABLE,
	["DropItem"] = M.ABILITY.AABB | M.ABILITY.MOVE | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["RegionPart"] = M.ABILITY.MOVE | M.ABILITY.SCALE | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
	["VoxelTerrain"] = M.ABILITY.FOCUS,
	["Light"] = M.ABILITY.MOVE | M.ABILITY.ROTATE | M.ABILITY.AABB | M.ABILITY.FOCUS | M.ABILITY.SELECTABLE,
}


local PRECISION = 0.01

local function on_transform(self)
	Signal:publish(self, M.SIGNAL.GEOMETRIC_CHANGED)

	if self._parent then
		on_transform(self._parent)
	end
end

-- 可以由引擎主动修改的属性(通常是场景操作，可以批量操作)，为了效率需要做以下考虑
-- 因为是被动属性所以不需要 RECORDE，撤销主属性，它也会调用到这里跟着变
-- 因为属性面板是由 Bunch 统一管理，所以也不需要 SYNC
-- 它们不会再触发其它的属性关联所以也不需要 NOTIFY
-- 特殊对待 SYNC 标记， 目前有 position、rotation、size
local function on_position_changed(self)
	local meta = VN.meta(self._vnode)
	if meta:is("Instance_CSGShape") then
		VN.assign(self._vnode, "massCenter", self._vnode["position"], VN.CTRL_BIT.NONE)
	end

	-- 基于效率考虑拖动过程中统一设置而不是单个 obj 设置
	if not self._on_drag then
		on_transform(self)
	end
end

local function on_rotation_changed(self)
	if not self._on_drag then
		on_transform(self)
	end
end

local function check_effect_part_transform(self)
	VN.assign(
		self._vnode,
		"position", 
		Utils.deseri_prop("Vector3", IInstance:get(self._node, "position")),
		VN.CTRL_BIT.NONE
	)

	VN.assign(
		self._vnode,
		"rotation", 
		Utils.deseri_prop("Vector3", IInstance:get(self._node, "rotation")),
		VN.CTRL_BIT.NONE
	)
end

local function on_size_changed(self)
	if not self._vnode["scale"] then
		return
	end

	VN.assign(
		self._vnode,
		"scale", 
		Utils.deseri_prop("Vector3", IInstance:get(self._node, "scale")),
		VN.CTRL_BIT.NONE
	)

	local meta = VN.meta(self._vnode)
	if meta:is("Instance_CSGShape") then
		local volume = IInstance:get_volume(self._node)
		VN.assign(
			self._vnode, 
			"volume",
			volume,
			VN.CTRL_BIT.NONE
		)
		VN.assign(
			self._vnode,
			"mass",
			volume * self._vnode["density"],
			VN.CTRL_BIT.NONE
		)
	end

	if not self._on_drag then
		on_transform(self)
	end
end

-- 引擎有些计算会延迟，所以在某些属性改变的时候需要主动刷新
local function update_node(self)
	if self._node:isA("PartOperation") then
		-- self._node:updateShape()
		VN.assign(
			self._vnode, 
			"size", 
			Utils.deseri_prop("Vector3", IInstance:get(self._node, "size")),
			VN.CTRL_BIT.NOTIFY
		)
	end
end

-- thoes property can changed by engine
local property_monitor = {
	["position"] = function(self, value)
		local curr = self._vnode["position"]
		if math.abs(curr.x - value.x) < PRECISION and
		   math.abs(curr.y - value.y) < PRECISION and
		   math.abs(curr.z - value.z) < PRECISION then
		   -- 非引擎主动修改
		   return
		end

		if self._on_drag then
			self._record["position"] = self._record["position"] or {}
			self._record["position"].from = self._record["position"].from or VN.value(curr)
			self._record["position"].to = value
			VN.assign(self._vnode, "position", value, VN.CTRL_BIT.NONE)

			-- gitmoz移动3D音效时，更新相对坐标
			if self._vnode["relative_pos"] and self._parent then	
				local pos = self._node:getLocalPosition()
				VN.assign(self._vnode, "relative_pos", pos, VN.CTRL_BIT.NONE)
			end

			on_position_changed(self)
		else
			self._vnode["position"] = value
		end
	end,

	["rotation"] = function(self, value)
		local curr = self._vnode["rotation"]
		if math.abs(curr.x - value.x) < PRECISION and
		   math.abs(curr.y - value.y) < PRECISION and
		   math.abs(curr.z - value.z) < PRECISION then
		   -- 非引擎主动修改
		   return
		end

		if self:check_ability(M.ABILITY.FORCE_UPRIGHT) then
			value.x = 0
			value.z = 0
		end

		if self._on_drag then
			self._record["rotation"] = self._record["rotation"] or {}
			self._record["rotation"].from = self._record["rotation"].from or VN.value(curr)
			self._record["rotation"].to = value

			VN.assign(self._vnode, "rotation", value, VN.CTRL_BIT.NONE)
			on_rotation_changed(self)
		else
			self._vnode["rotation"] = value
		end
	end,

	["size"] = function(self, value)
		local curr = self._vnode["size"]
		if math.abs(curr.x - value.x) < PRECISION and
		   math.abs(curr.y - value.y) < PRECISION and
			math.abs(curr.z - value.z) < PRECISION then
			-- 非引擎主动修改
			return
		end

		if self._on_drag then
			self._record["size"] = self._record["size"] or {}
			self._record["size"].from = self._record["size"].from or VN.value(curr)
			self._record["size"].to = value

			VN.assign(self._vnode, "size", value, VN.CTRL_BIT.NONE)
			on_size_changed(self)
		else
			self._vnode["size"] = value
		end
	end,

	["scale"] = function(self, value)
		local curr = self._vnode["scale"]
		if math.abs(curr.x - value.x) < PRECISION and
		   math.abs(curr.y - value.y) < PRECISION and
			math.abs(curr.z - value.z) < PRECISION then
			-- 非引擎主动修改
			return
		end

		if self._on_drag then
			self._record["scale"] = self._record["scale"] or {}
			self._record["scale"].from = self._record["scale"].from or VN.value(curr)
			self._record["scale"].to = value

			VN.assign(self._vnode, "scale", value, VN.CTRL_BIT.NONE)
			on_size_changed(self)
		else
			self._vnode["scale"] = value
		end
	end,

	["originSize"] = function(self, value)
		local curr = self._vnode["originSize"]
		if not curr then
			return
		end
		if math.abs(curr.x - value.x) < PRECISION and
		   math.abs(curr.y - value.y) < PRECISION and
			math.abs(curr.z - value.z) < PRECISION then
			-- 非引擎主动修改
			return
		end

		if self._on_drag then
			self._record["originSize"] = self._record["originSize"] or {}
			self._record["originSize"].from = self._record["originSize"].from or VN.value(curr)
			self._record["originSize"].to = value

			VN.assign(self._vnode, "originSize", value, VN.CTRL_BIT.NONE)
			on_size_changed(self)
		else
			self._vnode["originSize"] = value
		end
	end,

	["volume_changed"] = function(self, value)
		if value <= 0.0 then
			return
		end

		local meta = VN.meta(self._vnode)
		if meta:is("Instance_CSGShape") then
			local mass = self._vnode["density"] * value
			VN.assign(self._vnode, "volume", value, VN.CTRL_BIT.NONE)
			VN.assign(self._vnode, "mass", mass, VN.CTRL_BIT.NONE)
		end
	end,

	["light_actived"] = function(self)
		local actived = self._vnode["lightActived"]
		if not actived then
			return
		end
		--引擎调用，不存在复亮的情况
		VN.assign(self._vnode, "lightActived", false, VN.CTRL_BIT.NONE)
	end
}

--支持合批的零件类型
local batch_enable_types = {
	Part = true, 
	PartOperation = true, 
	MeshPart = true
}

local model_mixed_batch_type = "__ARRAY_MIX_ITEM"

--只设置model自己的合批类型，会在router中向父节点传递，不向子节点传递
--通知属性面板，notify走router流程，不记录，因为不是用户直接操作的model
local function set_model_self_batch_type(model,is_mixed, batch_type)
	model._dont_set_child = true
	if is_mixed then
		VN.assign(model._vnode,"batchType", model_mixed_batch_type, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.SYNC)
	else
		if batch_type then
			VN.assign(model._vnode,"batchType", batch_type, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.SYNC)
		end
	end
	model._dont_set_child = nil
end

local function is_model_batch_type_mixed(obj)
	assert(obj:class() == "Model")

	local model_batch_type = nil
	for idx,child in ipairs(obj:children()) do
		local cur_type = nil
		local child_cls = child:class()
		if child_cls == "Model" then
			if child._vnode["batchType"] == model_mixed_batch_type then
				return true, nil
			else 
				cur_type = child._vnode["batchType"]
			end
		elseif batch_enable_types[child_cls] then
			cur_type = child._vnode["batchType"]
		end
						
		if model_batch_type == nil then
			model_batch_type = cur_type
		else
			if model_batch_type~=cur_type then
				return true, nil
			end
		end
	end
	return false, model_batch_type
end --function is_model_batch_type_mixed(obj)

local router = {
	["^name"] = function(self, event, oval)
		IInstance:set(self._node,"name",self._vnode["name"])
		if self._node:isA("Entity") then
			self._node:setName(self._vnode["name"])
			self._node:updateShowName()
		end
		Signal:publish(self, M.SIGNAL.NAME_CHANGED, self._vnode["name"])
	end,

	["^selected_count"] = function(self,event,oval)
		if not self._selected_inc then
			if self._vnode["selected"] then
				self._vnode["selected"] =  false --is_select
			end
			self._vnode["selected"] = true
		end
	end,

	["^selected$"] = function(self,event,oval)
		self:on_selected(self._vnode["selected"])
		Signal:publish(self, M.SIGNAL.SELECTED_CHANGED,self._vnode["selected"])
	end,

	["^isLockedInEditor"] = function(self, event, oval)
		IInstance:set(self._node,"isLockedInEditor",tostring(self:locked()))
	end,

	["^isVisibleInEditor"] = function(self,event,oval)
		IInstance:set(self._node,"isVisibleInEditor",tostring(self:enabled()))
		IInstance:set_selectable(self._node, self:enabled())
	end,

	["^children$"] = function(self, event, index, oval)
		if event == Def.NODE_EVENT.ON_INSERT then
			local vnode = self._vnode["children"][index]
			local child = Object:create("instance", vnode, self)
			IInstance:set_parent(child:node(), self:node())
			table.insert(self._children, index, child)
			local trans = child._vnode["transform"]
			if trans then
				local pos = self:node():getPosition()
				local rotate = self:node():getRotation()
				child:node():setPosition({x = pos.x, y = pos.y, z = pos.z})
				child:node():setRotation({x = rotate.x, y = rotate.y, z = rotate.z})
			end
			
			if self:class() == "Model" then
				local batch_type = self._vnode["batchType"]

				if batch_type ~= model_mixed_batch_type then
					self._dont_set_child = true
					if child._vnode["batchType"] ~= batch_type then
						VN.assign(self._vnode,"batchType", model_mixed_batch_type, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.SYNC)
					end
					self._dont_set_child = nil
				end
			end
		elseif event == Def.NODE_EVENT.ON_REMOVE then
			local child = table.remove(self._children, index)

			if self:class()=="Model" then
				local is_mixed, batch_type = is_model_batch_type_mixed(self)
				set_model_self_batch_type(self,is_mixed,batch_type) 
			end

			child:dtor()
		end

		-- update_node(self)
	end,

	["^position"] = function(self, event, oval)
		IInstance:set(self._node, "position", Utils.seri_prop("Vector3", self._vnode["position"]))
		on_position_changed(self)
	end,

	["^rotation"] = function(self, event, oval)
		IInstance:set(self._node, "rotation", Utils.seri_prop("Vector3", self._vnode["rotation"]))
		on_rotation_changed(self)
	end,

	["^scale$"] = function(self, event, oval)
		IInstance:set(self._node, "scale", Utils.seri_prop("Vector3", self._vnode["scale"]))
	end,

	["^scale/x"] = function(self, event, oval)
		IInstance:set_scale_x(self._node, self._vnode["scale"]["x"])
	end,

	["^scale/y"] = function(self, event, oval)
		IInstance:set_scale_y(self._node, self._vnode["scale"]["y"])
	end,

	["^scale/z"] = function(self, event, oval)
		IInstance:set_scale_z(self._node, self._vnode["scale"]["z"])
	end,

	["^size$"] = function(self, event, oval)
		IInstance:set(self._node, "size", Utils.seri_prop("Vector3", self._vnode["size"]))
		on_size_changed(self)
	end,

	["^size/x"] = function(self, event, oval)
		IInstance:set_size_x(self._node, self._vnode["size"]["x"])
		on_size_changed(self)
	end,
	
	["^size/y"] = function(self, event, oval)
		IInstance:set_size_y(self._node, self._vnode["size"]["y"])
		on_size_changed(self)
	end,
	
	["^size/z"] = function(self, event, oval)
		IInstance:set_size_z(self._node, self._vnode["size"]["z"])
		on_size_changed(self)
	end,
	
	["^mass$"] = function(self, event, oval)
		IInstance:set(self._node, "mass", tostring(self._vnode["mass"]))
	end,

	["^restitution"] = function(self, event, oval)
		IInstance:set(self._node, "restitution", tostring(self._vnode["restitution"]))
	end,

	["^friction"] = function(self, event, oval)
		IInstance:set(self._node, "friction", tostring(self._vnode["friction"]))
	end,

	["^lineVelocity"] = function(self, event, oval)
		IInstance:set(self._node, "lineVelocity", Utils.seri_prop("Vector3", self._vnode["lineVelocity"]))
	end,

	["^angleVelocity"] = function(self, event, oval)
		IInstance:set(self._node, "angleVelocity", Utils.seri_prop("Vector3", self._vnode["angleVelocity"]))
	end,

	["^useAnchor"] = function(self, event, oval)
		IInstance:set(self._node, "useAnchor", tostring(self._vnode["useAnchor"]))
	end,
	["^cameraCollideEnable"] = function(self, event, oval)
		IInstance:set(self._node, "cameraCollideEnable", tostring(self._vnode["cameraCollideEnable"]))
	end,

	["^partNavMeshType"] = function(self, event, oval)
		IInstance:set(self._node, "partNavMeshType", tostring(self._vnode["partNavMeshType"]))
	end,

	
	["^staticObject"] = function(self, event, oval)
		IInstance:set(self._node, "staticObject", tostring(self._vnode["staticObject"]))
	end,

	["^selectable"] = function(self, event, oval)
		IInstance:set(self._node, "selectable", tostring(self._vnode["selectable"]))
	end,
	["^needSync"] = function(self, event, oval)
		IInstance:set(self._node, "needSync", tostring(self._vnode["needSync"]))
	end,

	["^bloom"] = function(self, event, oval)
		IInstance:set(self._node, "bloom", tostring(self._vnode["bloom"]))
	end,

	["^useGravity"] = function(self, event, oval)
		IInstance:set(self._node, "useGravity", tostring(self._vnode["useGravity"]))
	end,

	["^density"] = function(self, event, oval)
		self._vnode["mass"] = self._vnode["density"] * self._vnode["volume"]
		IInstance:set(self._node, "density", tostring(self._vnode["density"]))
	end,

	["^collisionUniqueKey"] = function(self, event, oval)
		IInstance:set(self._node, "collisionUniqueKey", tostring(self._vnode["collisionUniqueKey"]))
	end,

	["^collisionFidelity$"] = function(self, event, oval)
		IInstance:set(self._node, "collisionFidelity", self._vnode["collisionFidelity"])
	end,
	
	["^material/color"] = function(self, event, oval)
		IInstance:set(self._node, "materialColor", Utils.seri_prop("Color", self._vnode["material"]["color"]))
	end,

	["^material/texture"] = function(self, event, oval)
		IInstance:set(self._node, "materialTexture", Utils.seri_prop("PartTexture", self._vnode["material"]["texture"]))
	end,

	["^material/offset"] = function(self, event, oval)
		IInstance:set(self._node, "materialOffset", Utils.seri_prop("Vector3", self._vnode["material"]["offset"]))
	end,

	["^material/alpha"] = function(self, event, oval)
		IInstance:set(self._node, "materialAlpha", tostring(self._vnode["material"]["alpha"]))
	end,

	["^material/useTextureAlpha"] = function(self, event, oval)
		IInstance:set(self._node, "useTextureAlpha", tostring(self._vnode["material"]["useTextureAlpha"]))
	end,

	["^material/discardAlpha"] = function(self, event, oval)
		IInstance:set(self._node, "discardAlpha", tostring(self._vnode["material"]["discardAlpha"]))
	end,

	["^csgShapeVisible"] = function(self, event, oval)
		IInstance:set(self._node, "visible", tostring(self._vnode["csgShapeVisible"]))
	end,

	["^csgShapeEffect/asset"] = function(self, event, oval)
		IInstance:set(self._node, "effectFilePath", tostring(self._vnode["csgShapeEffect"]["asset"]))
	end,

	["^transform/pos"] = function(self, event, oval)
		local pos = {x = 0, y = 0, z = 0}
		pos.x = self._vnode["transform"]["pos"]["x"]
		pos.y = self._vnode["transform"]["pos"]["y"]
		pos.z = self._vnode["transform"]["pos"]["z"]
	    self._node:setLocalPosition(pos)
		check_effect_part_transform(self)
	end,

	["^transform/rotate"] = function(self, event, oval)
		local rotate = {x = 0, y = 0, z = 0}
		rotate.x = self._vnode["transform"]["rotate"]["x"]
		rotate.y = self._vnode["transform"]["rotate"]["y"]
		rotate.z = self._vnode["transform"]["rotate"]["z"]
		self._node:setLocalRotation(rotate)
		check_effect_part_transform(self)
	end,

	["^relative_pos"] = function(self, event, oval)
		local pos = {x = 0, y = 0, z = 0}
		pos.x = self._vnode["relative_pos"]["x"]
		pos.y = self._vnode["relative_pos"]["y"]
		pos.z = self._vnode["relative_pos"]["z"]
	    self._node:setLocalPosition(pos)
		VN.assign(
			self._vnode,
			"position", 
			Utils.deseri_prop("Vector3", IInstance:get(self._node, "position")),
			VN.CTRL_BIT.NONE
		)
	end,

	["^loop/enable"] = function(self, event, oval)
		if self._vnode["loop"]["enable"]  then
			IInstance:set(self._node, "loopCount", tostring(-self._vnode["loop"]["play_times"]))
		else
			IInstance:set(self._node, "loopCount", tostring(self._vnode["loop"]["play_times"]))
		end
	end,

	["^loop/play_times"] = function(self, event, oval)
		if self._vnode["loop"]["enable"] then
			IInstance:set(self._node, "loopCount", tostring(-self._vnode["loop"]["play_times"]))
		else
			IInstance:set(self._node, "loopCount", tostring(self._vnode["loop"]["play_times"]))
		end
	end,

	["^loop/interval"] = function(self, event, oval)
		IInstance:set(self._node, "loopInterval", tostring(self._vnode["loop"]["interval"]))
	end,

	["^loop/reset"] = function(self, event, oval)
		IInstance:set(self._node, "loopReset", tostring(self._vnode["loop"]["reset"]))
	end,

	["^shape"] = function(self, event, oval)
		IInstance:set_shape(self._node, tostring(self._vnode["shape"]))
	end,

	["^slavePartID"] = function(self, event, oval)
		IInstance:set(self._node, "slavePartID", tostring(self._vnode["slavePartID"]))
	end,

	["^masterLocalPos"] = function(self, event, oval)
		local master_pivot = IWorld:get_instance(self._node:getMasterPivotID())
		local instance = IInstance:get_parent(self._node)
		local pos = instance:toWorldPosition(self._vnode["masterLocalPos"])
		IInstance:set_world_pos(master_pivot,pos)
	end,

	["^masterWorldPos"] = function(self, event, oval)
		local master_pivot = IWorld:get_instance(self._node:getMasterPivotID())
		IInstance:set_world_pos(master_pivot,self._vnode["masterWorldPos"])
	end,

	["^slaveLocalPos"] = function(self, event, oval)
		local slave_pivot = IWorld:get_instance(self._node:getSlavePivotID())
		local instance = IWorld:get_instance(self._node:getSlavePartID())
		if instance then
			local pos = instance:toWorldPosition(self._vnode["slaveLocalPos"])
			IInstance:set_world_pos(slave_pivot,pos)
		end
	end,

	["^slaveWorldPos"] = function(self, event, oval)
		local slave_pivot = IWorld:get_instance(self._node:getSlavePivotID())
		IInstance:set_world_pos(slave_pivot,self._vnode["slaveWorldPos"])
	end,

	["^collision$"] = function(self, event, oval)
		IInstance:set(self._node, "collision", tostring(self._vnode["collision"]))
	end,

	["^useSpring"] = function(self, event, oval)
		IInstance:set(self._node, "useSpring", tostring(self._vnode["useSpring"]))
	end,

	["^stiffness"] = function(self, event, oval)
		IInstance:set(self._node, "stiffness", tostring(self._vnode["stiffness"]))
	end,

	["^damping"] = function(self, event, oval)
		IInstance:set(self._node, "damping", tostring(self._vnode["damping"]))
	end,

	["^springTargetAngle"] = function(self, event, oval)
		IInstance:set(self._node, "springTargetAngle", tostring(self._vnode["springTargetAngle"]))
	end,

	["^angleUpperLimit"] = function(self, event, oval)
		IInstance:set(self._node, "angleUpperLimit", tostring(self._vnode["angleUpperLimit"]))
	end,

	["^angleLowerLimit"] = function(self, event, oval)
		IInstance:set(self._node, "angleLowerLimit", tostring(self._vnode["angleLowerLimit"]))
	end,

	["^useMotor"] = function(self, event, oval)
		IInstance:set(self._node, "useMotor", tostring(self._vnode["useMotor"]))
	end,

	["^motorTargetAngleVelocity"] = function(self, event, oval)
		IInstance:set(self._node, "motorTargetAngleVelocity", tostring(self._vnode["motorTargetAngleVelocity"]))
	end,

	["^useAngleLimit"] = function(self, event, oval)
		IInstance:set(self._node, "useAngleLimit", tostring(self._vnode["useAngleLimit"]))
	end,

	["^angleUpperLimit"] = function(self, event, oval)
		IInstance:set(self._node, "angleUpperLimit", tostring(self._vnode["angleUpperLimit"]))
	end,

	["^angleLowerLimit"] = function(self, event, oval)
		IInstance:set(self._node, "angleLowerLimit", tostring(self._vnode["angleLowerLimit"]))
	end,

	["^motorForce"] = function(self, event, oval)
		IInstance:set(self._node, "motorForce", tostring(self._vnode["motorForce"]))
	end,

	["^radius"] = function(self, event, oval)
		IInstance:set(self._node, "radius", tostring(self._vnode["radius"]))
	end,

	["^length"] = function(self, event, oval)
		IInstance:set(self._node, "length", tostring(self._vnode["length"]))
	end,

	["^visible"] = function(self, event, oval)
		IInstance:set(self._node, "visible", tostring(self._vnode["visible"]))
	end,

	["^fixedJustify"] = function(self, event, oval)
		IInstance:set(self._node, "fixedJustify", tostring(self._vnode["fixedJustify"]))
	end,

	["^thickness"] = function(self, event, oval)
		IInstance:set(self._node, "thickness", tostring(self._vnode["thickness"]))
	end,

	["^coil"] = function(self, event, oval)
		IInstance:set(self._node, "coil", tostring(self._vnode["coil"]))
	end,

	["^color"] = function(self, event, oval)
		IInstance:set(self._node, "color", Utils.seri_prop("Color", self._vnode["color"]))
	end,

	["^upperLimit"] = function(self, event, oval)
		IInstance:set(self._node, "upperLimit", tostring(self._vnode["upperLimit"]))
	end,

	["^lowerLimit"] = function(self, event, oval)
		IInstance:set(self._node, "lowerLimit", tostring(self._vnode["lowerLimit"]))
	end,
	
	["^booleanOperation"] = function(self, event, oval)
		IInstance:set(self._node, "booleanOperation", tostring(self._vnode["booleanOperation"]))
	end,

	["^decalOffset"] = function(self, event, oval)
		local val = { x = self._vnode["decalOffset"].x, y = self._vnode["decalOffset"].y, z = 0 }
		IInstance:set(self._node, "decalOffset", Utils.seri_prop("Vector3", val))
	end,

	["^decalColor"] = function(self, event, oval)
		IInstance:set(self._node, "decalColor", Utils.seri_prop("Color", self._vnode["decalColor"]))
	end,

	["^decalAlpha"] = function(self, event, oval)
		IInstance:set(self._node, "decalAlpha", tostring(self._vnode["decalAlpha"]))
	end,

	["^decalSurface"] = function(self, event, oval)
		IInstance:set(self._node, "decalSurface", tostring(self._vnode["decalSurface"]))
	end,

	["^decalImageType"] = function(self, event, oval)
		IInstance:set(self._node, "decalImageType", tostring(self._vnode["decalImageType"]))
	end,

	["^decalTiling"] = function(self, event, oval)
		local val = { x = self._vnode["decalTiling"].x, y = self._vnode["decalTiling"].y, z = 0 }
		IInstance:set(self._node, "decalTiling", Utils.seri_prop("Vector3", val))
	end,

	["^decalTexture/asset"] = function(self, event, oval)
		IInstance:set(self._node, "decalTexture", self._vnode["decalTexture"]["asset"])
	end,

	["^force"] = function(self, event, oval)
		IInstance:set(self._node,"force",Utils.seri_prop("Vector3",self._vnode["force"]))
	end,

	["^useRelativeForce"] = function(self, event, oval)
		IInstance:set(self._node,"useRelativeForce",tostring(self._vnode["useRelativeForce"]))
	end,

	["^torque"] = function(self, event, oval)
		IInstance:set(self._node,"torque",Utils.seri_prop("Vector3",self._vnode["torque"]))
	end,

	["^useRelativeTorque"] = function(self, event, oval)
		IInstance:set(self._node,"useRelativeTorque",tostring(self._vnode["useRelativeTorque"]))
	end,

	["^customThreshold"] = function(self, event, oval)
		IInstance:set(self._node,"customThreshold",tostring(self._vnode["customThreshold"]))
	end,

	["^mesh"] = function(self, event, oval)
		IInstance:set(self._node,"mesh",tostring(self._vnode["mesh"]))
	end,

	["^roughness"] = function(self, event, oval)
		IInstance:set(self._node,"roughness",tostring(self._vnode["roughness"]))
	end,

	["^metalness"] = function(self, event, oval)
		IInstance:set(self._node,"metalness",tostring(self._vnode["metalness"]))
	end,
	
	["^fixRotation"] = function(self, event, oval)
		IInstance:set(self._node,"fixRotation",tostring(not self._vnode["fixRotation"]))
	end,

	["^autoAnchor"] = function(self, event, oval)
		IInstance:set(self._node,"autoAnchor",tostring(self._vnode["autoAnchor"]))
	end,
	["^isTop"] = function(self, event, oval)
		IInstance:set(self._node,"isTop",tostring(self._vnode["isTop"]))
	end,

	["^isFaceCamera"] = function(self, event, oval)
		IInstance:set(self._node,"isFaceCamera",tostring(self._vnode["isFaceCamera"]))
	end,

	["^rangeDistance"] = function(self, event, oval)
		IInstance:set(self._node, "rangeDistance", tostring(self._vnode["rangeDistance"]))
	end,

	["^layoutFile/asset"] = function(self, event, oval)
		local path = self._vnode["layoutFile"]["asset"]
		local asset_path = string.sub(path,7,string.len(path))
		IInstance:set(self._node, "layoutFile", asset_path)
	end,

	["^uiScaleMode"] = function(self, event, oval)
		IInstance:set(self._node, "uiScaleMode", self._vnode["uiScaleMode"] and "0" or "1")
	end,

	["^stretch"] = function(self, event, oval)
		IInstance:set(self._node, "stretch", tostring(self._vnode["stretch"]))
	end,

	["^isLock$"] = function(self, event, oval)
		IInstance:set(self._node, "isLock", tostring(self._vnode["isLock"]))
	end,

	["^staticBatchNo"] = function(self, event, oval)
		if self:class() == "MeshPart" then
			return
		end

		IInstance:set(self._node, "staticBatchNo", tostring(self._vnode["staticBatchNo"]))

		if self._vnode["staticBatchNo"] and 0 < #self._vnode["staticBatchNo"] then
			self._vnode["enableStaticBatching"] = true
		end
	end,

	["^batchType$"] = function(self, event, oval)

		local function set_model_batch_type(obj, batching_type)
			assert(obj:class() == "Model")

			obj._setting_batching_type = true
			for idx,child in ipairs(obj:children()) do
				if child._vnode["batchType"] ~= batching_type then
					child._setting_batching_type = true
					VN.assign(child._vnode,"batchType",batching_type, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.SYNC)
					child._setting_batching_type = nil
				end
			end
			obj._setting_batching_type = nil
		end

		local cls = self:class()
		if cls == "Model" then
			IInstance:set_batch_type(self._node, tostring(self._vnode["batchType"]))
			if self._dont_set_child == nil and self._vnode["batchType"]~= model_mixed_batch_type then
				set_model_batch_type(self,self._vnode["batchType"])
			end
		elseif batch_enable_types[cls] then
			IInstance:set_batch_type(self._node, tostring(self._vnode["batchType"]))
		end

		local parent = self:parent()
		if parent and parent._setting_batching_type then
			return
		end
		while (parent)
		do
			if parent:class() == "Model" then
				local oval = parent._vnode["batchType"]
				local is_mixed, batch_type = is_model_batch_type_mixed(parent)
				local nval = nil
				if is_mixed then
					nval = model_mixed_batch_type
				else
					nval = batch_type
				end

				if oval == nval then
					break
				end

				if nval then
					parent._dont_set_child = true
					VN.assign(parent._vnode, "batchType", nval, VN.CTRL_BIT.SYNC)
					parent._dont_set_child = nil
				end

			end
			parent = parent:parent()
		end
	end,

	["^collisionFidelity$"] = function(self, event, oval)
		IInstance:set(self._node, "collisionFidelity", self._vnode["collisionFidelity"])
	end,

	["^lightType"] = function(self, event, oval)
		IInstance:set(self._node, "lightType", tostring(self._vnode["lightType"]))
	end,

	["^skyColor"] = function(self, event, oval)
		IInstance:set(self._node, "skyColor", Utils.seri_prop("Color", self._vnode["skyColor"]))
	end,

	["^skyLineColor"] = function(self, event, oval)
		IInstance:set(self._node, "skyLineColor", Utils.seri_prop("Color", self._vnode["skyLineColor"]))
	end,

	["^lightColor"] = function(self, event, oval)
		IInstance:set(self._node, "lightColor", Utils.seri_prop("Color", self._vnode["lightColor"]))
	end,

	["^lightBrightness"] = function(self, event, oval)
		IInstance:set(self._node, "lightBrightness", tostring(self._vnode["lightBrightness"]))
	end,

	["^lightRange"] = function(self, event, oval)
		IInstance:set(self._node, "lightRange", tostring(self._vnode["lightRange"]))
	end,

	["^lightAngle"] = function(self, event, oval)
		IInstance:set(self._node, "lightAngle", tostring(self._vnode["lightAngle"]))
	end,

	["^lightLength"] = function(self, event, oval)
		IInstance:set(self._node, "lightLength", tostring(self._vnode["lightLength"]))
	end,

	["^lightWidth"] = function(self, event, oval)
		IInstance:set(self._node, "lightWidth", tostring(self._vnode["lightWidth"]))
	end,

	["^lightActived"] = function(self, event, oval)
		IInstance:set(self._node, "lightActived", tostring(self._vnode["lightActived"]))
	end,

	["^shadows/shadowsType"] = function(self, event, oval)
		IInstance:set(self._node, "shadowsType", tostring(self._vnode["shadows"]["shadowsType"]))
	end,

	["^shadows/shadowsIntensity"] = function(self, event, oval)
		IInstance:set(self._node, "shadowsIntensity", tostring(self._vnode["shadows"]["shadowsIntensity"]))
	end,

	["^shadows/shadowsOffset"] = function(self, event, oval)
		IInstance:set(self._node, "shadowsOffset", tostring(self._vnode["shadows"]["shadowsOffset"]))
	end,

	["^shadows/shadowsPresicion"] = function(self, event, oval)
		IInstance:set(self._node, "shadowsPresicion", tostring(self._vnode["shadows"]["shadowsPresicion"]))
	end,

	["^shadows/shadowsDistance"] = function(self, event, oval)
		IInstance:set(self._node, "shadowsDistance", tostring(self._vnode["shadows"]["shadowsDistance"]))
	end,
}

function M.inject(name, updater)
	router["^"..name] = updater
end

function M:init(vnode, parent)
	assert(VN.check_type(vnode, "Instance"))

	Base.init(self, "instance", vnode)
	-- self._transform = Transform.build()
	self._raw_ctor = true
	self._node = nil
	self._parent = parent
	self._children = {}
	self._invalid = false
	self._lightGizmo = nil

	self._record = {}
	self._on_drag = false
	local beyond = parent ~= nil
	local cls = vnode["class"]
	local is_op = "PartOperation" == vnode["class"] 
	if is_op and parent == nil then
		beyond = true
	end
	
	self._node = assert(IWorld:create_instance(
		Utils.export_inst(
			VN.value(vnode), 
			true
		), beyond,
		{not_only_engine = true}
	))

	if vnode["id"] == "" then
		self._vnode["id"] = tostring(IWorld:gen_instance_id())
	end

	if vnode["volume"] == 0 then
		-- self._node:updateShape()
		self._vnode["volume"] = IInstance:get_volume(self._node)
		self._vnode["mass"] = self._vnode["density"] * self._vnode["volume"]
	end
	
	if self:check_ability(M.ABILITY.SELECTABLE) then
		IInstance:set_selectable(self._node, self:enabled())
	end

	-- 遍历 children
	if is_op then
		local childs = {}
		for _, v in ipairs(vnode["children"]) do
			local child = Object:create("instance",v,self)
			local child = Object:create("instance", v, self)
			if "Part" == v.class or "PartOperation" == v.class then
				table.insert(childs,child:node())
			else
				IInstance:set_parent(child:node(), self:node())
			end
			table.insert(self._children, child)
		end
		self._node:setCSGChildren(childs)
	else		
		for _, v in ipairs(vnode["children"]) do
			local child = Object:create("instance", v, self)
			IInstance:set_parent(child:node(), self:node())
			table.insert(self._children, child)
		end
	end

	self._router = Signal:subscribe(self._vnode, Def.NODE_EVENT.ON_MODIFY, function(path, event, index, ...)
		path = table.concat(path, "/")
		if event == Def.NODE_EVENT.ON_ASSIGN then
			path = path == "" and index or path .. "/" .. index
		end

		local captures = nil
		for pattern, processor in pairs(router) do
			captures = table.pack(string.find(path, pattern))
			if #captures > 0 then
				local args = {}
				for i = 3, #captures do
					table.insert(args, math.tointeger(captures[i]) or captures[i])
				end
				for _, arg in ipairs({...}) do
					table.insert(args, arg)
				end
				if event == Def.NODE_EVENT.ON_ASSIGN then
					processor(self, event, table.unpack(args))
				else
					processor(self, event, index, table.unpack(args))
				end

				break
			end
		end
	end)

	if nil == parent then
		if is_op then
			self:child_dtor(true)
		else
			self:check_child_dtor()
		end
	elseif not parent._raw_ctor then
		self:check_child_dtor()
	end

	self._cancel = {}
	for name in pairs(property_monitor) do
		local cancel = self._node:listenPropertyChange(name, function(inst, old, new)
			local processor = assert(property_monitor[name], name)
			if processor then
				processor(self, new)
			end
			
		end)

		table.insert(self._cancel, cancel)
	end

	-- if nil == parent then
	-- 	local vn_size = self._vnode["size"] 
	-- 	if self._node["getSize"] and vn_size then
	-- 		local size = self._node:getSize()
	-- 		VN.assign(self._vnode, "size", size, VN.CTRL_BIT.NONE)
	-- 	end
	-- end


	if cls == "Model" then
		local is_mixed, batch_type = is_model_batch_type_mixed(self)

		self._dont_set_child = true
		if is_mixed then
			VN.assign(self._vnode,"batchType", model_mixed_batch_type, VN.CTRL_BIT.NONE)
		else
			if batch_type ~= nil then
				VN.assign(self._vnode,"batchType", batch_type, VN.CTRL_BIT.NONE)
			end
		end
		self._dont_set_child = nil

	end

	self._raw_ctor = nil
	--TODO PartOperation size 引擎和编辑器对不上引擎最新版本代码已经修复，待引擎代码合并最新分支行要修改
	if cls=="MeshPart" then
		local size=self._node:getSize()
		VN.assign(self._vnode, "size", size, VN.CTRL_BIT.NONE)
		on_size_changed(self)
	end
end

function M:check_child_dtor()
	local cls = self:class()
 	if "Model" == cls or "Folder" == cls then
		for _,child in ipairs(self:children()) do
			child:check_child_dtor()
		end
	elseif "PartOperation" == cls then
		self:child_dtor()
	end
end

function M:child_dtor(isSetParent)
	local manager = CW:getSceneManager()
	local scene = manager:getOrCreateScene(CW.CurMap.obj)

	if isSetParent then
		IInstance:set_parent(self._node, scene:getRoot())
	end

	for _,child in ipairs(self:children()) do
		if child:check_base("Instance_CSGShape") then
			child:dtor()
		end
	end
end


function M:dtor()
	for _, child in ipairs(self._children) do
		child:dtor()
	end

	self._invalid = true
	Signal:publish(self, M.SIGNAL.DESTROY)

	for _, cancel in ipairs(self._cancel) do
		cancel()
	end
	self._cancel = {}

	if self._node then
		-- TODO author:rcz split() need file name is content self:getMergeShapesDataKey()!
		-- if  self._node:isA("PartOperation") then
		-- 	self._node:onRemovedByEditor()
		-- end
		IWorld:remove_instance(self._node)
		self._node = nil
	end

	if self._lightGizmo then
		self._lightGizmo:destroy()
		self._lightGizmo = nil
	end

	Base.dtor(self)
	if self._router then
		self._router()
	end
end
---------------------------------------
-- parent & children
function M:parent()
	return self._parent
end

function M:children()
	return self._children
end

function M:new_child(val)
	if not val.id or val.id == "" then
		val.id = tostring(IWorld:gen_instance_id())
	end
	VN.insert(self._vnode["children"], nil, val)
	return assert(self:query_child(val.id), tostring(val.id))
end

function M:remove_child(obj)
	for idx, child in ipairs(self._children) do
		if child == obj then
			local val = VN.remove(self._vnode["children"], idx)
			return val
		end
	end

	assert(false, "can 't find child")
end

function M:query_child(id)
	for _, child in ipairs(self._children) do
		if child:check(id) then
			return child
		else
			local cc = child:query_child(id)
			if cc then
				return cc
			end
		end
	end
end

function M:root()
	if self._parent then
		return self._parent:root()
	else
		return self
	end
end

--------------------------------------------------------------
-- setter/getter vnode

function M:id()
	return self._vnode["id"]
end

function M:class()
	return self._vnode["class"]
end

function M:name()
	return self._vnode["name"]
end

function M:locked()
	return self._vnode["isLockedInEditor"]
end

function M:enabled()
	return self._vnode["isVisibleInEditor"]
end

function M:btskey()
	return self._vnode["btsKey"]
end

function M:module()
	local map = {
		["Entity"] = "entity",
		["DropItem"] = "item"
	}
	local class = self:class()
	return map[class]
end

function M:config()
	return self._vnode["config"]
end

function M:size()
	return Lib.copy(self._vnode["size"])
end

function M:selected()
	return self._vnode["selected"]
end

function M:set_select(flag, on)
	if self._invalid then
		return
	end
	
	local show = on and true or flag
	IInstance:set_select(self._node, show)
	self._vnode["selected"] = flag
end

function M:set_select_inc(flag, on)
	self:set_select(flag,on)
	local c = self._vnode["selected_count"] or 0
	self._selected_inc =  true
	self._vnode["selected_count"] = c + 1
	self._selected_inc = nil
end

function M:set_boolean_operation(operation)
	self._vnode["booleanOperation"] = operation
end

function M:set_master_local_pos(pos)
	self._vnode["masterLocalPos"] = pos
end

function M:master_local_pos()
	return self._vnode["masterLocalPos"]
end

function M:set_master_world_pos(pos)
	self._vnode["masterWorldPos"] = pos
end

function M:master_world_pos()
	return self._vnode["masterWorldPos"]
end

function M:set_slave_local_pos(pos)
	self._vnode["slaveLocalPos"] = pos
end

function M:slave_local_pos()
	return self._vnode["slaveLocalPos"]
end

function M:set_slave_world_pos(pos)
	self._vnode["slaveWorldPos"] = pos
end

function M:slave_world_pos()
	return self._vnode["slaveWorldPos"]
end

function M:set_length(length)
	self._vnode["length"] = length
end

function M:set_anchor_space(space)
	self._vnode["anchorSpace"] = tostring(space)
end

function M:set_slave_part_name(name)
	self._vnode["slavePartName"] = name
end

function M:set_slave_part_id(id)
	self._vnode["slavePartID"] = id
end

function M:slave_part_id()
	return self._vnode["slavePartID"]
end

function M:set_master_part_name(name)
	self._vnode["masterPartName"] = name
end

function M:set_translucence()
	local alpha = self._vnode["material"]["alpha"]
	alpha = (alpha > 0.5) and 0.5 or alpha
	IInstance:set(self._node,"materialAlpha",tostring(alpha))
end

function M:recover_translucence()
	local alpha = self._vnode["material"]["alpha"]
	IInstance:set(self._node,"materialAlpha",tostring(alpha))
end

-------------------------------------------------------------
-- common utils

function M:transform()
	return self._transform
end

function M:local_position()
	if self._parent	then
		local parent_position = self._parent:val()["position"]
		local position = self:val()["position"]
		local local_pos = Lib.v3cut(parent_position, position)
		return local_pos
	end
	return {x = 0, y = 0, z = 0}
end

function M:transform_set_position(position)
	assert(self._transform)
	self._transform:setPosition(position)
end

function M:transform_set_rotation(rotation)
	assert(self._transform)
	self._transform:setRotation(rotation)
end

function M:transform_set_scale(scale)
	assert(self._transform)
	self._transform:setScale(scale)
end

function M:set_selectable(flag)
	assert(self._node)
	IInstance:set_selectable(self._node, flag)
end

function M:setLocked(lockedstate)
    if self._invalid then
		return
	end
	self._vnode["isLockedInEditor"] = lockedstate
end

function M:rotation()
	assert(self._node)
	return IInstance:rotation(self._node)
end

function M:check(id)
	--assert(self._node)
	if not self._node then
		return false
	end
	if not math.tointeger(id) then
		return IInstance:id(self._node) == IInstance:id(id)	-- id is node
	end
	return IInstance:id(self._node) == math.tointeger(id)	-- id maybe string
end

function M:on_selected(selected)
	local receptor
	if self:check_base("Instance_ConstraintBase") then
		receptor = Receptor:bind("constraint")
	else
		receptor = Receptor:bind("instance")
	end

	if selected then
		receptor:attach(self:node())
		local manager = CW:getSceneManager()
		if self._vnode["class"] == "Light" then
			self._lightGizmo = GizmoLight:create()
			self._lightGizmo:setSelect(self._node)
			manager:addLightGizmo(self._lightGizmo)
		end
	else
		receptor:detach(self:node())
		if self._lightGizmo then
			self._lightGizmo:destroy()
			self._lightGizmo = nil
		end
	end
end

function M:check_ability(type)
	local class = self._vnode["class"]
	local ability = CLASS_ABILITY[class]
	return ability and (ability & type > 0) or false
end

function M:check_base(type)
	local meta = Meta:meta(self._vnode.__OBJ_TYPE)
	return meta:inherit(type)
end

function M:value()
	return VN.value(self._vnode)
end

function M:on_drag()
	for _, child in ipairs(self._children) do
		child:on_drag()
	end
	self._on_drag = true
end

function M:on_drop()
	for _, child in ipairs(self._children) do
		child:on_drop()
	end

	if self._record.position then
		VN.assign(self._vnode, "position", self._record.position.from, VN.CTRL_BIT.NONE)
		VN.assign(self._vnode, "position", self._record.position.to, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.RECORDE)
	end

	if self._record.rotation then
		VN.assign(self._vnode, "rotation", self._record.rotation.from, VN.CTRL_BIT.NONE)
		VN.assign(self._vnode, "rotation", self._record.rotation.to, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.RECORDE)
	end

	if self._record.size then
		VN.assign(self._vnode, "size", self._record.size.from, VN.CTRL_BIT.NONE)
		VN.assign(self._vnode, "size", self._record.size.to, VN.CTRL_BIT.NOTIFY | VN.CTRL_BIT.RECORDE)
	end

	self._record = {}
	self._on_drag = false
end

--零件操作检查
function M:check_part_mix(obj,operation)
	local type_table = operation == "MODEL" and Def.SCENE_MODEL_TYPE or Def.SCENE_UNION_TYPE
	local type  = obj:class()
	if type_table[string.upper(type)] then
		return true
	end
	return false
end

function M:isGlobalLight()
	return self:node().lightType == "GlobalLight"
end

function M:get_light_gizmo()
	return self._lightGizmo
end



return M
