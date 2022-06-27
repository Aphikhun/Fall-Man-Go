local lpeg = require "lpeg"

local P = lpeg.P
local B = lpeg.B
local R = lpeg.R
local S = lpeg.S
local V = lpeg.V

local C = lpeg.C
local Carg = lpeg.Carg
local Cb = lpeg.Cb
local Cc = lpeg.Cc
local Cf = lpeg.Cf
local Cg = lpeg.Cg
local Cp = lpeg.Cp
local Cs = lpeg.Cs
local Ct = lpeg.Ct
local Cmt = lpeg.Cmt

local EOF           = P(-1)
local DIGIT         = R("09")
local ALPHA         = R("az") + R("AZ")
local PNAME         = ALPHA + P("_")
local NAME          = PNAME * (DIGIT + PNAME)^0

local BLANK         = S(" \t")
local BLANKS0       = BLANK^0
local BLANKS1       = BLANK^1
local NEWLINE       = P("\r")^-1 * P("\n") * Cmt(B("\n") * Carg(1), function(_, pos, state)
                        if pos > state.e_line_pos then
                            state.e_line_pos = pos
                            state.e_line = state.e_line + 1
                        end
                        return pos
                    end) * (Carg(1) / function(state)
						state.p_line = state.p_line + 1
					end)

local COMMENT       = P("#") * (1 - NEWLINE)^0
local SAPCE_LINE    = BLANKS0 * COMMENT^-1
local SAPCE_PARA    = (SAPCE_LINE * NEWLINE)^0 * SAPCE_LINE

local INTEGER_DEC	= P"-"^-1 * DIGIT^1
local INTEGER_HEX	= P"-"^-1 * "0" * S("xX") * (R("09") + R("af") + R("AF")) ^ 1
local INTEGER		= INTEGER_HEX + INTEGER_DEC
local DOUBLE		= P"-"^-1 * DIGIT^1 * "." * DIGIT^1
local BOOL			= P("true") + P("false")
local NIL			= P("nil")

local QUALIFIER		= P("const") + P("hide")

