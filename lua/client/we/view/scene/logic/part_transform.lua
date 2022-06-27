local Def = require "we.def"
local Meta = require "we.gamedata.meta.meta"
local Constraint = require "we.view.scene.logic.constraint"
local IWorld = require "we.engine.engine_world"
local Receptor = require "we.view.scene.receptor.receptor"
local Utils = require "we.view.scene.utils"
local IInstance = require "we.engine.engine_instance"
local Recorder = require "we.gamedata.recorder"
local Dialog = require "we.view.scene.dialog"
local Module = require "we.gamedata.module.module"

local M = {}

local operation_class = {
	init = function(self, id, position, size)
		self._id = id
		self._position = position
		self._size = size
	end,

	id = function(self)
		return self._id
	end,

	position = function(self)
		return self._position
	end,

	size = function(self)
		return self._size
	end
}

local function get_scale(s1, s2)
	return {
		x = s1.x / s2.x,
		y = s1.y / s2.y,
		z = s1.z / s2.z
	}
end

local function transform_part_position(pos, old_pos, new_pos, scale)
	return {
		x = (pos.x - old_pos.x) * scale.x + new_pos.x,
		y = (pos.y - old_pos.y) * scale.y + new_pos.y,
		z = (pos.z - old_pos.z) * scale.z + new_pos.z
	}
end

local function transform_part_size(size, scale)
	return {
		x = size.x * scale.x,
		y = size.y * scale.y,
		z = size.z * scale.z
	}
end

