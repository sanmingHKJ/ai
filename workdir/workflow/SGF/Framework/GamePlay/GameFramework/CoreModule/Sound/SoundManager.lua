--[[
    声音管理器
    Date: 2024年10月21日
    Author: 揭育龙
    Copyright (c) 2024 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local SoundChannel = GFScript("CoreModule.Sound.SoundChannel")
local FadeChannel = GFScript("CoreModule.Sound.FadeChannel")
local NormalChannel = GFScript("CoreModule.Sound.NormalChannel")

local SoundManager = Class.New("SoundManager")

-- 定义声音频道
local SoundChannels = {
    Music = { volume = 1, fadeTime = 1, maxSounds = 2, type = "FadeChannel" }, --背景音乐
    Ambient = { volume = 1, fadeTime = 0.5, maxSounds = 3, type = "NormalChannel" }, --环境音
    Footstep = { volume = 1, fadeTime = 0, maxSounds = 5, type = "NormalChannel" }, --脚步声
    Effect = { volume = 1, fadeTime = 0, maxSounds = 50, type = "NormalChannel" }, --效果音
    Gun = { volume = 1, fadeTime = 0, maxSounds = 50, type = "NormalChannel" }, --枪械音效
    Voice = { volume = 1, fadeTime = 0.1, maxSounds = 10, type = "NormalChannel" }, --语音
    UI = { volume = 1, fadeTime = 0, maxSounds = 3, type = "NormalChannel" } --UI音效
}

local MasterVolume = 1
local ChannelInstances = {}

function SoundManager:Constructor()
    self.sound_group = nil
end

-- 释放资源
function SoundManager:Destructor()
    self:StopAllSounds()
    for _, channel in pairs(ChannelInstances) do
        channel:Destroy()
    end
    ChannelInstances = {}
    if self.sound_group then
        self.sound_group:Destroy()
        self.sound_group = nil
    end
end
-- 初始化声音管理器
function SoundManager:Init()

end

function SoundManager:OnPostInitialization()
    if self.sound_group then
        return
    end
    --读取GameSettings
    local soundSettings = GameFramework:GetGameSetting().Sound
    if soundSettings then
        self:SetMasterVolume(soundSettings.MasterVolume)
        for channelName, config in pairs(soundSettings.Channel) do
            if SoundChannels[channelName] then
                SoundChannels[channelName].volume = config.volume
                SoundChannels[channelName].fadeTime = config.fadeTime
            end
        end
    end
    
    local defworkspace = game:GetService("WorkSpace")
    self.sound_group = SandboxNode.New('SoundGroup')
    self.sound_group.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.sound_group.Name = 'SoundManager'
    self.sound_group.Parent = defworkspace

    local SceneManager = GFScript("ActorModule.SceneManager")
    SceneManager:OnClientEvent("SceneChanged", function(scene)
        self.sound_group.Parent = scene:GetWorkspace()
    end)

    for channelName, channelData in pairs(SoundChannels) do
        ChannelInstances[channelName] = self:CreateChannel(channelName, channelData)
    end
end

-- 创建频道
function SoundManager:CreateChannel(channelName, channelData)
    if channelData.type == "FadeChannel" then   
        return FadeChannel.New(self, channelName, channelData.maxSounds, channelData.volume)
    elseif channelData.type == "NormalChannel" then
        return NormalChannel.New(self, channelName, channelData.maxSounds, channelData.volume)
    end
    return nil
end

-- 设置主音量
function SoundManager:SetMasterVolume(volume)
    MasterVolume = math.clamp(volume, 0, 1)
    self:UpdateAllChannelVolumes()
end

-- 获取主音量
function SoundManager:GetMasterVolume()
    return MasterVolume
end

-- 设置指定频道音量
function SoundManager:SetChannelVolume(channelName, volume)
    if ChannelInstances[channelName] then
        ChannelInstances[channelName]:SetVolume(volume)
        self:UpdateChannelVolume(channelName)
    else
        Log:Warn("SoundManager", "Invalid channel name: " .. channelName)
    end
end

-- 获取指定频道音量
function SoundManager:GetChannelVolume(channelName)
    if ChannelInstances[channelName] then
        return ChannelInstances[channelName]:GetVolume()
    else
        Log:Warn("SoundManager", "Invalid channel name: " .. channelName)
        return 0
    end
end

-- 更新所有频道音量
function SoundManager:UpdateAllChannelVolumes()
    for channelName, _ in pairs(ChannelInstances) do
        self:UpdateChannelVolume(channelName)
    end
end

-- 更新指定频道音量
function SoundManager:UpdateChannelVolume(channelName)
    local channel = ChannelInstances[channelName]
    if channel then
        channel:UpdateAllSoundVolumes()
    end
end

-- 更新
function SoundManager:Update(dt)
    for _, channel in pairs(ChannelInstances) do
        channel:Update(dt)
    end
end

function SoundManager:GetSoundPath(channelName, soundId)
    if Utils:StartWith(soundId, "sandboxId://") or Utils:StartWith(soundId, "SandboxId://") then  
        return soundId
    end
    return "sandboxId://Sounds/" .. channelName .. "/" .. soundId 
end

-- 指定频道播放声音
function SoundManager:PlaySound(channelName, soundId, options, finishedCallback)
    local channel = ChannelInstances[channelName]
    if channel then
        return channel:PlaySound(self:GetSoundPath(channelName, soundId), options, finishedCallback)
    end
end

-- 按路径获取sound对象
function SoundManager:StopSoundById(channelName, soundId)
    local channel = ChannelInstances[channelName]
    if channel then
        channel:StopSoundById(self:GetSoundPath(channelName, soundId))
    end
end

-- 指定频道停止声音
function SoundManager:StopSound(channelName, sound)
    local channel = ChannelInstances[channelName]
    if channel then
        if type(sound) == "string" then
            channel:StopSoundById(self:GetSoundPath(channelName, sound))
        else
            channel:StopSound(sound)
        end
    end
end

-- 停止所有声音
function SoundManager:StopAllSounds()
    for _, channel in pairs(ChannelInstances) do
        channel:StopAllSounds()
    end
end

return SoundManager