local DOC = P {
    "MAIN",

	LINE	= Cg(Carg(1) / function(state)
						return state.p_line
					end,
					"__line"
				),

	LITERAL = "\"" * C((1 - (NEWLINE + "\""))^0) * "\"",

	LUA_FUNC_ENDING = "end" * SAPCE_PARA * ")" * BLANKS0 * ";",

	LUA_FUNC = C(P"function" * ((1 - (NEWLINE + V("LUA_FUNC_ENDING")))^1 * (NEWLINE - V("LUA_FUNC_ENDING"))^0)^0 * #V("LUA_FUNC_ENDING") * P("end")) * Carg(1) / 
	function(v, state)
		local line = state.p_line
		for _ in string.gmatch(v, "\n") do
			line = line - 1
		end
		local func, errmsg = load("return " .. v)
		assert(func, string.format("error:\n%s\n%s\n at function: %d", errmsg, v, line))
		return string.dump(func())
	end,

	VALUE_ARRAY = Ct(
		"{" * SAPCE_PARA *
			(SAPCE_PARA * V("VALUE") * BLANKS0 * ",")^0 * (SAPCE_PARA * V("VALUE"))^-1 * SAPCE_PARA *
		"}"
	),

	VALUE_STRUCT = Ct(
		Cg(C(NAME), "type") * BLANKS0 *
		"(" * SAPCE_PARA *
			Cg(
				Ct(
					(SAPCE_PARA * V("VARIABLE") * BLANKS0 * ",")^0 * SAPCE_PARA * V("VARIABLE")^-1
				),
				"ctor_args"
			) * SAPCE_PARA *
		")"
	) /
	function(tb)
		for _, arg in ipairs(tb.ctor_args or {}) do
			assert(not tb.ctor_args[arg.identifier])
			tb.ctor_args[arg.identifier] = arg
		end
		return tb
	end,

	VALUE = V("LITERAL") + 
			C(DOUBLE) / function(v)
				return tonumber(v)
			end + 
			C(INTEGER) / function(v)
				return tonumber(v)
			end + 
			C(BOOL) / function(v)
				return v == "true" and true or false
			end + 
			C(NIL) / function()
				return nil
			end + 
			V("VALUE_ARRAY") + V("VALUE_STRUCT"),

	VARIABLE = Ct(
		Cg(C(NAME), "identifier") * BLANKS0 *
		("[" * BLANKS0 * 
			Cg(
				(C(INTEGER) + Cc("-1")), "array") * BLANKS0 * 
		"]")^-1 * BLANKS0 *
		(
			"=" * SAPCE_PARA * 
			Cg(V("VALUE"), "value")		
		)^-1
	) /
	function(var)
		if var.array then
			assert(var.array ~= 0)
			var.array = math.tointeger(var.array)
		end
		return var
	end,

	ATTRIBUTE = Ct(
		Cg(C(NAME), "key") * BLANKS0 * ":" * BLANKS0 * Cg(V("LITERAL"), "val")
	),

	ATTRIBUTES = Ct(
		"[" * SAPCE_PARA *
			(SAPCE_PARA * V("ATTRIBUTE") * BLANKS0 * ",")^0 * (SAPCE_PARA * V("ATTRIBUTE"))^-1 * SAPCE_PARA *
		"]"
	)^-1 / 
	function(attrs)
		local ret = {}
		for _, attr in ipairs(attrs) do
			assert(not ret[attr.key], string.format("attr '%s' is duplicate", attr.key))
			ret[attr.key] = attr.val
		end

		return next(ret) and ret
	end,

	ENUM_DEF_CONSTANT = V("LITERAL") + C(INTEGER),

	ENUM_DEF_ITEM = Ct(
		Cg(V("ATTRIBUTES"), "attribute") * SAPCE_PARA * 
		V("LINE") *
		Cg(V("ENUM_DEF_CONSTANT"), "value")
	),

	ENUM_DEF = Ct(
		Cg(Cc("enum"), "specifier") *
		Cg(V("ATTRIBUTES"), "attribute") * SAPCE_PARA *
		V("LINE") *
		"enum" * BLANKS1 * Cg(C(NAME), "name") * SAPCE_PARA * 
		"{" * SAPCE_PARA *
			P(
				P(
					"list" * SAPCE_PARA *
					"(" * SAPCE_PARA *
							Cg(V("LUA_FUNC"), "func_list") * SAPCE_PARA *
					")" * BLANKS0 *
					";" * SAPCE_PARA
				) +
				P(
					Cg(
						Ct(
							(SAPCE_PARA * V("ENUM_DEF_ITEM") * SAPCE_PARA * ",")^0 * SAPCE_PARA * (V("ENUM_DEF_ITEM") * P(",")^-1)^-1
						),
						"constant"
					)
				)
			) ^ -1 * SAPCE_PARA *
		"}" * BLANKS0 *	
		";"
	) / 
	function(tb)
		tb.attribute = tb.attribute or {}
		if tb.func_list then
			tb.attribute["ENUM_LIST"] = "true"
		else
			tb.attribute["ENUM_LIST"] = nil
		end

		return tb
	end,

	STRUCT_DEF_BASE_TYPE = Ct(
		Cg(P(":") * SAPCE_PARA * C(NAME), "type")
	) / 
	function(tb)
		return tb
	end,

	STRUCT_DEF_BASE_CONSTRUCT = Ct(
		P("base") * SAPCE_PARA *
		"(" * SAPCE_PARA *
			(
				(SAPCE_PARA * V("VARIABLE") * BLANKS0 * ",")^0 * SAPCE_PARA * V("VARIABLE")^-1
			) * SAPCE_PARA *
		")" * BLANKS0 * 
		";") * 
		Cb("base") / 
		function(value, base)
			base.ctor_args = value
			for _, arg in ipairs(base.ctor_args or {}) do
				assert(not base.ctor_args[arg.identifier], "identifier conflict")
				base.ctor_args[arg.identifier] = arg
			end
		end,
	
	STRUCT_DEF_MEMBER = Ct(
		Cg(V("ATTRIBUTES"), "attribute") * SAPCE_PARA *
		V("LINE") *
		Cg(
			Ct(
				(C(QUALIFIER) * BLANKS1)^0
			),
			"qualifier"
		) *
		Cg(C(NAME), "type") * BLANKS1 *
		Cg(V("VARIABLE"), "variable") * BLANKS0 *
		";"
	) / 
	function(tb)
		local member = {
			attribute = tb.attribute or {},
			type = tb.type,
			identifier = tb.variable.identifier,
			value = tb.variable.value,
			array = tb.variable.array,
			__line = tb.__line
		}
		for _, q in ipairs(tb.qualifier or {}) do
			member.attribute = member.attribute or {}
			member.attribute[string.upper(q)] = "true"
		end

		return member
	end,

	STRUCT_DEF_MONITOR = Ct(
		V("LINE") *
		"monitor" * SAPCE_PARA * 
		"(" * SAPCE_PARA *
			Cg(V("LITERAL"), "identifier") * BLANKS0 *
			"," * SAPCE_PARA *
			Cg(V("LUA_FUNC"), "func_monitor") * SAPCE_PARA *
		")" * BLANKS0 *
		";"
	),

	STRUCT_DEF_ATTRS_UPDATER = Ct(
		V("LINE") *
		"attrs_updater" * SAPCE_PARA *
		"(" * SAPCE_PARA *
			Cg(V("LUA_FUNC"), "func_attrs_updater") * SAPCE_PARA *
		")" * BLANKS0 *
		";"
	),

	STRUCT_DEF = Ct(
		Carg(1) / function(state)
			state.tmp = state.tmp or {}
		end *
		Cg(Cc("struct"), "specifier") *
		Cg(
			Carg(1) / function(state)
				state.tmp.member = state.tmp.member or {}
				return state.tmp.member
			end,
			"member"
		) *
		Cg(
			Carg(1) / function(state)
				state.tmp.monitor = state.tmp.monitor or {}
				return state.tmp.monitor
			end,
			"monitor"
		) *
		Cg(V("ATTRIBUTES"), "attribute") * SAPCE_PARA *
		V("LINE") *
		"struct" * BLANKS1 * 
		Cg(C(NAME), "name") * SAPCE_PARA *
		Cg(
			V("STRUCT_DEF_BASE_TYPE") * Carg(1) / function(base, state)
				state.tmp.base = state.tmp.base or base
				return state.tmp.base
			end,
			"base"
		)^-1 * SAPCE_PARA *
		"{" * SAPCE_PARA *
			V("STRUCT_DEF_BASE_CONSTRUCT")^-1 * SAPCE_PARA *
			Cg(
				V("STRUCT_DEF_ATTRS_UPDATER"),
				"attrs_updater"
			) ^-1 *
			(SAPCE_PARA *
				(
					Cb("member") * V("STRUCT_DEF_MEMBER") / function(list, item)
						table.insert(list, item)
						list[item.identifier] = item
					end +
					Cb("monitor") * V("STRUCT_DEF_MONITOR") / function(list, item)
						list[item.identifier] = item
					end
				)
			)^0 * SAPCE_PARA *
		"}" * BLANKS0 *
		";"
	) * Carg(1) /
	function(struct, state)
		state.tmp = nil
		return struct
	end,

	MAIN = SAPCE_PARA * 
		Ct(
			(
				(SAPCE_PARA * V("ENUM_DEF")) + 
				(SAPCE_PARA * V("STRUCT_DEF"))
			)^0
		) * SAPCE_PARA *
		EOF,
}

local EXCEPTION = lpeg.Cmt(Carg(1), function(_, pos, state)
    error(string.format("%s parse error, at line:%s", state.file, state.e_line))
    return pos
end)

local function init()

end

return function(path)
	local state = {
		file = path, 
		e_line_pos = 0, 
		e_line = 1,
		p_line = 1,
	}
	init()

	local file = assert(io.open(state.file), state.file)
	local text = file:read("a")
	file:close()

	local c1, c2, c3 = string.byte(text, 1, 3)
	if (c1 == 0xEF and c2 == 0xBB and c3 == 0xBF) then
	    text = string.sub(text, 4)
	end

	local ret = lpeg.match(DOC + EXCEPTION, text, 1, state)
	assert(type(ret) == "table")
	
	return ret
end
