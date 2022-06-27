local tray_class_equip = require "common.tray.class.tray_class_equip"

local M = Lib.derive(tray_class_equip)

function M:seri()
	return {}
end

function M:on_drop(slot, item)

end

function M:on_pick(slot, item)

end

return M
