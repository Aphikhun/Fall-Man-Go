local ModuleBase = require "editor.gamedata.module.class.module_base"

local M = Lib.derive(ModuleBase)

local MODULE_NAME = "game"
local ITEM_TYPE = "GameCfg"

function M:init(name)
	assert(name == MODULE_NAME, 
		string.format("[ERROR] module name not match %s:%s", MODULE_NAME, name)
	)

	ModuleBase.init(self, MODULE_NAME, ITEM_TYPE)
end

function M:need_reload()
	return true
end

return M
