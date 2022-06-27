local soundPath = 'asset/Audio/'

local audioCfg = {
    captureFlag = { soundType = 0, soundPath = soundPath .. 'occupied.mp3', volume = 1, time = 5 },
    pickFlag = { soundType = 0, soundPath = soundPath .. 'PickUp.mp3', volume = 1, time = 5 },
    takenFlag = { soundType = 0, soundPath = soundPath .. 'prompt.mp3', volume = 1, time = 5 },
    loseFlag = { soundType = 0, soundPath = soundPath .. 'prompt.mp3', volume = 1, time = 5 },
    addScore = { soundType = 0, soundPath = soundPath .. 'Score.mp3', volume = 1, time = 5 },
    wait = { soundType = 0, soundPath = soundPath .. 'BattleReady.mp3', volume = 1, time = -1 },
    readyStart = { soundType = 0, soundPath = soundPath .. 'countdown.mp3', volume = 1, time = -1 },
    start = { soundType = 0, soundPath = soundPath .. 'Beyond.mp3', volume = 1, time = -1 },
    finish = { soundType = 0, soundPath = soundPath .. 'Bleu.mp3', volume = 1, time = -1 },
}

local function getSoundCfg(soundName)
    return audioCfg[soundName]
end

local Audio = {} ---@class Audio
local audioEngine = TdAudioEngine.Instance()
Lib.declare("Audio", Audio)

local soundList = {}
local soundIDTb = {}

local globalMusicID

function Audio.PlaySound(soundName, pos)
    local soundData = getSoundCfg(soundName)

    if not soundData then
        return
    end

    local soundID
    if soundData.soundType == 1 then
        soundID = audioEngine:play3dSound(soundData.soundPath, pos)
    else
        soundID = audioEngine:play2dSound(soundData.soundPath, soundData.time == -1)
    end

    if soundID and soundID ~= 0 then
        audioEngine:setSoundsVolume(soundID, soundData.volume)
        --audioEngine:set3DRollOffMode(soundID, 0x00040000)
        audioEngine:set3DRollOffMode(soundID, 0x00100000)
        local stopTime = soundData.time
        if stopTime ~= -1 then
            soundList[soundID] = World.Timer(stopTime * 20, function()
                audioEngine:stopSound(soundID)
                soundList[soundID] = nil
            end)
        end
    end
    soundIDTb[soundName] = soundID
    return soundID
end

function Audio.GetSoundIDByName(soundName)
    return soundIDTb[soundName]
end

function Audio.StopSound(soundID)
    if soundList[soundID] then
        soundList[soundID]()
        soundList[soundID] = nil
    end
    audioEngine:stopSound(soundID)
end

function Audio.PlayGlobalSound(soundName)
    local useless = globalMusicID and Audio.StopSound(globalMusicID)
    globalMusicID = Audio.PlaySound(soundName, nil, true)
end

return Audio

