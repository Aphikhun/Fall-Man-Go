local Cjson = require "cjson"
local Def = require "we.def"
local Lfs = require "lfs"
local Seri = require "we.gamedata.seri"
local ItemDataUtils = require "we.gamedata.item_data_utils"
local Converter = require "we.gamedata.export.data_converter"
local ItemBase = require "we.gamedata.module.class.item_base"
local Meta = require "we.gamedata.meta.meta"
local PropImport = require "we.gamedata.module.prop_import"
local Map = require "we.map"
local Utils = require "we.view.scene.utils"
local EngineFile = require "we.view.scene.create_engine_file"
local GameConfig = require "we.gameconfig"
local Core = require "editor.core"

local M = Lib.derive(ItemBase)

local MODULE_NAME = "map"
local ITEM_TYPE = "MapCfg"
local DATA_SET_FOLDER = "DataSet"

local PATH_DATA_DIR = Lib.combinePath(Def.PATH_GAME, MODULE_NAME)

function M:on_modify(reload, no_store)
	if no_store then
		return
	end
	self:set_modified(true)
	if reload then
		self:flush()
		Map:reload_map(self:id())
	end
	self:update_props_cache()
	Lib.emitEvent(Event.EVENT_EDITOR_DATA_MODIFIED, self._module:name(), self._id)
end

local function check_remove_operation_child(obj)
	local function remove_operation_child(obj)
		local children = {}
		for _, child in ipairs(obj.children) do
			local meta = Meta:meta(child["__OBJ_TYPE"])
			if not meta:inherit("Instance_CSGShape") then
				table.insert(children,child)
			end
		end
		obj.children = children
	end

	if "PartOperation" == obj.class then
		remove_operation_child(obj)
	elseif "Model" == obj.class or "Folder" == obj.class then
		for _,child in ipairs(obj.children) do
			check_remove_operation_child(child)
		end
	end
end

--天空盒贴图(引擎顺序:right、left、top、bottom、back、front)
local function convert_texture(texture)
	local function convert(text)
		if not text then
			return ""
		elseif "@" == string.sub(text, 1, 1) then
			return string.sub(text, 2)
		else
			return text
		end
	end

	return {
		right	= { asset = convert(texture[1]) },
		left	= { asset = convert(texture[2]) },
		top		= { asset = convert(texture[3]) },
		bottom	= { asset = convert(texture[4]) },
		back	= { asset = convert(texture[5]) },
		front	= { asset = convert(texture[6]) }
	}
end

--加载数据
function M:load_data()
	return function()
		local item_path = Lib.combinePath(Def.PATH_GAME_META_DIR,
			"module", self._module:name(),
			"item",	self._id,
			"setting.json")
		local data = Lib.read_json_file(item_path)
		assert(data.data, item_path)

		-- load folder data set
		local folderPath = Lib.combinePath(Def.PATH_GAME_META_DIR, "module", self._module:name(), "item", self._id, self.folderConfig.folder_name)
		self.folderConfig:load_folder_editor(data.data.instances, folderPath)
		return data.data
	end
end

--[FolderDataSet]导出节点资源数据（编辑器）
function M:export_folder_editor(val)
	local folderPath = Lib.combinePath(Def.PATH_GAME_META_DIR, "module", self._module:name(), "item", self._id, self.folderConfig.folder_name)
	return self.folderConfig:export_folder_editor(val, folderPath)
end

--[FolderDataSet]清理节点资源数据（编辑器）
function M:clear_folder_editor(exportFiles)
	local folderPath = Lib.combinePath(Def.PATH_GAME_META_DIR, "module", self._module:name(), "item", self._id, self.folderConfig.folder_name)
	self.folderConfig:clear_folder(folderPath, exportFiles)
end

