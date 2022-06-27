﻿---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by williamoj.
--- DateTime: 2020/10/4 8:59 下午
---

local cjson = require "cjson"
local Signal = require "we.signal"
local Module = require "we.gamedata.module.module"
local Def = require "we.def"

local ActorMain = nil
local M = {}

local cancel_subscribe = nil


function M:init(main)
	ActorMain = main
	self._router = {
		-- Skill增删
		["^skill$"] = function(event, index, oval)
			local actor = ActorMain:getActor()
			if event == Def.NODE_EVENT.ON_INSERT then
				local skill = self:get_skill(index)
				-- 创建Skill
				actor:AddSkill(skill.name)
				-- 创建动画
				local animation = skill["action_editor_animation"]
				local res_file = (animation["res_file"] or {}).asset
				if res_file ~= nil and res_file ~= "" then
					local animation_name = actor:CheckResource(res_file)
					actor:AddSkAnimation(skill.name, animation_name)
					-- 同步属性
					--self:sync_animation_properties(actor, skill.name, animation, animation_name)
					self:reset_animation_properties(actor, skill.name, animation, animation_name)
				end
				-- 创建特效
				local effects = skill["action_editor_effect"]
				for _, effect in pairs(effects) do
					res_file = (effect["res_file"] or {}).asset
					if res_file ~= nil and res_file ~= "" then
						local effect_name = actor:CheckResource(res_file)
						local effect_index = actor:AddSkEffect(skill.name, effect_name)
						-- 同步属性
						--self:sync_effect_properties(actor, skill.name, effect, effect_index)
						self:reset_effect_properties(actor, skill.name, effect, effect_index)
					end
				end
			elseif event == Def.NODE_EVENT.ON_REMOVE then
				-- 删除动画
				local res_file = (oval["action_editor_animation"]["res_file"] or {}).asset
				if res_file ~= nil and res_file ~= "" then
					local animation_name = actor:CheckResource(res_file)
					actor:RemoveSkAnimation(oval.name, animation_name)
				end
				-- 删除Skill
				actor:RemoveSkill(oval.name)
			else
				assert(false)
			end
		end,

		-- Skill名
		["^skill/(%d+)$"] = function(event, key, iskill, oval)
			assert(event == Def.NODE_EVENT.ON_ASSIGN)
			local actor = ActorMain:getActor()
			if key == "name" then
				local skill = self:get_skill(iskill)
				actor:SetSkillName(oval, skill.name)
			end
		end,

		-- Skill动画
		["^skill/(%d+)/action_editor_animation/?(%g*)"] = function(event, key, iskill, subpath, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local skill = self:get_skill(iskill)
			--local subpaths = Lib.splitString(subpath, "/")
			local animation = skill["action_editor_animation"]
			local res_file = animation["res_file"]["asset"]
			if res_file == oval then
				return
			end
			local actor = ActorMain:getActor()
			local animation_name = res_file or ""
			if animation_name ~= "" then
				animation_name = actor:CheckResource(res_file)
			end
			-- 动画资源
			if subpath == "res_file" then
				if key ~= "asset" then
					return
				end
				local old_animation_name = oval or ""
				--old_animation_name = Lib.toFileName(old_animation_name)
				actor:ChangeSkAnimation(skill.name, animation_name, old_animation_name)
				-- 同步属性
				--self:sync_animation_properties(actor, skill.name, animation, animation_name)
				self:reset_animation_properties(actor, skill.name, animation, animation_name)
			-- 动画循环播放
			elseif subpath == "loop_play_set" then
				if key == "enable" then
					local loop = animation["loop_play_set"].enable
					if loop then
						actor:SetSkAnimationLoop(skill.name, animation_name, -1)
					else
						local play_times = animation["loop_play_set"].play_times
						actor:SetSkAnimationLoop(skill.name, animation_name, play_times)
					end
				elseif key == "play_times" then
					local play_times = animation["loop_play_set"].play_times
					actor:SetSkAnimationLoop(skill.name, animation_name, play_times)
				end
			-- 动画名称
			elseif key == "name" then
				print("##### Not Implemented [todo]:", key)
			-- 动画开始时间
			elseif key == "start_time" then
				actor:SetSkAnimationBeginTime(skill.name, animation_name, math.floor(animation.start_time * 1000 + 0.5))
			-- 动画时长
			elseif key == "length" then
				print("##### Not Implemented [todo]:", key)
			-- 动画作用通道
			elseif key == "channel_mode" then
				actor:SetSkAnimationChannel(skill.name, animation_name, animation.channel_mode)
			-- 动画播放速度
			elseif key == "play_speed" then
				actor:SetSkAnimationTimeScale(skill.name, animation_name, animation.play_speed)
			-- 动画过渡时间
			elseif key == "transition_time" then
				actor:SetSkAnimationFadeTime(skill.name, animation_name, math.floor(animation.transition_time * 1000 + 0.5))
			else
				print("##### Not Implemented [action_editor_animation]:", subpath, key)
			end
		end,

		-- Skill特效增删
		["^skill/(%d+)/action_editor_effect$"] = function(event, index, iskill, oval)
			local actor = ActorMain:getActor()
			local skill = self:get_skill(iskill)
			if event == Def.NODE_EVENT.ON_INSERT then
				local effect = skill["action_editor_effect"][index]
				local res_file = effect["res_file"].asset
				if res_file == nil or res_file == "" then
					return
				end
				local effect_name = actor:CheckResource(res_file)
				local effect_index = actor:AddSkEffect(skill.name, effect_name)
				-- 同步属性
				--self:sync_effect_properties(actor, skill.name, effect, effect_index)
				self:reset_effect_properties(actor, skill.name, effect, effect_index)
			elseif event == Def.NODE_EVENT.ON_REMOVE then
				local res_file = oval["res_file"].asset
				if res_file == nil or res_file == "" then
					return
				end
				actor:RemoveSkEffect(skill.name, index-1)
			end
		end,

		-- Skill特效
		["^skill/(%d+)/action_editor_effect/+(%g*)"] = function(event, key, iskill, subpath, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			local skill = self:get_skill(iskill)
			local subpaths = Lib.splitString(subpath, "/")
			local effect_index = subpaths[1]
			local effect = skill["action_editor_effect"][effect_index]
			local res_file = effect["res_file"].asset
			if res_file == oval then
				return
			end
			local actor = ActorMain:getActor()
			effect_index = effect_index - 1	-- 转换成c++的index
			-- 资源
			if subpaths[2] == "res_file" then
				if key ~= "asset" then
					return
				end
				local effect_name = res_file or ""
				if effect_name ~= "" then
					effect_name = actor:CheckResource(res_file)
				end
				actor:ChangeSkEffect(skill.name, effect_index, effect_name)
				actor:SetSkillPosition(skill.name,0)
				-- 同步属性
				--self:sync_effect_properties(actor, skill.name, effect, effect_index)
				self:reset_effect_properties(actor, skill.name, effect, effect_index)
			-- 变换
			elseif subpaths[2] == "transform" then
				local transform = effect["transform"]
				if subpaths[3] == "pos" then
					local pos = transform["pos"]
					actor:SetSkEffectPosition(skill.name, effect_index, pos.x, pos.y, pos.z)
				elseif subpaths[3] == "rotate" then
					local rotate = transform["rotate"]
					actor:SetSkEffectRotation(skill.name, effect_index, rotate.x, rotate.y, rotate.z)
				elseif key == "scale" then
					actor:SetSkEffectScale(skill.name, effect_index, transform.scale)
				end
			-- 半透明
			elseif subpaths[2] == "alpha" then
				local alpha = effect["alpha"].value
				actor:SetSkEffectAlpha(skill.name, effect_index, alpha)
			-- 循环播放
			elseif subpaths[2] == "loop_play_set" then
				if key == "enable" then
					local loop = effect["loop_play_set"].enable
					if loop then
						actor:SetSkEffectLoop(skill.name, effect_index, -1)
					else
						local play_times = effect["loop_play_set"].play_times
						actor:SetSkEffectLoop(skill.name, effect_index, play_times)
					end
				elseif key == "play_times" then
					local play_times = effect["loop_play_set"].play_times
					actor:SetSkEffectLoop(skill.name, effect_index, play_times)
				end
			-- 自定义播放周期
			elseif subpaths[2] == "custom_time_set" then
				if key == "enable" then
					local enabled = effect["custom_time_set"].enable
					if enabled then
						local cycle_time = effect["custom_time_set"].play_times
						actor:SetSkEffectCycleTime(skill.name, effect_index, cycle_time)
					else
						actor:SetSkEffectCycleTime(skill.name, effect_index, -1)
					end
				elseif key == "play_times" then
					local cycle_time = effect["custom_time_set"].play_times
					actor:SetSkEffectCycleTime(skill.name, effect_index, cycle_time)
				end
			-- 挂点
			elseif key == "bind_part" then
				actor:SetSkEffectBindPart(skill.name, effect_index, effect.bind_part)
			-- 跟随挂点
			elseif key == "follow_bind_part" then
				actor:SetSkEffectFollowActor(skill.name, effect_index, effect.follow_bind_part)
			-- 开始时间
			elseif key == "start_time" then
				actor:SetSkEffectBeginTime(skill.name, effect_index, math.floor(effect.start_time * 1000 + 0.5))
			-- 播放速度
			elseif key == "play_speed" then
				actor:SetSkEffectTimeScale(skill.name, effect_index, effect.play_speed)
			else
				print("##### Not Implemented [action_editor_effect]:", subpath, key)
			end
		end,

		-- Skill音效
		["^skill/(%d+)/action_editor_sound/?(%g*)"] = function(event, key, iskill, subpath, oval)
			if event ~= Def.NODE_EVENT.ON_ASSIGN then
				return
			end
			print("##### Not Implemented [skill]:", subpath, key)
		end,

		-- Skill动画列表
		["^ani_list$"] = function(event, key, iskill, oval)
			assert(event == Def.NODE_EVENT.ON_ASSIGN)
			print("##### Not Implemented [skill]:", key)
		end
	}
end


function M:get_skill(iskill)
	return self._root["skill"][iskill]
end


function M:sync_animation(animation, properties)
	animation.length = properties.length
	animation.start_time = properties.begin_time
	animation.play_speed = properties.time_scale
	animation["loop_play_set"].enable = properties.loop <= 0
	animation["loop_play_set"].play_times = properties.loop
	animation.channel_mode = properties.channel
	animation.transition_time = properties.fade_time
end


function M:sync_effect(effect, properties)
	effect.length = properties.length
	effect.bind_part = properties.bind_part
	local transform = effect["transform"]
	local pos = transform["pos"]
	local _position = properties["position"]
	pos.x = _position[1]
	pos.y = _position[2]
	pos.z = _position[3]
	local rotate = transform["rotate"]
	local _rotation = properties["rotation"]
	rotate.x = _rotation[1]
	rotate.y = _rotation[2]
	rotate.z = _rotation[3]
	transform.scale = properties.scale
	effect.start_time = properties.begin_time
	effect.play_speed = properties.time_scale
	effect["loop_play_set"].enable = properties.loop <= 0
	effect["loop_play_set"].play_times = properties.loop
	effect["alpha"].value = properties.alpha
	effect["custom_time_set"].enable = properties.cycle_time > 0
	effect["custom_time_set"].play_times = properties.cycle_time
	effect.follow_bind_part = properties.follow_actor
end


function M:sync_animation_properties(actor, skill_name, animation, animation_name)
	local _properties = actor:GetSkAnimationProperties(skill_name, animation_name)
	if _properties ~= "{}" then
		local properties = cjson.decode(_properties)
		--print("### properties:", _properties)
		self:sync_animation(animation, properties)
	end
end


function M:sync_effect_properties(actor, skill_name, effect, effect_index)
	local _properties = actor:GetSkEffectProperties(skill_name, effect_index)
	if _properties ~= "{}" then
		local properties = cjson.decode(_properties)
		--print("### properties:", _properties)
		self:sync_effect(effect, properties)
	end
end


function M:reset_animation_properties(actor, skill_name, animation, animation_name)
	actor:SetSkAnimationBeginTime(skill_name, animation_name, math.floor(animation.start_time * 1000 + 0.5))
	actor:SetSkAnimationChannel(skill_name, animation_name, animation.channel_mode)
	actor:SetSkAnimationTimeScale(skill_name, animation_name, animation.play_speed)
	actor:SetSkAnimationFadeTime(skill_name, animation_name, math.floor(animation.transition_time * 1000 + 0.5))

	local _properties = actor:GetSkAnimationProperties(skill_name, animation_name)
	if _properties ~= "{}" then
		local properties = cjson.decode(_properties)
		--print("### properties:", _properties)
		--self:sync_animation(animation, properties)
		animation.length = properties.length
	end

	
	local loop = animation["loop_play_set"]
	if loop then
		if loop.enable then
			actor:SetSkAnimationLoop(skill_name, animation_name, -1)
		else
			actor:SetSkAnimationLoop(skill_name, animation_name, loop.play_times)
		end
	end
end


function M:reset_effect_properties(actor, skill_name, effect, effect_index)
	actor:SetSkEffectBindPart(skill_name, effect_index, effect.bind_part)
	actor:SetSkEffectFollowActor(skill_name, effect_index, effect.follow_bind_part)
	actor:SetSkEffectBeginTime(skill_name, effect_index, math.floor(effect.start_time * 1000 + 0.5))
	actor:SetSkEffectTimeScale(skill_name, effect_index, effect.play_speed)

	local _properties = actor:GetSkEffectProperties(skill_name, effect_index)
	if _properties ~= "{}" then
		local properties = cjson.decode(_properties)
		--print("### properties:", _properties)
		effect.length = properties.length
	end

	local transform = effect["transform"]
	if transform then
		actor:SetSkEffectScale(skill_name, effect_index, transform.scale)
		local pos = transform["pos"]
		if pos then
			actor:SetSkEffectPosition(skill_name, effect_index, pos.x, pos.y, pos.z)
		end
		local rotate = transform["rotate"]
		if rotate then
			actor:SetSkEffectRotation(skill_name, effect_index, rotate.x, rotate.y, rotate.z)
		end
	end
	local alpha = effect["alpha"]
	if alpha then
		actor:SetSkEffectAlpha(skill_name, effect_index, alpha.value)
	end
	local loop = effect["loop_play_set"]
	if loop then
		if loop.enable then
			actor:SetSkEffectLoop(skill_name, effect_index, -1)
		else
			actor:SetSkEffectLoop(skill_name, effect_index, loop.play_times)
		end
	end
	local cycle = effect["custom_time_set"]
	if cycle then
		if cycle.enable then
			actor:SetSkEffectCycleTime(skill_name, effect_index, cycle.play_times)
		else
			actor:SetSkEffectCycleTime(skill_name, effect_index, -1)
		end
	end
end


function M:set_actor(item_id)
	local root = Module:module("actor_editor"):item(item_id):obj()
	assert(root, item_id)
	self._root = root["actor_action"]

	if cancel_subscribe then
		cancel_subscribe()
	end

	cancel_subscribe = Signal:subscribe(self._root, Def.NODE_EVENT.ON_MODIFY, function(path, event, index, ...)
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
		if #captures <= 0 then
			print("No router for:", path, index)
		end
	end)
end

local names = {"ActorTemplates", "ActorTemplate", "Skills", "Skill"}
function M:get_skills_by_path(path)
	local actor_tb = Lib.LoadXmltoTable(path)
	
	local ret = {}
	local tb = actor_tb
	for _,v in ipairs(names) do
		if not tb[v] or type(tb[v]) ~= "table" then
			return ret
		end
		tb = tb[v]
	end

	local skills_tb = tb
	
	for _,skill in ipairs(skills_tb) do
		table.insert(ret, skill["_attr"]["Name"])
	end
	return ret
end

return M