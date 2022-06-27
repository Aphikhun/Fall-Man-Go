print("prog")
local Lib = require "lib"
local loader = require "loader"
local Lfs = require "lfs"
local M = {}

function M:Init(path)
	self.game_path = path
	self.plugin_path = Lib.combinePath(self.game_path, "plugin")
	for pagin_name in Lfs.dir(self.plugin_path) do
		self.meta_path = Lib.combinePath(self.plugin_path, pagin_name, "custom_meta")
		self.csv_path = Lib.combinePath(self.meta_path, "custom_meta_lang.csv")
		self.transKeys = {}
		self.extraKeys_ = {}
		self.actionCatalog = {}
		self:load_meta(self.meta_path)
		self:Group()
		self:converter_and_write_file()
	end
end

function M:combine_key(...)
	local tmp = {}
	for _, path in ipairs({...}) do
		if (path ~= "") then
			table.insert(tmp, path)
		end
	end
	local ret = table.concat(tmp, ".")
	return ret
end

function M:add_key(data)
	local key = data.name
	table.insert(self.transKeys, key)
	if string.find(data.name, "T_") then
		return
	elseif string.find(data.name, "Trigger_") then
		if data.base and data.base.ctor_args.contexts then
			for _, arg in ipairs(data.base.ctor_args.contexts.value) do
				key = self:combine_key(data.name, arg.ctor_args.key.value, "name")
				table.insert(self.transKeys, key)
				key = self:combine_key(data.name, arg.ctor_args.key.value, "desc")
				table.insert(self.transKeys, key)
			end
		end
	elseif string.find(data.name, "Action_") and data.name ~= "Action_Base" then
		for _, component in ipairs(data.member.components.value) do
			if component.type == "Component_Params" then
				for _, param in ipairs(component.ctor_args.params.value) do
					if param.ctor_args.key then
						key = self:combine_key(data.name, param.ctor_args.key.value, "name")
						table.insert(self.transKeys, key)
						key = self:combine_key(data.name, param.ctor_args.key.value, "desc")
						table.insert(self.transKeys, key)
					end
				end
			end
		end
		if data.attribute and data.attribute.Catalog then
			self.actionCatalog[data.attribute.Catalog] = true
		end
	elseif data.specifier == "struct" then
		local members = data.member or {}
		for _, member in ipairs(members) do
			key = self:combine_key(data.name, member.identifier, "name")
			table.insert(self.transKeys, key)
			key = self:combine_key(data.name, member.identifier, "desc")
			table.insert(self.transKeys, key)
			if member.attribute then
				if member.attribute.GROUP then	--TODO
					local group_str = Lib.splitString(member.attribute.GROUP, '/')
					local group_str2 = {}
					for _, k in ipairs(group_str) do
						table.insert(group_str2, k)
						local group_key = table.concat(group_str2, "/")
						self.extraKeys_[group_key] = true
						self.extraKeys_[group_key .. ".desc"] = true
					end
				end
				if member.attribute.TAB then
					local key = self:combine_key("Tab", member.attribute.TAB)
					self.extraKeys_[key] = true
				end
			end
		end
	elseif data.specifier == "enum" and not string.find(data.name, "Triggers") then
		local constant = data.constant or {}
		for _, val in ipairs(constant) do
			local key = ""
			if val["attribute"] and val["attribute"]["Lang"] then
				key = self:combine_key(data.name, val["attribute"]["Lang"])
			else
				key = self:combine_key(data.name, val.value)
			end
			table.insert(self.transKeys, key)
		end
	end
end

function M:init_csvline()
	local csvline = {}
	local csv_file = Lib.read_csv_file(self.csv_path)
	if not csv_file then
		return csvline
	end
	for _, line in ipairs(csv_file) do
		csvline[line.KEY] = line
	end
	return csvline
end

function M:Group()
		--GROUP特性
	for k in pairs(self.extraKeys_) do
		table.insert(self.transKeys, k)
	end
	for k in pairs(self.actionCatalog) do
		table.insert(self.transKeys, k)
	end
end

function M:converter_and_write_file()
	local csvline_ = self:init_csvline()

	local keys_ = {"KEY", "zh", "en"}

	local lines_ = {}
	local check_keys = {}
	for _, key in ipairs(self.transKeys) do
		if not check_keys[key] then
			local line = {}
			if csvline_[key] then
				line = csvline_[key]
			else
				for _,v in ipairs(keys_) do
					line[v] = key
				end
			end
			table.insert(lines_, line)
			table.sort(lines_, function(a, b)
				return a.KEY < b.KEY
			end)
			check_keys[key] = true
		end
	end
	Lfs.mkdir(Lib.combinePath(self.game_path,".meta","custom_meta_lang"))
	Lib.write_csv(self.csv_path, lines_, keys_)
end

function M:load_meta(path)
	for name in Lfs.dir(path) do
		local tb = Lib.splitString(name,".")
		if tb[#tb] == "meta" then
			local datas = loader(Lib.combinePath(path,name))
			for _, v in ipairs(datas) do
				self:add_key(v)
			end
		end
	end
end

local path = "../../editor"
for name in Lfs.dir(path) do
	if name ~= "." and name ~= ".." then
		local obj = Lib.copy(M)
		obj:Init(Lib.combinePath(path,name))
	end
end

print("End")
