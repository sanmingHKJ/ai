--[[
    支持淡入淡出的声音频道
    Date: 2024年10月21日
    Author: 揭育龙
    Copyright (c) 2024 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Tween = GFScript("CoreModule.Tween") 
local SoundChannel = GFScript("CoreModule.Sound.SoundChannel")

local FadeChannel = Class.New("FadeChannel", SoundChannel)

--- 构造函数
-- @param soundManager 声音管理器
-- @param name 频道名称
-- @param maxSounds 最大同时播放的声音数量（此处固定为3）
-- @param defaultVolume 默认音量
function FadeChannel:Constructor(soundManager, name, maxSounds, defaultVolume)
    self.currentMusic = nil  -- 当前正在播放的音乐
    self.nextMusic = nil     -- 下一个要播放的音乐
    self.fadeInTime = 1      -- 淡入时间（秒）
    self.fadeOutTime = 1     -- 淡出时间（秒）
    self.currentTween = nil  -- 当前正在执行的渐变动画
end

--- 播放声音
-- @param soundId 声音ID
-- @param options 播放选项（可选）
-- @return SandboxNode 播放的声音节点
function FadeChannel:PlaySound(soundId, options, finishedCallback)
    options = options or {}
    
    local newSoundPath = soundId
    if self.currentMusic and self.currentMusic.SoundPath == newSoundPath then
        if finishedCallback then
            finishedCallback(self.currentMusic)
        end
        return -- 如果要播放的音乐与当前音乐相同，则不做任何操作
    end

    local newMusic = self:AllocateSoundNode()

    newMusic.PlayFinish:Clear()
    newMusic.PlayFinish:Connect(function(node)
        node:PlaySound()
        if finishedCallback then    
            finishedCallback(node)
        end 
    end)
    
    newMusic.SoundPath = newSoundPath
    newMusic.IsLoop = false
    newMusic.Volume = 0 -- 从0开始，用于淡入

    if self.currentMusic then
        if self.nextMusic then
            -- 如果已经有一个正在淡入的音乐，停止它并回收
            self:StopSound(self.nextMusic)
        end
        self.nextMusic = newMusic
        self:CrossFade()
    else
        self.currentMusic = newMusic
        self:FadeInMusic(self.currentMusic)
    end

    return newMusic
end

function FadeChannel:StopSoundById(soundId)
    if self.currentMusic and self.currentMusic.SoundPath == soundId then
        self:StopSound(self.currentMusic)
    elseif self.nextMusic and self.nextMusic.SoundPath == soundId then
        self:StopSound(self.nextMusic)
    else
        print("FadeChannel:StopSoundById sound管理逻辑错误")
    end
end

--- 停止指定声音
-- @param sound 要停止的声音节点
function FadeChannel:StopSound(sound)
    if self.currentTween then
        Tween:Cancel(self.currentTween)
        self.currentTween = nil
    end

    if sound == self.currentMusic or sound == self.nextMusic then
        self:FadeOutMusic(sound)
    else
        self:RecycleSoundNode(sound)
    end
end

--- 交叉淡入淡出
function FadeChannel:CrossFade()
    if self.currentTween then
        Tween:Cancel(self.currentTween)
    end

    local fadeOutMusic = self.currentMusic
    local fadeInMusic = self.nextMusic

    self.currentTween = Tween:AlphaBy(function(progress)
        if fadeOutMusic then fadeOutMusic.Volume = (1 - progress) * self:GetDerivedVolume() end
        if fadeInMusic then fadeInMusic.Volume = progress * self:GetDerivedVolume() end
    end, 0, 1, self.fadeOutTime, Tween.Easing.Linear)

    Tween:SetComplete(self.currentTween, function()
        self:RecycleSoundNode(fadeOutMusic)
        self.currentMusic = fadeInMusic
        self.nextMusic = nil
        self.currentTween = nil
    end)

    fadeInMusic:PlaySound()
end

--- 淡入音乐
-- @param music 要淡入的音乐节点
function FadeChannel:FadeInMusic(music)
    if self.currentTween then
        Tween:Cancel(self.currentTween)
    end

    self.currentTween = Tween:AlphaBy(function(progress)
        music.Volume = progress * self:GetDerivedVolume()
    end, 0, 1, self.fadeInTime, Tween.Easing.Linear)

    Tween:SetComplete(self.currentTween, function()
        self.currentTween = nil
    end)

    music:PlaySound()
end

--- 淡出音乐
-- @param music 要淡出的音乐节点
function FadeChannel:FadeOutMusic(music)
    local fadeOutTween = Tween:AlphaBy(function(progress)
        music.Volume = (1 - progress) * self:GetDerivedVolume()
    end, 1, 0, self.fadeOutTime, Tween.Easing.Linear)

    Tween:SetComplete(fadeOutTween, function()
        self:RecycleSoundNode(music)
        if music == self.currentMusic then
            self.currentMusic = nil
        elseif music == self.nextMusic then
            self.nextMusic = nil
        end
    end)
end

--- 设置频道音量
-- @param volume 音量值 (0-1)
function FadeChannel:SetVolume(volume)
    SoundChannel.SetVolume(self, volume)
    if self.currentMusic then
        self.currentMusic.Volume = self:GetDerivedVolume()
    end
    if self.nextMusic then
        self.nextMusic.Volume = self:GetDerivedVolume()
    end
end

return FadeChannel
