local cjson = require "cjson"
local misc = require "misc"

local eventCalls = {}

local function v2s(value, sp, restLevel)
	local typ = type(value)
	if typ=="string" then
		return '\"' .. value .. '\"'
	elseif typ~="table" then
		return tostring(value)
	end
	restLevel = restLevel - 1
	if restLevel<0 then
		return "..."
	end
	local nsp = sp .. "  "
	local tb = {}
	local idxs = {}
	for k, v in ipairs(tb) do
		idxs[k] = true
		tb[#tb+1] = "[" .. k .. "] = " .. v2s(v, nsp, restLevel)
	end
	for k, v in pairs(value) do
		if not idxs[k] then
			k = (type(k)=="string") and ('\"'..k..'\"') or tostring(k)
			tb[#tb+1] = "[" .. k .. "] = " .. v2s(v, nsp, restLevel)
		end
	end
	if not tb[1] then
		return "{}"
	end
	nsp = "\n" .. nsp
	return "{"..nsp .. table.concat(tb, ","..nsp) .. "\n" .. sp .. "}";
end

local Lib = {}

function Lib.v2s(value, maxLevel)
	return v2s(value, "", maxLevel or 3)
end

function Lib.pv(value, maxLevel)
	print(v2s(value, "", maxLevel or 3))
end

function Lib.read_file(path)
	local file, errmsg = io.open(path, "rb")
	if not file then
		print("[Error]", errmsg)
		return nil
	end
	local content = file:read("a")
	file:close()

	-- remove BOM
	local c1, c2, c3 = string.byte(content, 1, 3)
	if (c1 == 0xEF and c2 == 0xBB and c3 == 0xBF) then	-- UTF-8
		content = string.sub(content, 4)
	elseif (c1 == 0xFF and c2 == 0xFE) then	-- UTF-16(LE)
		content = string.sub(content, 3)
	end

	return content
end

function Lib.combinePath(...)
	local tmp = {}
	for _, path in ipairs({...}) do
		if (path ~= "") then
			table.insert(tmp, path)
		end
	end
	local ret = string.gsub(string.gsub(table.concat(tmp, "/"), "\\", "/"), "(/+)", "/")
	return ret
end

function Lib.splitString(str, sep)
	local res = {}
	string.gsub(str, '[^' .. sep .. ']+', function(w)
		table.insert(res, w)
	end)
	return res
end

function Lib.read_json_file(path)
	print("read_json_file", path)
	local file, errmsg = io.open(path)
	if not file then
		print(errmsg)
		return false
	end
	local content = file:read("a")
	file:close()
	local ok, ret = pcall(cjson.decode, content)
	assert(ok, path)
	return ret
end

function Lib.write_csv(path, items, header)
	local function to_array(item)
		local ret = {}
		for _, key in pairs(header) do
			table.insert(ret, item[key])
		end

		return ret
	end

	local out = misc.csv_encode(header) .. "\r\n"
	for i, v in ipairs(items) do
		local line = to_array(v)
		out = out .. misc.csv_encode(line) .. "\r\n"
	end

	misc.write_utf16(path, out)
end

Lib.read_csv_file = function(path, ignore_line, raw)
	local csvLine = {}
	local file = io.open(path, "rb", raw)
	if not file then
		return nil
	end

	local content = file:read("a")
	file:close()
	content = misc.read_text(content)
	local key, pos = misc.csv_decode(content)
	local line = {}
	local line_number = 1
	while pos do
        line, pos = misc.csv_decode(content, pos)
		line_number = line_number + 1
		if not ignore_line or line_number > ignore_line then
			local t = {}
			if line then
				for k,v in pairs(line) do
					t[tostring(key[k])] = v
				end
				table.insert(csvLine, t)
			end
		end
	end
	return csvLine, key
end

function Lib.toJson(data)
	local to_space, obj2json, array2json, tojson
	
	to_space = function(level)
		local str = ""
		for i = 1, level do
			str = str .. "  "
		end
		return str
	end

	obj2json = function(data, keys, level)
		table.sort(keys)
		local str = "{\n"
		level = level + 1
		for i, k in ipairs(keys) do
			local line = string.format("%s\"%s\": %s,\n", to_space(level), k, tojson(data[k], level))
			str = str .. line
		end
		level =  level - 1
		str = str .. "}"
		str = string.gsub(str, ",\n}", "\n" .. to_space(level) .. "}")
		return str
	end

	array2json = function(data, level)
		local str = "[\n"
		level = level + 1
		for _, v in ipairs(data) do
			local line = to_space(level) .. tojson(v, level) .. ",\n"
			str = str .. line
		end
		level =  level - 1
		str = str .. "]"
		str = string.gsub(str, ",\n]", "\n" .. to_space(level) .. "]")
		return str
	end

	tojson = function(data, level)
		if type(data) == "string" then
			return '\"' .. data .. '\"'
		elseif type(data) == "number" then
			return tostring(data)
		elseif type(data) == "nil" then
			return "null"
		elseif type(data) == "boolean" then
			return (data and "true") or "false"
		elseif type(data) == "table" then
			level = level or 0
			local keys = {}
			for k, _ in pairs(data) do
				if type(k) == "string" then
					table.insert(keys, k)
				end
			end
			if #keys > 0 then
				return obj2json(data, keys, level)
			elseif #data > 0 then
				return array2json(data, level)
			else
				return "[]"
			end
		end
	end

	return tojson(data)
end

function Lib.copy(value)
	if type(value)~="table" then
		return value
	end
	local ret = {}
	for k, v in pairs(value) do
		ret[k] = Lib.copy(v)
	end
	return ret
end

function Lib.derive(base, derive)
	assert(base)
	derive = derive or {}
	derive.__base = derive.__base or {}
	table.insert(derive.__base, base)

	return setmetatable(derive, {
			__index = function (_, key)
				for _, base in ipairs(derive.__base) do
					if base[key] then
						return base[key]
					end
				end
			end
		}
	)
end

function Lib.subscribeEvent(name, func, ...)
	local calls = eventCalls[name]
	if not calls then
		calls = {}
		eventCalls[name] = calls
	end
	local call = {
		event = name,
		func = func,
		args = table.pack(...),
		stack = traceback("register event"),
		index = #calls + 1,
	}
	calls[call.index] = call
	return function()
		if call.index then
			calls[call.index] = nil
		end
		call.index = nil
	end
end

function Lib.emitEvent(name, ...)
	local calls = eventCalls[name]
	if not calls then
		return
	end
	local newArgs = table.pack(...)
	eventCalls[name] = nil
	for _, call in pairs(calls) do
		local args = call.args
		local n = args.n
		local m = newArgs.n
		for i = 1, m do
			args[n+i] = newArgs[i]
		end
		local ok, ret = xpcall(call.func, traceback, table.unpack(args, 1, n + m))
		if not ok then
			perror("Error event callback:", call.event, ret)
			if call.stack then
				print(call.stack)
			end
		end
	end
	local newCalls = eventCalls[name]
	if newCalls then
		for _, call in pairs(newCalls) do
			call.index = #calls + 1
			calls[call.index] = call
		end
	end
	eventCalls[name] = calls
end
return Lib
