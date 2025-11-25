local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local SkillEventHandler = GFScript("SkillModule.SkillEventHandler")
local TargetUtils = GFScript("CombatModule.TargetUtils")

local ExternalSkillEventHandler = {}
-- ExternalSkillEventHandler.__index = function(table, key)
--     local value = rawget(ExternalSkillEventHandler, key)
--     if value then
--         return value
--     end
--     return SkillEventHandler[key]
-- end
setmetatable(ExternalSkillEventHandler, {__index = SkillEventHandler})

--替换技能弹道
function ExternalSkillEventHandler:ReplaceProjectile(skill, params)
    if not self:CheckCondition(skill, target, params.condition) then
        return
    end
    local replaceId = params.replaceId
    local needRemoves = {}
    skill:ForEachTargets(function(target)
        if target:GetTag() == ActorDefines.ProjectileTag and target.projectileId == replaceId then
            local nodeTemplate = nil
            if params.hasAsset and not Utils:IsNullOrEmpty(params.asset) then
                nodeTemplate = Utils:GetMainStorageNode(params.asset)
            end
            local projectile = Projectile.New(skill.actor:GetScene(), nodeTemplate)
            projectile.skill = skill
            projectile.shape = (not Utils:IsNullOrEmpty(params.shape)) and params.shape or "Cylinder"
            projectile.radius = params.radius or 0
            projectile.height = params.height or 0
            projectile.width = params.width or 0
            projectile.angle = params.angle or 0
            projectile.length = params.length or 0
            projectile.projectileId = params.projectileId
            projectile:SetTargetClearInterval(params.resetInterval)
            projectile:SetTargetHitCount(params.maxTargetHitCount)
            projectile.filterFunc = SkillEventHandler.TargetFilter
            projectile.penetrate = (params.penetrate == nil and true or params.penetrate)
            projectile.delayTime = params.delayTime or 0
            
            local duration = params.duration
            --如果配置了距离，以距离计算时间
            if not Utils:IsNullOrZero(params.distance) then
                duration = params.distance / params.speed
            end
            local callback = "onHit"
            if not Utils:IsNullOrEmpty(params.hitCallback) then
                callback = params.hitCallback
            end
            projectile.hitCallback = function(actor)
                skill:ServerFireAllSkillEvents(callback)
            end

            local startPosition = target:GetPosition()
            if params.groundCast then
                local groundPos = skill.actor:GetGroundPosition(startPosition)
                startPosition = Vec3.New(groundPos.x, groundPos.y, groundPos.z)
            end
            
            local dir = target:GetForward()
            projectile:Start(startPosition, 
                dir * params.speed, duration, params.easing)

            target:Dead()
            table.insert(needRemoves, target)
        end
    end)
    --从skill.targets中移除
    for _,v in ipairs(needRemoves) do
        skill:RemoveHitTarget(v)
    end
end
--创建陷阱
function ExternalSkillEventHandler:_CreateTrap(startPosition, skill, params)
    local targetFilter = function(target)
        return self:TargetFilter(skill.actor, target, params, true, false)
    end

    local nodeTemplate = nil
    if params.hasAsset and not Utils:IsNullOrEmpty(params.asset) then
        nodeTemplate = Utils:GetMainStorageNode(params.asset)
    end

    local projectile = Projectile.New(skill.actor:GetScene(), nodeTemplate)
    projectile.skill = skill
    projectile.shape = (not Utils:IsNullOrEmpty(params.shape)) and params.shape or "Cylinder"
    projectile.radius = params.radius or 0
    projectile.height = params.height or 0
    projectile.width = params.width or 0
    projectile.angle = params.angle or 0
    projectile.length = params.length or 0
    projectile.category = "Trap"
    if not Utils:IsNullOrZero(params.hitTag) then
        projectile.hitTag = params.hitTag
    end
    projectile.projectileId = params.projectileId
    projectile:SetTargetClearInterval(params.resetInterval)
    projectile:SetTargetHitCount(params.maxTargetHitCount)
    projectile.filterFunc = targetFilter
    projectile.penetrate = (params.penetrate == nil and true or params.penetrate)
    projectile.delayTime = params.delayTime or 0

    projectile.hitCallback = function(projectile, actor, index)
        local callback = "onHit"
        if not Utils:IsNullOrEmpty(params.hitCallback) then
            callback = params.hitCallback
        end
        skill:ClearHitTargets()
        skill:AddHitTarget(actor, index)
        skill:ServerFireAllSkillEvents(callback)
    end
    
    projectile.enterCallback = function(projectile, actor)
        local callback = "onEnter"
        if not Utils:IsNullOrEmpty(params.enterCallback) then
            callback = params.enterCallback
        end
        skill:ClearHitTargets()
        skill:AddHitTarget(actor)
        skill:ServerFireAllSkillEvents(callback)
    end

    projectile.leaveCallback = function(projectile, actor)
        local callback = "onLeave"
        if not Utils:IsNullOrEmpty(params.leaveCallback) then
            callback = params.leaveCallback
        end
        skill:ClearHitTargets()
        skill:AddHitTarget(actor)
        skill:ServerFireAllSkillEvents(callback)
    end

    if params.groundCast then
        local groundPos = skill.actor:GetGroundPosition(startPosition)
        startPosition = Vec3.New(groundPos.x, groundPos.y, groundPos.z)
    end
    
    projectile:Start(startPosition, 
        Vec3.zero(), params.duration)
    return projectile