M.config = {
	{
		key = "setting.json",

		dataSetKey = "DataSet",
	
		reader = function(item_name, raw, item)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			local content = Lib.read_file(path, raw)
			--读取时，导入引擎节点资源数据（计算节点资源各个文件的md5，编辑器数据和引擎数据不同时，以引擎数据为准）
			local contentMd5 = ""
			local exportFiles = {}
			if content then
				contentMd5 = content ~= "" and Core.md5(content) or ""

				local setting = Cjson.decode(content)
				local folderPath = Lib.combinePath(PATH_DATA_DIR, item_name, item.folderConfig.folder_name)
				item.folderConfig:load_folder_engine(setting.scene, folderPath, exportFiles)
				content = Lib.toJson(setting)
			end
			return content, contentMd5, exportFiles
		end,

		--content引擎数据，ref编辑器数据，item类
		import = function(content, ref, item)
			local setting = Cjson.decode(content)

			local props = {
				canAttack			= PropImport.original,
				canBreak			= PropImport.original,
				fog = function(v)
					local ret = {
						hideFog = true,
						start = v.start,
						density = v.density and { value = v.density }
					}
					if v.start and v["end"] then
						ret.range = v["end"] - v.start
					end
					if v.color then
						ret.color = { 
							r = (v.color.x or 1) * 255, 
							g = (v.color.y or 1) * 255, 
							b = (v.color.z or 1) * 255 
						}
					end
					return ret
				end
			}
			
			for k, v in pairs(setting) do
				if type(props[k]) == "function" then
					ref[k] = props[k](v)
				end
			end

			ref.touch_pos = {}
			ref.touch_pos.down = setting.touchPosY and setting.touchPosY.touchdownPosY or -30.00
			ref.touch_pos.up = setting.touchPosY and setting.touchPosY.touchupPosY or 720.00
			--光源全局参数
			ref.blinn = setting.blinn == 1 and true or false
			ref.hdr = setting.hdr == 1 and true or false
			ref.reinhard = setting.reinhard
			ref.exposure = setting.exposure
			--ret.gamma = setting.gamma
			--ret.ambientStrength = setting.ambientStrength

			--天空盒
			do
				--天空盒切换模式
				local type = setting.skyBoxMode
				local base
				if setting.skyBox and next(setting.skyBox) then
					--处理之前没有保存skyBoxMode的情况
					if not type or "" == type then
						if #setting.skyBox > 1 or setting.skyBox[1].time then
							type = "dynamic_switch"
						else
							type = "static_display"
						end
					end
					if "static_display" == type then
						--天空盒静态贴图
						if setting.skyBox[1].texture then
							base = convert_texture(setting.skyBox[1].texture)
							base[Def.OBJ_TYPE_MEMBER] = "SkyBoxStatic"
						end
					elseif "dynamic_switch" == type then
						--天空盒动态贴图
						base = {
							[Def.OBJ_TYPE_MEMBER] = "SkyBoxDynamic",
							items = {}
						}
						for _, v in ipairs(setting.skyBox) do
							if v.texture then
								local info = {
									time = v.time,
									transition = v.transition,
									texture = convert_texture(v.texture)
								}
								table.insert(base.items, info)
							end
						end
					else
						print("convert skyBox fail: " .. type)
					end
				end
				ref.box = {
					type = type,
					base = base
				}
				--天空盒旋转速度
				ref.rotateSpeed = setting.skyBoxRotate.y / 60
			end

			--entity
			do
				ref.regions = nil
				ref.entitys = nil
			end
			
			if not ref.name then
				local trans_key = item:module_name() .. "_" .. item:id()
				ref.name = PropImport.Text(trans_key)
			end
			-- instance
			repeat
				if setting.scene then
					ref.instances = {}
					for _, item in ipairs(setting.scene) do
						table.insert(ref.instances, Utils.import_inst(item))
					end
				end
			until(true)
			
			return ref
		end,

		-- rawval编辑器数据，content引擎数据，save_merge_file是否保存网格数据
		export = function(rawval, content, save_merge_file)
			local ret = content and Cjson.decode(content) or {}

			local item = Meta:meta(ITEM_TYPE):ctor(rawval)

			ret.hideCloud = true
			ret.touchPosY = {
				touchdownPosY = item.touch_pos and item.touch_pos.down or -30.00,
				touchupPosY = item.touch_pos and item.touch_pos.up or 720.00
			}

			ret.canAttack	= item.canAttack
			ret.canBreak	= item.canBreak
			ret.moveDownGravity = GameConfig:disable_block() and 0.15 or nil
			--光源全局参数
			ret.blinn = item.blinn and 1 or 0
			ret.hdr = item.hdr and 1 or 0
			ret.reinhard = item.reinhard
			ret.exposure = item.exposure
			ret.gamma = item.gamma
			ret.ambientStrength = item.ambientStrength

			--天空盒
			do
				ret.skyBoxTexSize = 512
				ret.skyBoxTexPixFmt = "RGBA8"
				--天空盒切换模式
				ret.skyBoxMode = item.box.type
				--天空盒贴图(引擎顺序:right、left、top、bottom、back、front)
				local sky_base = item.box.base
				local sky_type = sky_base.__OBJ_TYPE
				if "SkyBoxStatic" == sky_type then
					ret.skyBox = {}
					local skyBoxItem = {
						texture = {}
					}
					table.insert(skyBoxItem.texture, #sky_base.right.asset > 0	and "@"..sky_base.right.asset	or "")
					table.insert(skyBoxItem.texture, #sky_base.left.asset > 0	and "@"..sky_base.left.asset	or "")
					table.insert(skyBoxItem.texture, #sky_base.top.asset > 0	and "@"..sky_base.top.asset		or "")
					table.insert(skyBoxItem.texture, #sky_base.bottom.asset > 0	and "@"..sky_base.bottom.asset	or "")
					table.insert(skyBoxItem.texture, #sky_base.back.asset > 0	and "@"..sky_base.back.asset	or "")
					table.insert(skyBoxItem.texture, #sky_base.front.asset > 0	and "@"..sky_base.front.asset	or "")
					table.insert(ret.skyBox, skyBoxItem)
				elseif "SkyBoxDynamic" == sky_type then
					ret.skyBox = {}
					for _, v in ipairs(sky_base.items or {}) do
						local skyBoxItem = {
							texture = {}
						}
						skyBoxItem.time = v.time
						skyBoxItem.transition = v.transition
						table.insert(skyBoxItem.texture, #v.texture.right.asset > 0		and "@"..v.texture.right.asset	or "")
						table.insert(skyBoxItem.texture, #v.texture.left.asset > 0		and "@"..v.texture.left.asset	or "")
						table.insert(skyBoxItem.texture, #v.texture.top.asset > 0		and "@"..v.texture.top.asset	or "")
						table.insert(skyBoxItem.texture, #v.texture.bottom.asset > 0	and "@"..v.texture.bottom.asset or "")
						table.insert(skyBoxItem.texture, #v.texture.back.asset > 0		and "@"..v.texture.back.asset	or "")
						table.insert(skyBoxItem.texture, #v.texture.front.asset > 0		and "@"..v.texture.front.asset	or "")
						table.insert(ret.skyBox, skyBoxItem)
					end
				else
					--默认天空盒
					ret.skyBox = {}
					local skyBoxItem = {
						texture = {}
					}
					table.insert(skyBoxItem.texture, "@asset/Sky03_right.png")
					table.insert(skyBoxItem.texture, "@asset/Sky03_left.png")
					table.insert(skyBoxItem.texture, "@asset/Sky03_top.png")
					table.insert(skyBoxItem.texture, "@asset/Sky03_bottom.png")
					table.insert(skyBoxItem.texture, "@asset/Sky03_back.png")
					table.insert(skyBoxItem.texture, "@asset/Sky03_front.png")
					table.insert(ret.skyBox, skyBoxItem)
				end
				--天空盒旋转速度
				ret.skyBoxRotate = {
					x = 0,
					y = item.rotateSpeed * 60,
					z = 0
				}
			end

			--entitys
			do
				ret.entity = nil
				ret.region = nil
			end

			if not item.fog.hideFog then
				ret.fog = {
					start = item.fog.start,
					density = item.fog.density.value,
					color = {
						x = item.fog.color.r / 256,
						y = item.fog.color.g / 256,
						z = item.fog.color.b / 256
					}
				}
				ret.fog["end"] = item.fog.start + item.fog.range
			else 
				ret.fog = nil
			end

			repeat
				local check_inst = Utils.raw_check_inst(ret.scene)
				ret.scene = nil
				if not next(item.instances) then
					break
				end

				if save_merge_file then
					EngineFile:create_merge_shapes_file(item.instances)
				end

				ret.scene = {}
				for _, val in ipairs(item.instances) do
					check_remove_operation_child(val)
					local ins = Utils.export_inst(val)
					table.insert(ret.scene,check_inst(ins))
				end
			until(true)

			return ret
		end,

		writer = function(item_name, data, dump, item)
			assert(type(data) == "table")

			--写入时，导出引擎节点资源数据（返回节点资源各个文件的md5，编辑器数据和引擎数据不同时，以引擎数据为准）
			local folderPath = Lib.combinePath(PATH_DATA_DIR, item_name, item.folderConfig.folder_name)
			local exportFiles = item.folderConfig:export_folder_engine(data.scene, folderPath)
			
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			return Seri("json", data, path, dump), exportFiles
		end,

		discard = function(item_name)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			ItemDataUtils:del(path)
		end
	},

	discard = function(item_name)
		local path = Lib.combinePath(PATH_DATA_DIR, item_name)
		ItemDataUtils:delDir(path)
		-- todo：要对地形对象执行 VoxelTerrain::clearStorage()
	end
}

M.folderConfig = {
	--文件夹名字
	folder_name = "DataSet",

	--加载节点资源数据（编辑器）
	load_folder_editor = function(self, val, folderPath)
		if not val or not next(val) or not folderPath then
			return
		end
		for key,_ in ipairs(val) do
			if "Instance_Folder" == val[key]["__OBJ_TYPE"] then
				if val[key].isDataSet then
					local path = Lib.combinePath(folderPath, val[key].id .. ".json")
					if Lib.fileExists(path) then
						local data = Lib.read_json_file(path)
						assert(data, path)
						-- load folder child data set
						self:load_folder_editor(data, folderPath)

						val[key].children = data
					end
				else
					-- load folder child data set
					self:load_folder_editor(val[key].children, folderPath)
				end
			end
		end
	end,

	--加载节点资源数据（引擎）
	load_folder_engine = function(self, val, folderPath, exportFiles)
		if not val or not next(val) or not folderPath then
			return
		end
		for key,_ in ipairs(val) do
			if "Folder" == val[key].class then
				if "true" == val[key].properties.isDataSet then -- 引擎是字符串
					local name = val[key].properties.id .. ".json"
					local path = Lib.combinePath(folderPath, name)
					if Lib.fileExists(path) then
						local data = Lib.read_json_file(path)
						assert(data, path)
						--记录文件的MD5
						local content = Lib.read_file(path)
						exportFiles[name] = content ~= "" and Core.md5(content) or ""
						--遍历加载folder所有数据
						self:load_folder_engine(data, folderPath, exportFiles)

						val[key].children = data
					end
				else
					--遍历加载folder所有数据
					self:load_folder_engine(val[key].children, folderPath, exportFiles)
				end
			end
		end
	end,

	--导出节点资源数据（编辑器）
	export_folder_editor = function(self, val, folderPath)
		local function export_folder(folder, folderPath, exportFiles)
			if not folder.children or not next(folder.children) then
				return
			end
			-- 1.先导出children数据
			for key,_ in ipairs(folder.children) do
				if "Folder" == folder.children[key].class then
					export_folder(folder.children[key], folderPath, exportFiles)
				end
			end
			-- 2.再导出folder数据
			if folder.isDataSet then
				local name = folder.id .. ".json"

				local meta = Meta:meta(folder["__OBJ_TYPE"])
				local data = meta:diff(folder, nil, true) or {}

				local path = Lib.combinePath(folderPath, name)
				os.remove(path)
				local file, errmsg = io.open(path, "w+b")
				assert(file, errmsg)
				file:write(Lib.toJson(data.children))
				file:close()

				exportFiles[name] = true
				folder.children = {}
			end
		end

		if not val or not next(val) then
			return
		end

		-- create dir
		Lib.mkPath(folderPath)
		local exportFiles = {}

		for key,_ in ipairs(val.instances) do
			if "Folder" == val.instances[key].class then
				export_folder(val.instances[key], folderPath, exportFiles)
			end
		end
		return exportFiles
	end,

	--导出节点资源数据（引擎）
	export_folder_engine = function(self, val, folderPath)
		local function export_folder(folder, folderPath, exportFiles)
			if not folder.children or not next(folder.children) then
				return
			end
			-- 1.先导出children数据
			for key,_ in ipairs(folder.children) do
				if "Folder" == folder.children[key].class then
					export_folder(folder.children[key], folderPath, exportFiles)
				end
			end
			-- 2.再导出folder数据
			if "true" == folder.properties.isDataSet then
				local name = folder.properties.id .. ".json"
				exportFiles[name] = Seri("json", folder.children, folderPath .. '/' .. name, true)
				folder.children = nil --置为nil
			end
		end

		if not val or not next(val) then
			return
		end

		-- create dir
		Lib.mkPath(folderPath)
		local exportFiles = {}

		for key,_ in ipairs(val) do
			if "Folder" == val[key].class then
				export_folder(val[key], folderPath, exportFiles)
			end
		end
		self:clear_folder(folderPath, exportFiles)
		return exportFiles
	end,

	--清理节点资源数据
	clear_folder = function(self, folderPath, exportFiles)
		if not folderPath then
			return
		end
		for entry in Lfs.dir(folderPath) do
			if entry ~= "." and entry ~= ".." then
				local curFile = folderPath .. '/' .. entry
				if "file" == Lfs.attributes(curFile, "mode") and (not exportFiles or not exportFiles[entry]) then
					os.remove(curFile)
				end
			end
		end
	end,

	check_dataset_same = function(self, set, dataSet)
		local function getLen(tab)
			local count = 0
			for k,v in pairs(tab) do
				count = count + 1
			end
			return count
		end

		set = set or {}
		dataSet = dataSet or {}
		local same = true
		if getLen(set) ~= getLen(dataSet) then
			same = false
		else
			for k,v in pairs(set) do
				if not dataSet[k] or dataSet[k] ~= v then
					same = false
					break
				end
			end
		end
		return same
	end
}

return M
