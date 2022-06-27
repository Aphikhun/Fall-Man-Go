local Cjson = require "cjson"
local Def = require "we.def"
local Seri = require "we.gamedata.seri"
local ItemDataUtils = require "we.gamedata.item_data_utils"
local Converter = require "we.gamedata.export.data_converter"
local ItemBase = require "we.gamedata.module.class.item_base"
local Meta = require "we.gamedata.meta.meta"
local PropImport = require "we.gamedata.module.prop_import"

local M = Lib.derive(ItemBase)

local MODULE_NAME = "skill"
local ITEM_TYPE = "SkillCfg"
local PATH_DATA_DIR = Lib.combinePath(Def.PATH_GAME, string.format("plugin/%s/%s", Def.DEFAULT_PLUGIN, MODULE_NAME))

M.config = {
	{
		key = "setting.json",
	
		reader = function(item_name, raw)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			return Lib.read_file(path, raw)
		end,

		import = function(content, ref, item)

			local props = {
				cdTime				= PropImport.Time,
				consumeItem = function(v)
					local ret = {}
					if type(v) == "table" and #v > 0 then
						for i, item in ipairs(v) do
							table.insert(ret, {
								count = item.count,
								itemType = PropImport.ConsumeItemType(item.consumeName, item.consumeBlock)
							})
						end
					else
						table.insert(ret, {
							count = v.count,
							itemType = PropImport.ConsumeItemType(v.consumeName, v.consumeBlock)
						})
					end
					return ret
				end,
				consumeVp			= PropImport.original,
				container = function(v)
					return {
						isValid = true,
						takeNum = v.takeNum,
						autoReloadSkill = v.autoReloadSkill
					}
				end,
				frontSight			= PropImport.original,
				--snipe				= PropImport.original,

				castAction			= PropImport.original,
				--castActionTime	= PropImport.Time,
				castSound			= PropImport.CastSound,
				castEffect			= PropImport.EntityEffect,
				startAction			= PropImport.original,
				startActionTime		= PropImport.Time,
				startEffect			= PropImport.EntityEffect,
				sustainAction		= PropImport.original,
				sustainEffect		= PropImport.EntityEffect,
				stopEffect			= PropImport.EntityEffect,
			}

			local setting = Cjson.decode(content)
			for k, v in pairs(setting) do
				if type(props[k]) == "function" then
					ref[k] = props[k](v, item)
				end
			end
			--[[上面遍历引擎数据一对一转成编辑器数据，避免写很多if，
			当引擎数据与编辑器数据的关系是一对多或多对一或多对多时，用下面的写法]]
			if not ref.name then
				local trans_key = item:module_name() .. "_" .. item:id()
				ref.name = PropImport.Text(trans_key)
			end
			do	--技能释放方式
				ref.skillReleaseWay = ref.skillReleaseWay or {}
				ref.skillReleaseWay.draggingEnabled = setting.draggingEnabled
				ref.skillReleaseWay.sensitivityFactor = setting.sensitivityFactor
				ref.skillReleaseWay.isClick = setting.isClick
				ref.skillReleaseWay.isTouch = setting.isTouch
				ref.skillReleaseWay.icon = PropImport.asset(setting.icon, item)
				if setting.touchTime then
					ref.skillReleaseWay.touchTime = PropImport.Time(setting.touchTime)
				end
				ref.skillReleaseWay.iconPos = {}
				ref.skillReleaseWay.iconPos.area_number = setting.area_number or 0

				if setting.castInterval then
					ref.skillReleaseWay.emitContinuously = {
						isValid = true,
						castInterval = PropImport.Time(setting.castInterval)
					}
				end

			end
			--前后摇导入	如为nil，则为meta中定义的默认值
			local skill_pre				= {}
			skill_pre.time				= {}
			skill_pre.enable_pre		= setting.enable_pre
			skill_pre.time.value		= skill_pre.enable_pre and setting.preSwingTime or 0
			skill_pre.ignore_release	= setting.ignoreCastSkillPreS
			skill_pre.ignore_move		= setting.ignoreMovePreS
			skill_pre.ignore_jump		= setting.ignoreJumpPreS
			skill_pre.move_interrupt	= setting.enableMoveBrkPreS
			ref.skill_pre				= skill_pre

			local skill_rear			= {}
			skill_rear.time				= {}
			skill_rear.enable_rear		= setting.enable_rear
			skill_rear.time.value		= skill_rear.enable_rear and setting.backSwingTime or 0
			skill_rear.ignore_release	= setting.ignoreCastSkillBackS
			skill_rear.ignore_move		= setting.ignoreMoveBackS
			skill_rear.ignore_jump		= setting.ignoreJumpBackS
			skill_rear.move_interrupt	= setting.enableMoveBrkBackS
			ref.skill_rear				= skill_rear
			-------
	

			do	--技能类型
				assert(setting.type)
				local skill
				if setting.type == "MeleeAttack" then
					skill = {
						[Def.OBJ_TYPE_MEMBER] = "Skill_MeleeAttack",
						hurtDistance = setting.hurtDistance,
						damage = setting.damage,
						range = setting.range,
						dmgFactor = setting.dmgFactor
					}
				elseif setting.type == "Reload" then
					skill = {
						[Def.OBJ_TYPE_MEMBER] = "Skill_Reload",
						reloadTime = PropImport.Time(setting.reloadTime),
					}
					skill.consumeItem = PropImport.ConsumeItemType(setting.reloadName, setting.reloadBlock)
				elseif setting.type == "Buff" then
					skill = {
						[Def.OBJ_TYPE_MEMBER] = "Skill_Buff",
						buffCfg = setting.buffCfg,
						buffTime = PropImport.Time(setting.buffTime),
						target = setting.target
					}
				elseif setting.type == "Ray" then
					skill = {
						[Def.OBJ_TYPE_MEMBER] = "Skill_Ray",
						rayLenth = setting.rayLenth,
						hitEffect = nil, --todo
						trajectoryEffect = nil, --todo
						recoil = setting.recoil,
						hitEntitySkill = setting.hitEntitySkill,
						hitEntityHeadSkill = setting.hitEntityHeadSkill,
						hitBlockSkill = setting.hitBlockSkill
					}
				elseif setting.type == "Missile" then
					skill = {
						[Def.OBJ_TYPE_MEMBER] = "Skill_Missile",
						target = {
							type = setting.targetType,
							param = {
								frontDistance = setting.frontDistance,
								frontRange = setting.frontRange,
								frontHeight = setting.frontHeight
							}
						}
					}
					local missileCount = setting.missileCount or 1

					local missile_props = { 
						missileCfg	= PropImport.original, 
						startPos	= PropImport.original, 
						startYaw	= PropImport.original,
						startPitch	= PropImport.original,
						bodyYawOffset= PropImport.original,
						bodyPitchOffset= PropImport.original,
						startWait	= PropImport.Time
					}
					skill.missile = {}
					for i = 1, missileCount do
						local missile_ = {}
						for k, v in pairs(missile_props) do
							if setting[k] then
								if type(setting[k]) == "table" then
									missile_[k] = v(setting[k][i])
								else
									missile_[k] = v(setting[k])
								end
							end
						end
						table.insert(skill.missile, missile_)
					end
				elseif setting.type == "UseItem" then
					skill = {[Def.OBJ_TYPE_MEMBER] = "Skill_UseItem"}
				else
					skill = {[Def.OBJ_TYPE_MEMBER] = "Skill_Base"}
				end
				ref.skill = {
					type = setting.type,
					base = skill
				}
			end
			return ref
		end,

		export = function(rawval, content)
			local meta = Meta:meta(ITEM_TYPE)
			local item = meta:ctor(rawval)

			local ret
			if content then
				ret = Cjson.decode(content)
			else
				ret = {}
			end

			--技能释放方式
			ret.icon = item.skillReleaseWay.isClickIcon and Converter(item.skillReleaseWay.icon, "add_asset") or nil
			------------------------------
			local area_number  = item.skillReleaseWay.iconPos.area_number
			ret.area_number = area_number 
			local pos_tab = {
				{-220, 66, 80},
				{-90, 66, 80},
				{60, 66, 80},
				{200, 66, 80},
				{-126, -366, 70},
				{-20, -366, 70},
				{-228, -68, 88},
				{-190, -200, 88},
				{-58, -238, 88}
			}
			if area_number < 5 then
				ret.horizontalAlignment = 1
				ret.verticalAlignment = nil
			else
				ret.horizontalAlignment = 2
				ret.verticalAlignment = 2
			end
			local tab = pos_tab[area_number]
			ret.area = tab and {{0, tab[1]}, {0, tab[2]}, {0, tab[3]}, {0, tab[3]}} or {{0, 0},{0, 0}, {0, 0}, {0, 0}}
			ret.customizeSkill = true;
			------------------------------
			ret.draggingEnabled = item.skillReleaseWay.draggingEnabled
			ret.sensitivityFactor = item.skillReleaseWay.sensitivityFactor
			ret.isClick = item.skillReleaseWay.isClick
			ret.isTouch = item.skillReleaseWay.isTouch
			ret.cdTime = item.cdTime.value
			ret.consumeItem = function()
				if #item.consumeItem == 0 then
					return
				end
				local consumeItem_array = {}
				for _, it in ipairs(item.consumeItem) do
					local newItem = {}
					if it.itemType.type == "Block" then
						newItem.consumeName = "/block"
						newItem.consumeBlock = it.itemType.block ~= "" and it.itemType.block
					else
						newItem.consumeName = it.itemType.item ~= "" and it.itemType.item
					end
					newItem.count = it.count
					table.insert(consumeItem_array, newItem)
				end
				return consumeItem_array
			end

			ret.consumeVp = item.consumeVp

			ret.container = function()
				if (item.container.isValid) then
					return {
						takeNum = item.container.takeNum,
						autoReloadSkill = item.container.autoReloadSkill ~= "" and item.container.autoReloadSkill or nil
					}
				end
			end
			
			ret.frontSight = item.frontSight
			--ret.snipe = item.snipe

			ret.castAction = item.castAction
			if item.defineActionTime then
				ret.castActionTime = Converter(item.castActionTime)
			else
				ret.castActionTime = -1
			end
			ret.castSound = Converter(item.castSound)
			ret.castEffect = Converter(item.castEffect)
			ret.startAction = item.startAction
			ret.startActionTime = Converter(item.startActionTime)
			ret.startEffect = Converter(item.startEffect)
			ret.sustainAction = item.sustainAction
			ret.sustainEffect = Converter(item.sustainEffect)
			ret.stopEffect = Converter(item.stopEffect)

			--前摇配置
			--开启前摇
			ret.enable_pre				= item.skill_pre.enable_pre
			--前摇时间
			ret.preSwingTime			= item.skill_pre.enable_pre and item.skill_pre.time.value or 0
			--前摇时忽略技能释放
			ret.ignoreCastSkillPreS		= item.skill_pre.ignore_release
			--前摇时忽略移动
			ret.ignoreMovePreS			= item.skill_pre.ignore_move
			--前摇时忽略跳跃
			ret.ignoreJumpPreS			= item.skill_pre.ignore_jump
			--前摇时忽略任意移动
			ret.enableMoveBrkPreS		= item.skill_pre.move_interrupt

			--后摇配置
			--开启后摇
			ret.enable_rear				= item.skill_rear.enable_rear
			--后摇时间
			ret.backSwingTime			= item.skill_rear.enable_rear and item.skill_rear.time.value or 0
			--后摇时忽略技能释放
			ret.ignoreCastSkillBackS	= item.skill_rear.ignore_release
			--后摇时忽略移动
			ret.ignoreMoveBackS			= item.skill_rear.ignore_move
			--后摇时忽略跳跃
			ret.ignoreJumpBackS			= item.skill_rear.ignore_jump
			--后摇时忽略任意移动
			ret.enableMoveBrkBackS		= item.skill_rear.move_interrupt
			---
			ret.type = item.skill.type
			local item_base = item.skill.base
			
			ret.castInterval = nil
			if item.skillReleaseWay.isClickIcon and item.skillReleaseWay.emitContinuously.isValid then
				ret.castInterval = item.skillReleaseWay.emitContinuously.castInterval.value
			end

			ret.hurtDistance = nil
			ret.damage = nil
			ret.range = nil
			ret.dmgFactor = nil
			if ret.type == "MeleeAttack" then
				ret.isClick = true
				ret.hurtDistance = item_base.hurtDistance
				ret.damage = item_base.damage
				ret.range = item_base.range
				ret.dmgFactor = item_base.dmgFactor
			end

			ret.reloadTime = nil
			ret.reloadName = nil
			ret.reloadBlock = nil
			if ret.type == "Reload" then
				ret.reloadTime = item_base.reloadTime.value
				if item_base.consumeItem.type == "Item" then
					ret.reloadName = item_base.consumeItem.item
				elseif item_base.consumeItem.type == "Block" then
					ret.reloadName = "/block"
					ret.reloadBlock = item_base.consumeItem.block
				end
			end

			ret.buffCfg = nil
			ret.buffTime = nil
			ret.target = nil
			if ret.type == "Buff" then
				ret.buffCfg = item_base.buffCfg
				ret.buffTime = item_base.buffTime.value
				ret.target = item_base.target ~= "skill_target" and item_base.target or nil
			end

			ret.rayLenth = nil
			ret.hitEffect = nil
			ret.trajectoryEffect = nil
			ret.recoil = nil
			ret.hitEntitySkill = nil
			ret.hitEntityHeadSkill = nil
			ret.hitBlockSkill = nil
			if ret.type == "Ray" then
				ret.rayLenth = item_base.rayLenth
				ret.hitEffect = Converter(item_base.hitEffect, "add_asset")
				ret.trajectoryEffect = Converter(item_base.trajectoryEffect, "add_asset")
				ret.recoil = item_base.recoil	
				ret.hitEntitySkill = item_base.hitEntitySkill ~= "" and item_base.hitEntitySkill or nil
				ret.hitEntityHeadSkill = item_base.hitEntityHeadSkill ~= "" and item_base.hitEntityHeadSkill or nil
				ret.hitBlockSkill = item_base.hitBlockSkill ~= "" and item_base.hitBlockSkill or nil
			end

			ret.targetType = nil
			ret.frontDistance = nil
			ret.frontRange = nil
			ret.frontHeight = nil
			ret.missileCount = nil
			ret.missileCfg = nil
			ret.startPos = nil
			ret.startYaw = nil
			ret.startPitch = nil
			ret.bodyYawOffset = nil
			ret.bodyPitchOffset = nil
			ret.startWait = nil
			if ret.type == "Missile" then
				ret.startFrom = ret.startFrom and ret.startFrom or "foot"
				ret.targetType = item_base.target.type
				if ret.targetType == "FrontEntity" then
					ret.frontDistance = item_base.target.param.frontDistance
					ret.frontRange = item_base.target.param.frontRange
					ret.frontHeight = item_base.target.param.frontHeight
				end
				ret.missileCount = #item_base.missile
				ret.missileCfg = {}
				ret.startPos = {}
				ret.startYaw = {}
				ret.startPitch = {}
				ret.bodyYawOffset = {}
				ret.bodyPitchOffset = {}
				ret.startWait = {}
				for i, missile in ipairs(item_base.missile or {}) do
					ret.missileCfg[i] = missile.missileCfg
					ret.startPos[i] = {
						x = missile.startPos.x,
						y = missile.startPos.y,
						z = missile.startPos.z
					}
					ret.startYaw[i] = missile.startYaw
					ret.startPitch[i] = missile.startPitch
					ret.bodyYawOffset[i] = missile.bodyYawOffset
					ret.bodyPitchOffset[i] = missile.bodyPitchOffset
					ret.startWait[i] = missile.startWait.value
				end
			else
				ret.startFrom = nil
			end

			ret.handItem = nil
			ret.minSustainTime = nil
			ret.maxSustainTime = nil
			ret.skillName = nil
			ret.releaseType = nil
			ret.touchTime = ret.isTouch and item.skillReleaseWay.touchTime.value or nil
			ret.enableCdTip = item.enableCdTip
			ret.enableCdMask = item.enableCdMask
			if ret.cdTime % 20 == 0 then
				item.isShowCdPoint = false
			else
				item.isShowCdPoint = true
			end
			ret.isShowCdPoint = item.isShowCdPoint
			ret.cdMaskConfig = {
				horizontalAlignment = 1,
				verticalAlignment = 1,
				FillPosition = item.FillPosition, 
				FillType = item.FillType,
				AntiClockwise = item.AntiClockwise
			}

			local key, val = next(ret)
			while(key) do
				if type(val) == "function" then
					ret[key] = val()
				end
				key, val = next(ret, key)
			end

			return ret
		end,

		writer = function(item_name, data, dump)
			assert(type(data) == "table")
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			return Seri("json", data, path, dump)
		end,

		discard = function(item_name)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "setting.json")
			ItemDataUtils:del(path)
		end
	},

	{
		key = "triggers.bts",

		member = "triggers",

		reader = function(item_name, raw)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "triggers.bts")
			return Lib.read_file(path, raw)
		end,

		import = function(content, ref)
			-- todo
			return {}
		end,

		export = function(item)
			return item.triggers or {}
		end,

		writer = function(item_name, data, dump)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "triggers.bts")
			return Seri("bts", data, path, dump)
		end,

		discard = function(item_name)
			local path = Lib.combinePath(PATH_DATA_DIR, item_name, "triggers.bts")
			ItemDataUtils:del(path)
		end
	},

	discard = function(item_name)
		local path = Lib.combinePath(PATH_DATA_DIR, item_name)
		ItemDataUtils:delDir(path)
	end
}

return M