local function level_shapes(shape)
	local shape_list = {}
	
	local check_all
	check_all = function(obj,t)
		local ct = t or {}
		local mt ={type = obj.children[1].booleanOperation,indexs={},children={},class=obj.children[1].class}
		for _,child in ipairs(obj.children) do
			if "PartOperation" == child.class then
				table.insert(mt.children,check_all(child,ct)) 
			else
				table.insert(ct,child)
				table.insert(mt.indexs,#ct) 
			end
			if 1 < child.booleanOperation then
				mt.type = child.booleanOperation
				if "PartOperation" == child.class then
					mt.class = "Part"
				else
					mt.class = "PartOperation"
				end
			end
		end
		return mt
	end

	local level = check_all(shape,shape_list)
	
	return shape_list,level
end

local function get_all_shapes(shape)
	local shape_list = {}
	local get_all_obj
	get_all_obj = function(obj,t)
		local ct = t or {}
		if "Part" == obj.class then
			table.insert(ct,obj)
		else
			for _,child in ipairs(obj.children) do
				if "PartOperation" == child.class then
					get_all_obj(child,ct)
				else 
					if "Part" == child.class then
						table.insert(ct,child)
					end
				end
			end
		end
	end

	get_all_obj(shape,shape_list)
	
	return shape_list
end

local function set_all_shapes(shape,all)
	local index = 1
	local set_all_obj 
	set_all_obj = function(obj)
		if "Part" == obj.class then
			obj.position = all[index].position
			obj.rotation = all[index].rotation
			obj.scale = all[index].scale
			index = index + 1
		else
			for _,child in ipairs(obj.children) do
				if "PartOperation" == child.class then
					set_all_obj(child)
				else 
					if "Part" == child.class then
						child.position = all[index].position
						child.rotation = all[index].rotation
						child.scale = all[index].scale
						index = index + 1
					end
				end
			end
		end
	end
	set_all_obj(shape)
end

local function transform_children(self, list, type)
	local ret = {}

	local function replace_id(val)
		local function reg_proc()
			do
				local meta = Meta:meta("Instance")
				meta:set_processor(function(val)
					local ret = Lib.copy(val)
					ret.id = tostring(IWorld:gen_instance_id())
					-- 记录colision
					if "PartOperation" == val.class or "MeshPart" == val.class then
						--deal reuse ollision file
						if val.collisionUniqueKey and "" ~= val.collisionUniqueKey then
							ret.collisionUniqueKey = val.collisionUniqueKey
						else
							ret.collisionUniqueKey = val.id
						end
					end
					return meta:process_(ret)
				end)
			end
		end

		local function unreg_proc()
			local meta = Meta:meta("Instance")
			meta:set_processor(nil)
		end

		reg_proc()
	
		local type = assert(val[Def.OBJ_TYPE_MEMBER])
		local meta = Meta:meta(type)
		val = meta:process(val)

		unreg_proc()

		return val
	end

	--记录part被操作的类型
	local function set_boolean_operation(last_part_op, part_op)
		for index, part in ipairs(list) do
			if index == #list then
				part:set_boolean_operation(last_part_op)
			else
				part:set_boolean_operation(part_op)
			end
		end
	end

	if type == 2 then
		set_boolean_operation(2, 0)
	else
		set_boolean_operation(0, type)
	end

	--移除约束
	local function remove_constraint(part)
		local cons = Constraint:query_constraint_by_slave_id(part:id())
		if cons then
			cons:remove()
		end
		for _, child in ipairs(part:children()) do
			if child:check_base("Instance_ConstraintBase") then
				remove_constraint(child)
				part:remove_child(child)
			end
		end
	end

	for _, obj in ipairs(list) do
		remove_constraint(obj)
		-- 更换id，构造副本零件时避免覆盖原有对象id
		local val = replace_id(obj:val())
		table.insert(ret, val)
	end
	
	return ret
end

--参数2：val为第一个选中对象的数据
local function create_part_operation(map, first_val, parent, children)
	local btsKey = GenUuid()
	local op_meta = Meta:meta("Instance_PartOperation"):ctor({
		-- position = pos,
		density = first_val["density"],
		restitution = first_val["restitution"],
		friction = first_val["friction"],
		lineVelocity = first_val["lineVelocity"],
		angleVelocity = first_val["angleVelocity"],
		useAnchor = first_val["useAnchor"],
		useGravity = first_val["useGravity"],
		mass = first_val["mass"],
		material = first_val["material"],
		-- massCenter = pos,
		mergeShapesDataKey = tostring(IWorld:gen_instance_id()),
		children = children,
		btsKey = btsKey
	})

	local module = Module:module("part_operation")
	module:new_item(btsKey)

	local part_operation = parent and parent:new_child(op_meta) or map:new_instance(op_meta)
	part_operation:vnode()["rotation"] = part_operation:node():getRotation();

	return part_operation
end

local function create_part_model(map, parent, pos)
	local meta = Meta:meta("Instance_Model"):ctor({
		position = pos,
		massCenter = pos
	})
	local model = parent and parent:new_child(meta) or map:new_instance(meta)
	
	return model
end

local function find_common_parent(list)
	local Vnode = require "we.gamedata.vnode"
	local parent_table = {}
	local child_table  = {}

	--形成实例路径表，并存入母表
	for _,obj in ipairs(list) do
		local path = Vnode.path(obj:vnode())
		child_table= Lib.splitString(path,"/")
		table.insert(parent_table,child_table)
	end

	--检查
	local check = function(parent_table, index)
		--越界
		if index > #parent_table[1] then
			return false
		end
		--基准值
		local value = parent_table[1][index]
		--取出每个路径表中当前下标的值与基准值作比较
		for _,child in ipairs(parent_table) do
			if index > #child or child[index] ~= value then
				return false
			end
		end
		return true
	end

	local index = 1
	local string = ""
	while check(parent_table,index)
	do
		string = string .. child_table[index]
		index = index + 1
	end
	
	local Map = require "we.view.scene.map"
	local obj_node = Map:curr():get_node()

	for i=1,index - 2 do
		obj_node = obj_node[child_table[i]]
	end

	local id = obj_node["id"]
	if not id then
		return nil
	end
	return Map:query_instance(id)
end

local function set_select_inc(list)
	for _, part in ipairs(list) do
		part:set_select_inc(false)
	end
end

function M:init()
	self._map = nil
	self._operation_list = {}
end

function M:query_part_operation(id)
	for _,operation in ipairs(self._operation_list) do
		if operation:id() == id then
			return operation
		end
	end
end

function M:relevance_operations(map, operations)
	self._map = map
	for _,operation in ipairs(operations) do
		self:new_operation(
			operation:id(),
			operation:val()["position"],
			operation:val()["size"]
		)
	end
end

function M:new_operation(id, pos, size)
	local operation = Lib.derive(operation_class)
	operation:init(id, pos, size)
	table.insert(self._operation_list, operation)
end

--参数2combine_type：0 合并	1 相交	2 相离
function M:make_part_combine(list, combine_type,check_intersect_move)
	assert(self._map)
	--获取共同父类
	local parent = find_common_parent(list)
	--转换children
	local children = transform_children(self, list, combine_type)
	--创建union
	local part_operation = create_part_operation(self._map, list[1]:val(), parent, children)
	local empty = CSGShape.isEmpty(part_operation:node())
	if empty then
		-- union失败，则删除对象
		local op_parent = part_operation:parent()
		if op_parent then
			op_parent:remove_child(part_operation)
		else
			self._map:remove_instance(part_operation)
		end
		Dialog:signal("DIALOG_INTERSECT")
		return
	end
	-- update
	set_select_inc(list)
	local size = Utils.deseri_prop("Vector3", IInstance:get(part_operation:node(), "size"))
	local position = part_operation:node():getFixedPosition()
	part_operation:vnode()["size"] = size
	part_operation:vnode()["position"] = position
	part_operation:vnode()["massCenter"] = position
	part_operation:vnode()["rotation"] = part_operation:node():getRotation();
	part_operation:vnode()["scale"] = part_operation:node():getScale();
	part_operation:vnode()["size"] = part_operation:node():getSize();
	-- union成功，删除旧对象
	local tempparent
	for _, part in ipairs(list) do
		tempparent = part:parent()
		if tempparent then
			tempparent:remove_child(part)
		else
			self._map:remove_instance(part)
		end
	end

	return part_operation
end

--Union操作
function M:part_combine(receptor, combine_type)
	assert(self._map)
	local list = receptor:list(function(obj)
		if obj:check_part_mix(obj,"UNION") then
			return true
		end
	end)

	local part_operation = self:make_part_combine(list,combine_type,true)
	if not part_operation then return end
	part_operation:set_select_inc(false)

	receptor:clear()
	receptor:attach(part_operation:node())
end

function M:part_split(receptor)
	assert(self._map)

	local list = receptor:list(function(obj)
	if obj:class() == "PartOperation" then
		return true
	end
	end)
	Recorder:start()
	local select_nodes = {}
	local edit_nodes = {}
	for _,part_operation in ipairs(list) do
		local parent = part_operation:parent()
		local editor_shapes_data = part_operation:val().children 
		local node_shapes = {}
		local editor_new_shapes = {}
		for _, e_shape in pairs(editor_shapes_data) do 
			local cls = e_shape.class
			if "Part" == cls or "PartOperation" == cls then
				local shape
				if parent then
					shape = parent:new_child(e_shape)
				else
					shape = self._map:new_instance(e_shape)
				end
				node_shapes[#node_shapes + 1] = shape:node()
				editor_new_shapes[#editor_new_shapes + 1] = shape
			end
		end
		local transforms = part_operation:node():splitShapesForEditor(node_shapes)

		for index,transform in ipairs(transforms) do
			local child = editor_new_shapes[index]
			child:vnode()["position"] = transform:getPosition()
			child:vnode()["rotation"] = transform:getRotation()
			child:vnode()["scale"] = transform:getScale()
			child:vnode()["size"] = node_shapes[index]:getSize()
			table.insert(edit_nodes,child)
		end

		for _,child in ipairs(node_shapes) do
			table.insert(select_nodes,child)
		end
	end

	set_select_inc(list)
	for _,part_operation in ipairs(list) do
		local parent = part_operation:parent()
		if parent then
			parent:remove_child(part_operation)
		else
			self._map:remove_instance(part_operation)
		end
	end
	set_select_inc(edit_nodes)
	Receptor:select("instance", select_nodes)
	Recorder:stop()
end

--Model组合
function M:part_group(receptor)
	assert(self._map)

	local list = receptor:list(function(obj)
		if obj:check_part_mix(obj,"MODEL") then
			return true
		end
	end)
	local parent = find_common_parent(list)
	local pos = receptor:center()
	set_select_inc(list)
	local model = create_part_model(self._map, parent, pos)

	local val_table = {}
	for _,part in ipairs(list) do
		if not part:parent() then
			table.insert(val_table,self._map:remove_instance(part))
		else
			table.insert(val_table,part:parent():remove_child(part))
		end
	end

	local Map = require"we.view.scene.map"
	Map:check_constraint(val_table,model)
	model:check_child_dtor()
	model:set_select_inc(false)

	receptor:clear()
	receptor:attach(model:node())
end

function M:part_ungroup(receptor)
	assert(self._map)

	local list = receptor:list(function(obj)
		if obj:class() == "Model" then
			return true
		end
	end)
	
	local dataset = {}
	set_select_inc(list)
	for _,model in ipairs(list) do
		local parent = model:parent()
		for _,child in ipairs(model:children()) do
			table.insert(dataset,{parent,child:val()})
		end
		if parent then
			parent:remove_child(model)
		else
			self._map:remove_instance(model)
		end
	end

	local instances = {}
	for _,ds in ipairs(dataset) do
		local parent = ds[1]
		local instance
		if parent then
			instance = parent:new_child(ds[2])
		else
			instance = self._map:new_instance(ds[2])
		end
		table.insert(instances,instance)
	end



	local nodes = {}
	for _,instance in ipairs(instances) do
		Constraint:check_constraint(instance)
		table.insert(nodes, instance:node())
	end

	Receptor:select("instance", nodes)
end

M:init()

return M