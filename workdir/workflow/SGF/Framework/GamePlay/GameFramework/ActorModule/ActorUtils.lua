-- 说明:角色工具类
-- 日期:2025年6月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local ActorSettings = GFScript("ActorModule.ActorSettings")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorUtils = {}

--根据id获取类型
function ActorUtils:GetActorType(tid)
    for _, actorIdRange in pairs(ActorSettings.ActorIdRange) do
        if tid >= actorIdRange[2] and tid <= actorIdRange[3] then
            return actorIdRange[1]
        end
    end
    return nil
end

--根据id段号获取对应的配置表
function ActorUtils:GetActorTableByTid(tid)
    local actorType = self:GetActorType(tid)
    if actorType then
        return self:GetActorTable(actorType)
    end
    return ActorSettings.Table
end

--根据类型获取对应的配置表
function ActorUtils:GetActorTable(actorType)
    return ActorSettings.TableByType[actorType] or ActorSettings.Table
end

return ActorUtils