end

--陷阱
--params.offset 偏移，释放这个吸附区域的偏移位置，跟其他事件一样
function ExternalSkillEventHandler:Trap(skill, params)
    if not self:CheckCondition(skill, target, params.condition) then
        return
    end
    
    local offset = Vec3.New(params.offset[1],params.offset[2],params.offset[3])
    local startPosition = skill.actor.AvatarComponent:GetOffsetPosition(offset)
    self:_CreateTrap(startPosition, skill, params)
end

--替换陷阱
--params.replaceId 替换的陷阱id
function ExternalSkillEventHandler:ReplaceTrap(skill, params)
    if not self:CheckCondition(skill, target, params.condition) then
        return
    end

    local replaceId = params.replaceId

    local needRemoves = {}
    skill:ForEachTargets(function(target)
        if target:GetTag() == ActorDefines.ProjectileTag and target.projectileId == replaceId then
            self:_CreateTrap(target:GetPosition(), skill, params)
            table.insert(needRemoves, target)
            target:Dead()
        end
        return true
    end)
    --从skill.targets中移除
    for _,v in ipairs(needRemoves) do
        skill:RemoveHitTarget(v)
    end
end
--命中陷阱
function ExternalSkillEventHandler:HitTrap(skill, params)
    local hitId = params.hitId
    --先做一个简单的选择，包含自己
    local targetFilter = function(target)
        return target.projectileId == hitId
    end
    local offset = Vec3.New(params.offset[1],params.offset[2],params.offset[3])
    local hitPos = skill.actor.AvatarComponent:GetOffsetPosition(offset)
    skill.actor:EnableOverlap(true)
    local hitTargets = {}
    if params.shape == "Cylinder" then
        hitTargets = TargetUtils:SelectCylinderTargets(skill.actor:IsServer(), hitPos,
        params.radius,params.height,targetFilter,ActorDefines.ProjectileTag)
    elseif params.shape == "Fan" then
        hitTargets = TargetUtils:SelectFanTargets(skill.actor:IsServer(), hitPos,
        skill.actor.AvatarComponent:GetForward(),
        params.radius,params.height,params.angle,targetFilter,ActorDefines.ProjectileTag)
    elseif params.shape == "Line" then
        hitTargets = TargetUtils:SelectLineTargets(skill.actor:IsServer(), hitPos,
        skill.actor.AvatarComponent:GetForward(), params.distance,
        params.width,params.height,targetFilter,ActorDefines.ProjectileTag)
    end
    skill.actor:EnableOverlap(false)
    skill:ClearHitTargets()
    skill:AddHitTargets(hitTargets)
    --设置碰撞源位置
    skill:ForEachHitTargets(function(target, index)
        target.hitSourcePos = hitPos
    end)
    if skill:GetHitTargetCount() > 0 then
        local callback = "onHit"
        if not Utils:IsNullOrEmpty(params.hitCallback) then
            callback = params.hitCallback
        end
        skill:ServerFireAllSkillEvents(callback)
    end
end


return ExternalSkillEventHandler