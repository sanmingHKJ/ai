local DataProviderManager = {}
DataProviderManager.dataProviders = {}

--注册数据提供函数
function DataProviderManager:RegisterDataProvider(name, func)
    if not self.dataProviders then
        self.dataProviders = {}
    end
    self.dataProviders[name] = func
end

--获取数据
function DataProviderManager:GetData(name, ...)
    if not self.dataProviders then
        return nil
    end
    local func = self.dataProviders[name]
    if not func then
        return nil
    end
    return func(...)
end

--是否存在数据
function DataProviderManager:HasData(name, ...)
    return self:GetData(name, ...) ~= nil
end

-- 是否云数据
function DataProviderManager:IsCloudData(tid, prefix)
    return string.find(tid, prefix) == 1
end

-- 获取英雄数据
function DataProviderManager:GetPlayerData(tid)
    if self:IsCloudData(tid, "CloudPlayer_") then
        return self:GetData("CloudPlayer", tid)
    else
        local prefix = "Player."
        if string.find(tid, "Player_") then
            tid = prefix .. tid
        end
        return self:GetData("Player", tid)
    end
end

-- 是否有技能数据
function DataProviderManager:HasPlayerData(tid)
    return self:GetPlayerData(tid) ~= nil
end

-- 获取Monster数据
function DataProviderManager:GetMonsterData(tid)
    if self:IsCloudData(tid, "CloudMonster_") then
        return self:GetData("CloudMonster", tid)
    else
        local prefix = "Monster."
        if string.find(tid, "Monster_") then
            tid = prefix .. "Monster." .. tid
        elseif string.find(tid, "Boss_") then
            tid = prefix .. "Boss." .. tid
        end
        return self:GetData("Monster", tid)
    end
end

-- 是否有Monster数据
function DataProviderManager:HasMonsterData(tid)
    return self:GetMonsterData(tid) ~= nil
end

-- 获取Summon数据
function DataProviderManager:GetSummonData(tid)
    if self:IsCloudData(tid, "CloudSummon_") then
        return self:GetData("CloudSummon", tid)
    else
        return self:GetData("Summon", tid)
    end
end

-- 是否有Summon数据
function DataProviderManager:HasSummonData(tid)
    return self:GetSummonData(tid) ~= nil
end

-- 获取技能数据
function DataProviderManager:GetSkillData(tid)
    if self:IsCloudData(tid, "CloudSkill_") then
        return self:GetData("CloudSkill", tid)
    else
        return self:GetData("Skill", tid)
    end
end

-- 是否有技能数据
function DataProviderManager:HasSkillData(tid)
    return self:GetSkillData(tid) ~= nil
end

-- 获取buff数据
function DataProviderManager:GetBuffData(tid)
    if self:IsCloudData(tid, "CloudBuff_") then
        return self:GetData("CloudBuff", tid)
    else
        return self:GetData("Buff", tid)
    end
end

-- 获取场景数据
function DataProviderManager:GetSceneData(tid)
    return self:GetData("Scene", tid)
end

-- 是否有buff数据
function DataProviderManager:HasBuffData(tid)
    return self:GetBuffData(tid) ~= nil
end

-- 获取物品数据
function DataProviderManager:GetItemData(tid)
    return self:GetData("Item", tid)
end

-- 是否有物品数据
function DataProviderManager:HasItemData(tid)
    return self:GetItemData(tid) ~= nil
end


return DataProviderManager