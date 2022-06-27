local GameConfig = require "we.gameconfig"
local Map = require "we.view.scene.map"
local Def = require "we.def"
local Lfs = require "lfs"
local Module = require "we.gamedata.module.module"

local M = {}

local function collect(instances, bts_files, bts_dirs, merge_files, collision_files)
	for _, obj in ipairs(instances) do
		-- get bts
		if Def.SCENE_SUPPORT_BLUEPRINT_TYPE[obj.class] then
			bts_files[obj.btsKey .. ".bts"] = true
			bts_dirs[obj.btsKey] = true
		end
		-- get merge
		if obj.mergeShapesDataKey then
			merge_files[obj.mergeShapesDataKey .. ".json"] = true
		end
		-- get collision
		if "MeshPart" == obj.class then
			local key = "" ~= obj.collisionUniqueKey and obj.collisionUniqueKey or obj.id
			collision_files[key] = true
			-- 获取meshpart collision文件名
			if "" ~= obj.mesh then
				key = string.gsub(obj.mesh, '/', '_')
				local len = string.len(key)
				if ".mesh" == string.sub(key, len - 4) then
					key = string.sub(key, 1, len - 5)
				end
				collision_files[key] = true
			end
		elseif "PartOperation" == obj.class then
			local key = "" ~= obj.collisionUniqueKey and obj.collisionUniqueKey or obj.id
			collision_files[key] = true
		end
		collect(obj.children, bts_files, bts_dirs, merge_files, collision_files)
	end
end

-- 检查目录中需删除的文件或目录
local function check_cache_dir(chk_dir, chk_set, del_set, is_dir)
	local type = is_dir and "directory" or "file"
	local set = del_set or {} 
	for fn in Lfs.dir(chk_dir) do
		if fn ~= "." and fn ~= ".." then
			local path = Lib.combinePath(chk_dir, fn)
			local attr = Lfs.attributes(path)
			if attr.mode == type then
				if not chk_set[fn] then
					table.insert(set, path)
				end
			end
		end
	end
	return set
end

-- 清理蓝图文件和空的bts文件
local function delete_bts(bts_files, bts_dirs)
	-- 检查待删除bts文件
	local function check_bts_dir_files(chk_dir, chk_set, del_set)
		local set = del_set or {} 
		for fn in Lfs.dir(chk_dir) do
			if fn ~= "." and fn ~= ".." then
				local path = Lib.combinePath(chk_dir, fn)
				local attr = Lfs.attributes(path)
				if attr.mode == "file" then
					-- 空的bts文件全部清理
					if 0 == attr.size or not chk_set[fn] then
						table.insert(set, path)
					end
				end
			end
		end
		return set
	end

	do
		-- 清理bts文件
		local dir = Lib.combinePath(Def.PATH_GAME, "events")
		local del_files = {}
		check_bts_dir_files(dir, bts_files, del_files)
		for _,path in ipairs(del_files) do
			os.remove(path)
		end
	end

	do
		-- 清理编辑器文件夹
		local del_dirs = {}
		for _,name in pairs(Def.SCENE_SUPPORT_BLUEPRINT_TYPE) do
			local dir = Lib.combinePath(Def.PATH_GAME_META_DIR, "module", name, "item")
			check_cache_dir(dir, bts_dirs, del_dirs, true)
		end
		for _,path in ipairs(del_dirs) do
			Lib.rmdir(path)
		end
	end
end

-- 清理网格文件
local function delete_merge(merge_files)
	local dir = Def.PATH_MERGESHAPESDATA
	local del_files = {}
	check_cache_dir(dir, merge_files, del_files)
	for _,path in ipairs(del_files) do
		os.remove(path)
	end
end

-- 清理collision文件
local function delete_collision(collision_files)
	local del_files = {}

	local dir_list = {"part_collision", "meshpart_collision"}
	for _,name in ipairs(dir_list) do
		local dir = Lib.combinePath(Def.PATH_GAME, name)
		check_cache_dir(dir, collision_files, del_files)
	end

	for _,path in ipairs(del_files) do
		os.remove(path)
	end
end

function M:clean_cache()
	if not GameConfig:disable_block() then
		return
	end
	-- 收集场景中的蓝图和网格文件
	local bts_files = {}
	local bts_dirs = {}
	local merge_files = {}
	local collision_files = {}
	for _, map in pairs(Map:maps()) do
		local node = map:get_node()
		local instances = node.__tree:value().instances
		collect(instances, bts_files, bts_dirs, merge_files, collision_files)
	end

	delete_bts(bts_files, bts_dirs)

	delete_merge(merge_files)

	delete_collision(collision_files)
end

return M