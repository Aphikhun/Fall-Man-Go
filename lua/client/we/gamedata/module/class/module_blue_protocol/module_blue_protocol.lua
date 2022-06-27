local ModuleBase = require "we.gamedata.module.class.module_base"

local M = Lib.derive(ModuleBase)

local MODULE_NAME = "blue_protocol"
local ITEM_TYPE = "BlueProtocolCfg"

function M:init(name)
	assert(name == MODULE_NAME, 
		string.format("[ERROR] module name not match %s:%s", MODULE_NAME, name)
	)

	ModuleBase.init(self, MODULE_NAME, ITEM_TYPE)
end

return M