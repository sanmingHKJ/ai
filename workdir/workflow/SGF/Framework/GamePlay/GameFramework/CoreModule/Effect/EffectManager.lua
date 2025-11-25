--[[
    特效管理器
    Date: 2025年6月7日
    Author: 揭育龙
    Copyright (c) 2025 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Effect = GFScript("CoreModule.Effect.Effect")
local EffectManager = Class.New("EffectManager")

-- 按assetId分组的缓存池
EffectManager.cachedEffectGroups = {}
EffectManager.activedEffects = {}
EffectManager.autoId = 0

function EffectManager:Init()
    -- 按assetId分组的缓存池，结构：{assetId = {effects = {}, lastUseTime = timestamp}}
    self.cachedEffectGroups = {}
    self.activedEffects = {}
    self.autoId = 0

    -- 每个分组的最大缓存数量
    self.maxCachedEffects = 100
    -- 清理间隔时间（秒）
    self.cleanupInterval = 30 -- 30秒
    -- 分组过期时间（秒）
    self.groupExpireTime = 180 -- 3分钟
    -- 上次清理时间
    self.lastCleanupTime = 0
end

-- 更新
function EffectManager:Update(dt)
    -- 检查并清理死亡的特效
    for id, effect in pairs(self.activedEffects) do
        if effect:IsDead() then
            self:RecycleEffect(effect)
        end
    end
    
    -- 定时清理长期不使用的分组
    local currentTime = Utils:GetServerTime()
    if currentTime - self.lastCleanupTime >= self.cleanupInterval then
        self:CleanupExpiredGroups()
        self.lastCleanupTime = currentTime
    end
end

-- 清理过期的分组
function EffectManager:CleanupExpiredGroups()
    local currentTime = Utils:GetServerTime()
    local expiredGroups = {}
    
    for assetId, group in pairs(self.cachedEffectGroups) do
        if currentTime - group.lastUseTime >= self.groupExpireTime then
            table.insert(expiredGroups, assetId)
        end
    end
    
    for _, assetId in ipairs(expiredGroups) do
        local group = self.cachedEffectGroups[assetId]
        -- 销毁该分组中的所有缓存特效
        for _, effect in ipairs(group.effects) do
            effect:Destroy()
        end
        self.cachedEffectGroups[assetId] = nil
        Log:Info("EffectManager: Cleaned up expired effect group for assetId: " .. assetId)
    end
end

function EffectManager:NewAutoId()
    self.autoId = self.autoId + 1
    return self.autoId
end

-- 分配特效
function EffectManager:AllocateEffect(assetId)
    -- 确保分组存在
    if not self.cachedEffectGroups[assetId] then
        self.cachedEffectGroups[assetId] = {
            effects = {},
            lastUseTime = Utils:GetServerTime()
        }
    end
    
    local group = self.cachedEffectGroups[assetId]
    
    -- 更新最后使用时间
    group.lastUseTime = Utils:GetServerTime()
    
    -- 从缓存池中获取特效
    if #group.effects > 0 then
        local cachedEffect = group.effects[1]
        table.remove(group.effects, 1)
        cachedEffect:SetAssetID(assetId)
        cachedEffect:OnAllocate()
        return cachedEffect
    end

    -- 创建新的特效
    local effect = Effect.New()
    effect:Init(assetId)
    effect:OnAllocate()
    return effect
end

-- 回收特效
function EffectManager:RecycleEffect(effect)
    if not effect.id then
        return
    end
    
    -- 获取特效的assetId
    local assetId = effect:GetAssetID()
    if not assetId then
        -- 如果无法获取assetId，直接销毁
        self.activedEffects[effect.id] = nil
        effect:Destroy()
        return
    end
    
    -- 确保分组存在
    if not self.cachedEffectGroups[assetId] then
        self.cachedEffectGroups[assetId] = {
            effects = {},
            lastUseTime = Utils:GetServerTime()
        }
    end
    
    local group = self.cachedEffectGroups[assetId]
    
    -- 检查分组是否已满
    if #group.effects >= self.maxCachedEffects then
        self.activedEffects[effect.id] = nil
        effect:Destroy()
        return
    end
    
    -- 回收特效到对应分组
    effect:OnRecycle()
    table.insert(group.effects, effect)
    self.activedEffects[effect.id] = nil
    effect:SetId(nil)
    effect:SetParent(nil)
end

-- 播放特效
function EffectManager:PlayEffect(assetID, once, parent)
    local effect = self:AllocateEffect(assetID)
    effect:SetId(self:NewAutoId())
    if parent then
        effect:SetParent(parent)
    end
    effect:Play(once)
    self.activedEffects[effect.id] = effect
    return effect
end

-- 停止特效
function EffectManager:StopEffect(effectId)
    local effect = self.activedEffects[effectId]
    if effect then
        effect:Stop()
        self:RecycleEffect(effect)
    end
end

-- 获取缓存统计信息
function EffectManager:GetCacheStats()
    local stats = {
        totalGroups = 0,
        totalCachedEffects = 0,
        groupDetails = {}
    }
    
    for assetId, group in pairs(self.cachedEffectGroups) do
        stats.totalGroups = stats.totalGroups + 1
        stats.totalCachedEffects = stats.totalCachedEffects + #group.effects
        stats.groupDetails[assetId] = {
            count = #group.effects,
            lastUseTime = group.lastUseTime
        }
    end
    
    return stats
end

-- 手动清理指定assetId的分组
function EffectManager:ClearGroup(assetId)
    local group = self.cachedEffectGroups[assetId]
    if group then
        for _, effect in ipairs(group.effects) do
            effect:Destroy()
        end
        self.cachedEffectGroups[assetId] = nil
        Log:Info("EffectManager: Manually cleared effect group for assetId: " .. assetId)
    end
end

-- 手动清理所有缓存
function EffectManager:ClearAllCache()
    for assetId, group in pairs(self.cachedEffectGroups) do
        for _, effect in ipairs(group.effects) do
            effect:Destroy()
        end
    end
    self.cachedEffectGroups = {}
    Log:Info("EffectManager: Cleared all effect cache")
end

return EffectManager