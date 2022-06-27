﻿---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by williamoj.
--- DateTime: 2020/9/17 9:42 上午
---

print("Start Actor Editor Script!", World.GameName)

local Def = require "we.def"
local Signal = require "we.signal"
local Module = require "we.gamedata.module.module"
local BodyPart = require "we.sub_editors.actor_body_parts"
local Skill = require "we.sub_editors.actor_skill"

local M = {}

local camera = Camera:getActiveCamera()
local actor_id = nil
local actor = nil
local actor_pos = nil
local actor_yaw = nil

local cancel_subscribe = nil


function M:init()
	BodyPart:init(self)
	Skill:init(self)
	self._router = {
		-- Actor位置
		["^position$"] = function(event, key, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local pos = self._root["position"]
			actor:SetPosition(pos.x, pos.y, pos.z)
		end,

		-- Actor旋转
		["^rotation$"] = function(event, key, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local rotate = self._root["rotation"]
			actor:SetRotation(rotate.x, rotate.y, rotate.z)
		end,

		-- Actor缩放
		["^scale$"] = function(event, key, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local scale = self._root["scale"]
			actor:SetOriginalScale(scale.x, scale.y, scale.z)
		end,

		-- Actor半透明
		["^alpha$"] = function(event, key, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local alpha = self._root["alpha"]
			actor:SetAlpha(alpha.value)
		end,
	}
end


function M:activate()
	if actor and self._root then
		actor:SetVisible(true)
		self:refreshActorTrans()
	end
end


function M:deactivate()
	if actor then
		actor:SetVisible(false)
	end
end

function M:set_root_nil()
	self._root = nil
end


function M:refreshActorTrans()
	local cam_pos = Vector3.fromTable(camera:getPosition())
	local cam_dir = Vector3.fromTable(camera:getDirection())
	local actor_radius = actor:GetBoundingRadius()
	actor_pos = cam_pos + cam_dir * (2.0 + actor_radius)
	actor_pos.y = actor_pos.y - actor_radius
	actor_yaw = math.deg(math.atan(cam_dir.x, cam_dir.z)) + 180.0
	--actor:SetPosition(actor_pos.x, actor_pos.y, actor_pos.z)
	--actor:SetRotation(0.0, actor_yaw, 0.0)
	local pos = self._root["position"]
	pos.x = actor_pos.x
	pos.y = actor_pos.y
	pos.z = actor_pos.z
	local rotate = self._root["rotation"]
	rotate.y = actor_yaw
	local item = Module:module("actor_editor"):item(actor_id)
	item:set_modified(false)
end


function M:setActor(template_path)
	if actor then
		actor:Reload(template_path, true)
	else
		actor = ActorEditable.new(template_path, true)
	end
	self._template_path = template_path
	--加大日志缓存
	--LogUtil.setMaxMessageSize(65535)
	--[[ test API
	print("### GetEffectLength:", actor:GetEffectLength("127_shop_snow.effect"))
	--]]--
	return actor
end

function M:getActor()
	return actor
end


function M:setActorID(item_id)
	actor_id = item_id
	self:set_actor(item_id)
	self:refreshActorTrans()
	BodyPart:set_actor(item_id)
	BodyPart:sync_actor_ids()
	Skill:set_actor(item_id)
	local item = Module:module("actor_editor"):item(item_id)
	item:set_modified(false)
end


function M:set_actor(item_id)
	local root = Module:module("actor_editor"):item(item_id):obj()
	assert(root, item_id)
	self._root = root

	if cancel_subscribe then
		cancel_subscribe()
	end

	cancel_subscribe = Signal:subscribe(self._root, Def.NODE_EVENT.ON_MODIFY, function(path, event, index, ...)
		-- 忽略'id'
		if index == "id" then
			return
		end
		path = table.concat(path, "/")
		local captures = nil
		for pattern, processor in pairs(self._router) do
			captures = table.pack(string.find(path, pattern))
			if #captures > 0 then
				local args = {}
				for i = 3, #captures do
					table.insert(args, math.tointeger(captures[i]) or captures[i])
				end
				for _, arg in ipairs({...}) do
					table.insert(args, arg)
				end
				print("Process:", path, event, index, table.unpack(args))
				processor(event, index, table.unpack(args))
				break
			end
		end
		--[[
		if #captures <= 0 then
			print("No router for:", path, index)
		end
		]]--
	end)
end

function M:modify_actor(path)
	if actor and self._template_path == path then
		actor:ClearTemplateData()
	end
end

Lib.subscribeEvent(Event.EVENT_EDITOR_ITEM_SAVE, function(module, item_id)
	if module ~= "actor_editor" or item_id ~= actor_id or (not actor) then
		return
	end
	--actor:Refresh()
	--BodyPart:sync_actor_ids()
	local item = Module:module("actor_editor"):item(item_id)
	item:set_modified(false)
end)


return M