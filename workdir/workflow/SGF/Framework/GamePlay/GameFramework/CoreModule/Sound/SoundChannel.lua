--[[
    声音频道基类
    Date: 2024年10月21日
    Author: 揭育龙
    Copyright (c) 2024 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local SoundChannel = Class.New("SoundChannel")

--- 构造函数
-- @param soundManager 声音管理器
-- @param name 频道名称
-- @param maxSounds 最大同时播放的声音数量
-- @param defaultVolume 默认音量
function SoundChannel:Constructor(soundManager, name, maxSounds, defaultVolume)
    self.soundManager = soundManager
    self.name = name
    self.maxSounds = maxSounds or 10
    self.volume = defaultVolume or 1
    self.activeSounds = {}
    self.soundNodePool = {} -- 声音节点池
    
    self.sound_channel = SandboxNode.New('SoundGroup')
    self.sound_channel.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.sound_channel.Name = name
    self.sound_channel.Parent = self.soundManager.sound_group
end

function SoundChannel:Destructor()
    self.sound_channel:Destroy()
end

--- 添加声音到频道
-- @param sound 要添加的声音
-- @return boolean 是否添加成功
function SoundChannel:AddSound(sound)
    if #self.activeSounds >= self.maxSounds then
        Log:Warn("SoundChannel", "Max sounds reached for channel: " .. self.name)
        return false
    end
    table.insert(self.activeSounds, sound)
    self:UpdateSoundVolume(sound)
    return true
end

--- 从频道移除声音
-- @param sound 要移除的声音
-- @return boolean 是否移除成功
function SoundChannel:RemoveSound(sound)
    for i, activeSound in ipairs(self.activeSounds) do
        if activeSound == sound then
            table.remove(self.activeSounds, i)
            return true
        end
    end
    return false
end

--- 设置频道音量
-- @param volume 音量值 (0-1)
function SoundChannel:SetVolume(volume)
    self.volume = math.clamp(volume, 0, 1)
    self:UpdateAllSoundVolumes()
end

--- 获取频道音量
-- @return number 当前音量值
function SoundChannel:GetVolume()
    return self.volume
end

--- 更新所有声音的音量
function SoundChannel:UpdateAllSoundVolumes()
    for _, sound in ipairs(self.activeSounds) do
        self:UpdateSoundVolume(sound)
    end
end

--- 更新单个声音的音量
-- @param sound 要更新的声音
function SoundChannel:UpdateSoundVolume(sound)
    if sound and sound.SetVolume then
        sound:SetVolume(self:GetDerivedVolume())
    end
end

--- 计算实际音量
-- @param sound 声音对象（未使用）
-- @return number 计算后的音量值
function SoundChannel:GetDerivedVolume(sound)
    return self.volume * self:GetMasterVolume()
end

--- 获取总音量
-- @return number 总音量值
function SoundChannel:GetMasterVolume()
    return self.soundManager:GetMasterVolume()
end

--- 从池中分配声音节点
-- @return SandboxNode 分配的声音节点
function SoundChannel:AllocateSoundNode()
    local sound
    if #self.soundNodePool > 0 then
        sound = table.remove(self.soundNodePool)
    else
        sound = SandboxNode.New('Sound', self.sound_channel)
        sound.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    end
    return sound
end

--- 回收声音节点到池中
-- @param sound 要回收的声音节点
function SoundChannel:RecycleSoundNode(sound)
    if sound then
        self:OnStopSound(sound)
        sound:StopSound()
        -- sound.SoundPath = ""
        sound.TransObject = nil
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.RollOffMinDistance = 2000
        sound.RollOffMaxDistance = 3500
        table.insert(self.soundNodePool, sound)
    end
end

--- 播放声音时回调
-- @param sound 播放的声音节点
function SoundChannel:OnPlaySound(sound)
    
end

--- 停止声音时回调
-- @param sound 停止的声音节点
function SoundChannel:OnStopSound(sound)
    
end

--- 更新函数（可在子类中重写）
-- @param dt 时间增量
function SoundChannel:Update(dt)
end

return SoundChannel
