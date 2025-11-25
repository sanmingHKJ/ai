--[[
    声音播放列表
    Date: 2025年8月29日
    Author: 揭育龙
    Copyright (c) 2025 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local TimerManager = GFScript("CoreModule.TimerManager")
local TableUtils = GFScript("CoreModule.TableUtils")
local SoundPlaylist = Class.New("SoundPlaylist")

--播放模式枚举，顺序播放，随机播放，单曲循环
local EPlayMode = {
    Sequence = "Sequence",
    Random = "Random"
}

function SoundPlaylist:Constructor(channelName)
    self.channelName = channelName
    self.currentIndex = 0
    self.playMode = EPlayMode.Sequence
    self.isPlaying = false
    self.isLoop = false --歌单循环
    --播放间隔
    self.playInterval = {0, 0}

    self.soundList = {}

    self.playQueue = {}

    
    self.updateTimer = TimerManager:AddTimer(function(dt)
        self:Update(dt)
    end, 0.1)
end

function SoundPlaylist:Destructor()
    if self.updateTimer then
        TimerManager:RemoveTimer(self.updateTimer)
        self.updateTimer = nil
    end
end

function SoundPlaylist:SetPlayMode(playMode)
    self.playMode = playMode
end

function SoundPlaylist:SetPlayInterval(min, max)
    self.playInterval = {min, max or min}
end

function SoundPlaylist:SetLoop(isLoop)
    self.isLoop = isLoop
end

--添加歌曲      
function SoundPlaylist:AddSound(soundId, loopCount)
    loopCount = loopCount or {1, 1}
    table.insert(self.soundList, {soundId = soundId, loopCount = loopCount})
end

--构建播放队列
function SoundPlaylist:BuildPlayQueue()
    self.playQueue = {}
    if self.playMode == EPlayMode.Sequence then
        for _, sound in ipairs(self.soundList) do
            local loopCount = sound.loopCount
            local randomLoopCount = math.random(loopCount[1], loopCount[2])  
            for i = 1, randomLoopCount do
                local interval = math.random(self.playInterval[1], self.playInterval[2])  
                table.insert(self.playQueue, {sound.soundId, interval})
            end
        end
    elseif self.playMode == EPlayMode.Random then
        local tempList = Utils:ShallowCopy(self.soundList)
        while #tempList > 0 do
            local randomIndex = math.random(1, #tempList)
            local loopCount = tempList[randomIndex].loopCount
            local randomLoopCount = math.random(loopCount[1], loopCount[2])
            for i = 1, randomLoopCount do
                local interval = math.random(self.playInterval[1], self.playInterval[2])
                table.insert(self.playQueue, {tempList[randomIndex].soundId, interval})
            end
            table.remove(tempList, randomIndex)
        end
    end
    return self.playQueue
end

--播放
function SoundPlaylist:Play()
    self.isPlaying = true
    self.currentIndex = 0
    self:BuildPlayQueue()
    self:PlayNextSound()
end

function SoundPlaylist:Stop()
    self.isPlaying = false
    self.currentIndex = 0   
end

--播放下一首
function SoundPlaylist:PlayNextSound()
    if #self.playQueue == 0 then
        self.isPlaying = false
        return
    end
    local soundElem, currentIndex, atEnd = TableUtils:GetNext(self.playQueue, self.currentIndex, self.isLoop)
    if soundElem then
        local soundId = soundElem[1]
        local interval = soundElem[2]
        SoundManager:PlaySound(self.channelName, soundId, nil, function()
            SoundManager:StopSound(self.channelName, soundId)
            self.nextSoundTimeEnd = Utils:GetServerTime() + interval
        end)
        if atEnd then
            self:BuildPlayQueue()
            self.currentIndex = 0
        end
        self.currentIndex = currentIndex
    end
end

--播放上一首
function SoundPlaylist:PlayPreviousSound()
    if #self.playQueue == 0 then
        self.isPlaying = false
        return
    end
    local soundElem, currentIndex, atEnd = TableUtils:GetPrevious(self.playQueue, self.currentIndex, self.isLoop)
    if soundElem then
        local soundId = soundElem[1]
        local interval = soundElem[2]
        SoundManager:PlaySound(self.channelName, soundId, nil, function()
            SoundManager:StopSound(self.channelName, soundId)
            self.nextSoundTimeEnd = Utils:GetServerTime() + interval
        end)
        if atEnd then
            self:BuildPlayQueue()
            self.currentIndex = 0
        end
        self.currentIndex = currentIndex
    end
end

function SoundPlaylist:Update(dt)
    if self.nextSoundTimeEnd and Utils:GetServerTime() >= self.nextSoundTimeEnd then
        self:PlayNextSound()
        self.nextSoundTimeEnd = nil
    end
end


return SoundPlaylist    