local Input = require "we.view.scene.input"
local Operator = require "we.view.scene.operator.operator"
local Receptor = require "we.view.scene.receptor.receptor"
local Recorder = require "we.gamedata.recorder"
local Placer = require "we.view.scene.placer.placer"
local State = require "we.view.scene.state"
local Map = require "we.view.scene.map"
local Scene = require "we.view.scene.scene"

local IWorld = require "we.engine.engine_world"

local Def = require "we.def"
local IScene = require "we.engine.engine_scene"
local IInstance = require "we.engine.engine_instance"
local Module = require "we.gamedata.module.module"
local VN = require "we.gamedata.vnode"

local last_tick = 0

return {
	KEY_EVENT = function(event, key)
		if event == "Press" then
			Input:on_key_press(key)
		elseif event == "Release" then
			Input:on_key_release(key)
		else
			assert(false, tostring(event))
		end
	end,

	MOUSE_EVENT = function(event, x, y, button)
		if event == "Press" then
			Input:on_mouse_press(x, y, button)
		elseif event == "Release" then
			Input:on_mouse_release(x, y, button)
		elseif event == "Move" then
			local curr_tick = World.CurWorld:getTickCount()
			if last_tick ~= curr_tick then
				Input:on_mouse_move(x, y)
				last_tick = curr_tick
			end
		else
			assert(false, tostring(event))
		end
	end,

	HOVER_REMAIN = function(event, x, y, button)
		local curr_tick = World.CurWorld:getTickCount()
		if last_tick ~= curr_tick then
			local ret,result=Input:on_hover_remain(x,y)
			last_tick = curr_tick
			local tab={ret,result=result}
			return tab
		end
	end,
	
	HOVER_UNLOCK = function(event, x, y, button)
		Input:on_hover_unlock(x,y)
	end,

	MOUSE_WHEEL = function(wheelValue)
		Input:on_mouse_wheel(wheelValue)
	end,

	LOST_FOCUS = function()
		Input:on_lost_focus()
	end,

	OPERATOR = function(code)
		Recorder:start()
		local op = assert(Operator:operator(code), tostring(code))
		local receptor = Receptor:binding()
		assert(op:check(receptor))

		op:exec(receptor)
		Recorder:stop()
	end,
	
	DRAG_INSTANCE_TO_SCENE = function(x, y)
		Recorder:start()
		Placer:binding():place(x, y)
		State:placer()["mode"] = ""
		Recorder:stop()
	end,

	CHECK_ITEM_IN_USE = function(module, item)
		local in_use = Map:check_use_cfg(module, item)
		return { ok = true, data = in_use}
	end,

	UNBIND_RECEPTOR = function()
		Receptor:unbind()
	end,

	SCENE_RESET = function()
		Scene:reset()
	end,

	CREATE_FOLDER = function(isDataSet)
		Recorder:start()
		Map:create_folder(isDataSet)
		Recorder:stop()
	end,

	CREATE_SCENEUI = function()
		Recorder:start()
		Map:create_sceneui()
		Recorder:stop()
	end,

	CREATE_EFFECT_PART = function(...)
		Recorder:start()
		Map:create_effect_part({...})
		Recorder:stop()
	end,
	
	CREATE_AUDIO_NODE = function(...)
		Recorder:start()
		Map:create_audio_node({...})
		Recorder:stop()
	end,

	ADD_FOLDER = function(id, isDataSet)
		Recorder:start()
		Map:add_folder(id, isDataSet)
		Recorder:stop()
	end,

	TIER_CHANGED = function(...)
		Recorder:start()
		Map:tier_changed(...)
		Recorder:stop()
	end,

	ADD_ITEM_CHILD = function(...)
		Recorder:start()
		Map:add_obj_child({...})
		Recorder:stop()
	end,

	ADD_LIGHT_CHILD = function(data)
		Recorder:start()
		Map:add_light_child(data)
		Recorder:stop()
	end,

	DROP_ITEM_EFFECT = function(...)
	    Recorder:start()
		Map:drop_obj_effect({...})
		Recorder:stop()
	end,

	DRAG_ITEM_EFFECT = function(...)
	    local table = {...}

		local instance= IScene:pick_point({x = table[1], y = table[2]}, Def.SCENE_NODE_TYPE.PART) 
		if not instance then
			return {ok = true, data = ""}
		end
		local id = IInstance:get(instance,"id")
		return {ok = true, data = id or ""}
	end,
	
	CHECK_SCENEUI_IN_RECEPTOR = function()
		local receptor = Receptor:binding()
		local list = receptor:list(function(obj)
			local child = obj:children()
			for _,v in ipairs(child) do
				if v:class() == "SceneUI" then
					return true
				end
			end
			return false
		end)
		return { results = #list ~= 0}
	end,
	
	CHANGE_EDIT_FOLDER = function(id)
		Map:change_edit_folder(id)
	end,

	CLEAR_EDIT_FOLDER = function()
		Map:clear_edit_folder()
	end,

	SET_REGION_PART = function(id)
		local placer = Placer:bind("region")
		placer:set_parent(Map:query_instance(id))
	end,
	
	CHANGE_EDIT_FOLDER = function(id)
		Map:change_edit_folder(id)
	end,

    btskey2name = function(btsKey)
        local module = Module:module("map")
        local name = ""

        for _, item in pairs(module:list()) do
            local root = item:obj()
            VN.iter(root,
                function(node)
                    local meta = VN.meta(node)
                    if meta:name() ~= "Instance_Part" and meta:name() ~= "Instance_PartOperation" then
                        return
                    end
                    return node["btsKey"] == btsKey
                end,
                function(node)
                   name = node["name"]
                end
             )
             if name ~= "" then
                break
             end
        end

        return {name = name}
    end
}
