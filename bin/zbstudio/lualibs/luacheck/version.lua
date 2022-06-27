local argparse = ZBREQUIRE "argparse"
local lfs = ZBREQUIRE "lfs"
local luacheck = ZBREQUIRE "luacheck"
local multithreading = ZBREQUIRE "luacheck.multithreading"
local utils = ZBREQUIRE "luacheck.utils"

local version = {}

version.luacheck = luacheck._VERSION

if rawget(_G, "jit") then
   version.lua = rawget(_G, "jit").version
elseif _VERSION:find("^Lua ") then
   version.lua = "PUC-Rio " .. _VERSION
else
   version.lua = _VERSION
end

version.argparse = argparse.version

version.lfs = utils.unprefix(lfs._VERSION, "LuaFileSystem ")

if multithreading.has_lanes then
   version.lanes = multithreading.lanes.ABOUT.version
else
   version.lanes = "Not found"
end

version.string = ([[
Luacheck: %s
Lua: %s
Argparse: %s
LuaFileSystem: %s
LuaLanes: %s]]):format(version.luacheck, version.lua, version.argparse, version.lfs, version.lanes)

return version
