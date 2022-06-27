local math = math
local setting = require "common.setting"

function Object:playSound(sound, cfg, noFollow)
	if not Blockman.instance.gameSettings:getEnableAudioUpdate() then
		return nil
	end
	if not sound or not sound.sound then
		return nil
	end

	if not self:isValid() then
		return
	end
	if sound.selfOnly then
		local entity
		if self.isEntity then
			entity = self
		else
			entity = self.world:getEntity(self.ownerId)
		end
		if not (entity and entity:isControl()) then
			return nil
		end
	end

	cfg = cfg or self:cfg()

	if not sound.path then
        sound.path = ResLoader:filePathJoint(cfg, sound.sound)
	end
    local isLoop=false
    if sound.loop~=nil then
       isLoop= sound.loop
    end
    local id = noFollow and TdAudioEngine.Instance():play3dSound(sound.path, self:getPosition(), isLoop) or self:play3dSound(sound.path, isLoop)
	if sound.volume then
		TdAudioEngine.Instance():setSoundsVolume(id, sound.volume)
	end
    return id
end

function Object:stopSound(soundId)
	if soundId then
		TdAudioEngine.Instance():stopSound(soundId)
	end
end

function Object:fadeSound(soundId, volume, ticks)
	if not soundId then
		return
	end

	local curVolume = TdAudioEngine.Instance():getSoundsVolume(soundId)
	local delta = (volume - curVolume) / ticks

	self.fadeSoundTimer = self.fadeSoundTimer or {}

	---@type LuaTimer
	local LuaTimer = T(Lib, "LuaTimer")
	LuaTimer:cancel(self.fadeSoundTimer[soundId])

	self.fadeSoundTimer[soundId] = LuaTimer:scheduleTimer(function()
		curVolume = TdAudioEngine.Instance():getSoundsVolume(soundId)
		local volume = curVolume + delta
		TdAudioEngine.Instance():setSoundsVolume(soundId, volume)
		--Lib.logDebug("setSoundsVolume", soundId, volume)
	end, 50, ticks)
end

function Object:isPlaying(soundId)
	if soundId then
		return TdAudioEngine.Instance():isPlaying(soundId)
	end
	return false
end

-- 客户端光环，目前实际上仅有显示作用
function Object:addAura(name, info)
	if not World.gameCfg.debug then
		return
	end
	local auralist = self:data("aura")
	assert(not auralist[name], name)
	local range = info.range
	if not range and info.cfgName then
		local cfg = setting:fetch("aura", info.cfgName)
		range = cfg.range
	end
	range = math.floor((range or 5) / 1)	-- 整除，为了取整
	if range<0 then
		range = 0
	end
	local rangelist = self:data("aurarange")
	local rangedata = rangelist[range]
	if not rangedata then
		rangedata = {
			range = range,
			list = {},
		}
		rangelist[range] = rangedata
		self:createObjectSphere(range, range, range*1.2, 0, {x = 0, y = 0, z = 0})
	end
	rangedata.list[name] = true
	auralist[name] = rangedata
	return true
end

function Object:removeAura(name)
	local auralist = self.luaData.aura
	if not auralist then
		return false
	end
	local rangedata = auralist[name]
	if not rangedata then
		return false
	end
	auralist[name] = nil
	local list = rangedata.list
	list[name] = nil
	if not next(list) then
		self:data("aurarange")[rangedata.range] = nil
		self:removeObjectSphere(rangedata.range)
	end
	return true
end

function Object:call_sphereChange(...)
	self:onInteractionRangeChanged(...)
end

function Object:onInteractionRangeChanged(id, list)
	if id ~= self.interactionRange then
		return
	end
	local objID = self.objID
	Me:onInInteractionRangesChanged(self.objID, list[1][2])
end