local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local PlayerManager = GFScript("ActorModule.PlayerManager")

local StatKismet = {}
----------------------------------------------属性相关------------------------------------------------
--[Server]设置基础Stat值
--@param playerId 玩家ID
--@param statType 属性类型
--@param value 值
--@return 是否成功
function StatKismet:SetBaseStatValue(playerId, statType, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:SetBaseStatValue(statType, value)
            return true
        end
    end
    return false
end

--[任意]获取基础Stat值
--@param playerId 玩家ID
--@param statType 属性类型
--@return 值
function StatKismet:GetBaseStatValue(playerId, statType)
    local player = PlayerManager:GetPlayer(playerId)
    if player then
        return player:GetBaseStatValue(statType)
    end
    return 0
end

--[任意]获取最终Stat值，该值包含其他系统加成得出的结果
--@param playerId 玩家ID
--@param statType 属性类型
--@return 值
function StatKismet:GetStatValue(playerId, statType)
    local player = PlayerManager:GetPlayer(playerId)
    if player then
        return player:GetStatValue(statType)
    end
    return 0
end


----------------------------------------------生命相关------------------------------------------------
--[Server]设置血量
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:SetHealth(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:SetHealth(value)
            return true
        end
    end
    return false
end
--[Server]增加血量
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:AddHealth(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:AddHealth(value)
            return true
        end
    end
    return false
end
--[Server]减少血量
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:SubHealth(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:SubHealth(value)
            return true
        end
    end
    return false
end
--[任意]获取血量
--@param playerId 玩家ID
--@return 值
function StatKismet:GetHealth(playerId)
    local player = PlayerManager:GetPlayer(playerId)
    if player then
        return player:GetHealth()
    end
    return 0
end

----------------------------------------------法力相关------------------------------------------------
--[Server]设置法力
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:SetMana(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:SetMana(value)
            return true
        end
    end
    return false
end
--[Server]增加法力
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:AddMana(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:AddMana(value)
            return true
        end
    end
    return false
end
--[Server]减少法力
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:SubMana(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player:SubMana(value)
            return true
        end
    end
    return false
end
--[任意]获取法力
--@param playerId 玩家ID
--@return 值
function StatKismet:GetMana(playerId)
    local player = PlayerManager:GetPlayer(playerId)
    if player then
        return player:GetMana()
    end
    return 0
end
--[Server]使用法力
--@param playerId 玩家ID
--@param value 值
--@return 是否成功
function StatKismet:UseMana(playerId, value)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            return player:UseMana(value)
        end
    end
    return false
end

----------------------------------------------属性定义相关------------------------------------------------
--[任意]定义属性
--@param name 名字
--@param desc 描述
--@param chance 是否是概率
--@param default 默认值
--@param changedCallback 属性改变回调：param player, oldValue, newValue
function StatKismet:DefineStat(name, desc, chance, default, changedCallback)
    StatDefines:DefineStat(name, desc, chance, default, changedCallback)
end
--[任意]设置属性回调
--@param name 名字
--@param changedCallback 属性改变回调：param player, oldValue, newValue
function StatKismet:SetStatChangedCallback(name, changedCallback)
    StatDefines:SetStatChangedCallback(name, changedCallback)
end
--[任意]是否是概率属性
--@param name 名字
--@return 是否是概率属性
function StatKismet:IsChanceStat(name)
    return StatDefines:IsChanceStat(name)
end
--[任意]获取属性定义
--@param name 名字
--@return 属性定义
function StatKismet:GetStatDefine(name)
    return StatDefines:GetStatDefine(name)
end

--[Server]定义属性集
--@param playerId 玩家ID
--@param name 名字
--@param priority 优先级
--@param calcStatsFunc 计算属性的函数
--@return 是否成功
function StatKismet:AddStatAffecter(playerId, name, priority, calcStatsFunc)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player.statManager:AddStatAffecter(name, priority, calcStatsFunc)
            return true
        end
    end
    return false
end

--[Server]设置属性集脏标记
--@param playerId 玩家ID
--@param name 名字
--@param dirty 是否需要重新计算
--@return 是否成功
function StatKismet:SetStatAffecterDirty(playerId, name)
    if Utils:IsServer() then
        local player = PlayerManager:GetPlayer(playerId)
        if player then
            player.statManager:SetStatAffecterDirty(name)
            return true
        end
    end
    return false
end


return StatKismet