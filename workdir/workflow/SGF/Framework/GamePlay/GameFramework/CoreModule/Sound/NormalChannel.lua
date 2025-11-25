--[[
    常规声音频道
    Date: 2024年10月21日
    Author: 揭育龙
    Copyright (c) 2024 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local SoundChannel = GFScript("CoreModule.Sound.SoundChannel")

local NormalChannel = Class.New("NormalChannel", SoundChannel)

--- 构造函数
-- @param soundManager 声音管理器
-- @param name 频道名称
-- @param maxSounds 最大同时播放的声音数量
-- @param defaultVolume 默认音量
function NormalChannel:Constructor(soundManager, name, maxSounds, defaultVolume)
    self.soundStates = {}
end

function NormalChannel:Destructor()
    for _, soundState in ipairs(self.soundStates) do
        if soundState ~= nil and soundState.finishEvent then
            soundState.finishEvent:Disconnect()
            soundState.finishEvent = nil
        end
    end
end

--- 播放声音
-- @param soundId 声音ID
-- @param options 播放选项
-- @return SandboxNode 播放的声音节点
function NormalChannel:PlaySound(soundId, options, finishedCallback)
    options = options or {}
    local priority = options.priority or 0  -- 默认优先级为0
    
    if #self.activeSounds >= self.maxSounds then
        -- 查找优先级最低的声音
        local lowestPriorityIndex = 1
        local lowestPriority = self.soundStates[self.activeSounds[1]] and self.soundStates[self.activeSounds[1]].priority or 0
        
        for i = 2, #self.activeSounds do
            local soundState = self.soundStates[self.activeSounds[i]]
            local soundPriority = soundState and soundState.priority or 0
            if soundPriority < lowestPriority then
                lowestPriority = soundPriority
                lowestPriorityIndex = i
            end
        end
        
        -- 如果新声音优先级不高于最低优先级的声音，则不播放
        if priority <= lowestPriority then
            if finishedCallback then
                finishedCallback(nil)
            end
            return nil
        end
        
        -- 移除优先级最低的声音
        local lowestPrioritySound = table.remove(self.activeSounds, lowestPriorityIndex)
        if lowestPrioritySound ~= nil then
            self:RecycleSoundAndState(lowestPrioritySound)
        end
    end

    local sound = self:AllocateSoundNode()
    sound.SoundPath = soundId
    sound.Volume = self:GetDerivedVolume()

    local soundState = {
        sound = sound,
        loopCount = options.loopCount,
        duration = options.duration,
        startTime = os.clock(),
        priority = priority  -- 保存优先级
    }
    if options.pos then
        sound.FixPos = Vector3.New(options.pos.x, options.pos.y, options.pos.z)
    end

    if options.bindObj then
        sound.TransObject = options.bindObj
    end
    if options.rollOffMode then
        sound.RollOffMode = options.rollOffMode
    end
    if options.rollOffMinDistance then
        sound.RollOffMinDistance = options.rollOffMinDistance
    end
    if options.rollOffMaxDistance then
        sound.RollOffMaxDistance = options.rollOffMaxDistance
    end

    sound.IsLoop = false

    soundState.finishEvent = sound.PlayFinish:Connect(function(node)  
        if options.loopCount then
            soundState.loopCount = soundState.loopCount - 1
            if soundState.loopCount <= 0 then
                self:StopSound(sound)
                if finishedCallback then
                    finishedCallback(nil)
                end
                return
            end
        end
        node:PlaySound()
        if finishedCallback then    
            finishedCallback(node)
        end 
    end)

    table.insert(self.activeSounds, sound)
    self.soundStates[sound] = soundState
    sound:PlaySound()
    self:OnPlaySound(sound)
    return sound
end

function NormalChannel:StopSoundById(soundId)
    for i, activeSound in ipairs(self.activeSounds) do
        if activeSound.SoundPath == soundId then
            table.remove(self.activeSounds, i)
            self:RecycleSoundAndState(activeSound)
            break
        end
    end
end

--- 停止指定声音
-- @param sound 要停止的声音节点
function NormalChannel:StopSound(sound)
    for i, activeSound in ipairs(self.activeSounds) do
        if activeSound == sound then
            table.remove(self.activeSounds, i)
            self:RecycleSoundAndState(sound)
            break
        end
    end
end

--- 停止所有声音
function NormalChannel:StopAllSounds()
    for _, sound in ipairs(self.activeSounds) do
        self:RecycleSoundAndState(sound)
    end
    self.activeSounds = {}
    self.soundStates = {}
end

-- 回收声音
function NormalChannel:RecycleSoundAndState(sound)
    self:RecycleSoundNode(sound)
    local state = self.soundStates[sound]
    if state then
        if state.finishEvent then
            state.finishEvent:Disconnect()
        end
        self.soundStates[sound] = nil
    end
end

--- 更新函数
-- @param dt 时间增量
function NormalChannel:Update(dt)
    -- 创建一个临时表来存储需要停止的声音
    local soundsToStop = {}
    
    for _, sound in ipairs(self.activeSounds) do
        if self.soundStates[sound] then
            local soundState = self.soundStates[sound]
            if soundState.duration and os.clock() - soundState.startTime >= soundState.duration then
                -- 不直接停止，而是记录下来
                table.insert(soundsToStop, sound)
            end
        end
    end
    
    -- 在遍历完成后再停止声音
    for _, sound in ipairs(soundsToStop) do
        self:StopSound(sound)
    end
end

--- 播放声音时回调
-- @param sound 播放的声音节点
function NormalChannel:OnPlaySound(sound)
end

--- 停止声音时回调
-- @param sound 停止的声音节点
function NormalChannel:OnStopSound(sound)
end

return NormalChannel
