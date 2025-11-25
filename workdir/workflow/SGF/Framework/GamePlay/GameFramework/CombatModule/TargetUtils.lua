local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorManager = GFScript("ActorModule.ActorManager")
local Profiler = GFScript("CoreModule.Profiler")
local Utils = GFScript("CoreModule.Utils")
local WorldService = game:GetService("WorldService")
local Players = game:GetService("Players")

local TargetUtils = {}
TargetUtils.profilerEnabled = false

--选择box内的目标
function TargetUtils:OverlapBox(isServer, center, extent, angle, filterFunc, tag)
    tag = Utils:IsNullOrEmpty(tag) and ActorDefines.ActorTag or tag
    if TargetUtils.profilerEnabled then
        Profiler:Start("OverlapBox: ",0.001)
    end
    local diveDown = 100
    local results = WorldService:OverlapBox(Vector3.New(extent.x,extent.y,extent.z),
                                            Vector3.New(center.x,center.y - diveDown,center.z),
                                            Vector3.New(angle.x,angle.y,angle.z),false,ActorDefines.AllCollideActorGroups)

    if TargetUtils.profilerEnabled then
        Profiler:Stop()
    end
    if TargetUtils.profilerEnabled then
        Profiler:Start("Overlap Filter: ",0.001)
    end
    local retActors = {}
    for _,v in ipairs(results) do
        local obj = v.obj
        if obj.Tag == ActorDefines.SummonTag then
            obj = obj.Parent
        end

        if obj ~= nil and obj.Tag == tag then
            if obj.Tag == ActorDefines.ActorTag then
                local actor = nil
                if isServer then
                    actor = ActorManager:GetServerActor(obj)
                else
                    actor = ActorManager:GetClientActor(obj)
                end
                if actor and actor:CanHit() and filterFunc(actor) then
                    table.insert(retActors, actor)
                end
            end
        end
    end
    if TargetUtils.profilerEnabled then
        Profiler:Stop()
    end
    return retActors
end

--将结果按近到远排序
function TargetUtils:SortByNear(actors, orginPos)
    table.sort(actors, function(a,b)
        local disA = a:GetPosition():Distance(orginPos)
        local disB = b:GetPosition():Distance(orginPos)
        return disA < disB
    end)
end

--选择圆柱内的目标
function TargetUtils:SelectCylinderTargets(isServer, center, radius, height, filterFunc, tag)
    tag = tag or ActorDefines.ActorTag
    if radius == 0 or height == 0 then
        return {}
    end
    local cylinderFilter = function(actor)
        --判断是否在半径内，忽略y坐标
        local centerPos = center:Clone()
        local targetPos = actor:GetPosition()
        local characterRadius = actor:GetRadius()
        centerPos.y = 0
        targetPos.y = 0
        if centerPos:Distance(targetPos) > radius + characterRadius then
            return false
        end
        if filterFunc then
            return filterFunc(actor)
        end 
        return true
    end
    local halfHeight = height / 2
    local results = self:OverlapBox(isServer, Vec3.New(center.x,center.y + halfHeight,center.z),
                                    Vec3.New(radius,halfHeight,radius),Vec3.New(0,0,0),cylinderFilter,tag)
    return results
end

--选择扇形内目标
function TargetUtils:SelectFanTargets(isServer, center, direction, radius, height, angle, filterFunc, tag)
    tag = tag or ActorDefines.ActorTag
    if radius == 0 or height == 0 then
        return {}
    end
    local fanFilter = function(actor)
        --判断是否在扇形内
        local targetPos = actor:GetPosition()
        local dir = targetPos - center
        dir:Normalize()
        if direction:AngleBetween(dir) > angle / 2 then
            return false
        end
        if filterFunc then
            return filterFunc(actor)
        end 
        return true
    end
    local results = self:SelectCylinderTargets(isServer, center, radius, height, fanFilter, tag)
    return results
end

--选择一条线上的目标
function TargetUtils:SelectLineTargets(isServer, startPos, dir, distance, width, height, filterFunc, tag)
    tag = tag or ActorDefines.ActorTag
    if width == 0 then
        return {}
    end
    local startPoint = startPos-- - dir * width / 2
    local endPoint = startPos + dir * distance --(distance + width / 2)
    -- endOffset.y  = height
    local halfOffset = Vec3.New(0,0,distance / 2)
    local lineFilter = function(actor)
        local actorPos = actor:GetPosition()
        local characterRadius = actor:GetRadius()
        actorPos.y = startPoint.y
        local lineDis = actorPos:DistanceToLine(startPoint, endPoint)
        if lineDis > width / 2 + characterRadius then
            return false
        end
        if filterFunc then
            return filterFunc(actor)
        end 
        return true
    end
    local lookDir = dir:Clone()
    lookDir.y = 0
    local orient = Quat.New()
    orient:FromLookRotation(lookDir, Vec3.New(0,1,0))
    local euler = orient:ToEuler()
    local orgin = startPos + orient * halfOffset
    local radius = (distance + width) / 2

    
    local results = self:OverlapBox(isServer, orgin,
                                    Vec3.New(radius,height/2,radius),
                                    Vec3.New(0,0,0),lineFilter,tag)
    return results
end


--射线检测目标
function TargetUtils:RaycastTarget(isServer, startPos, endPos)
    local dir = endPos - startPos
    local length = dir:Length()
    dir:Normalize()
    local ret = game:GetService("WorldService"):RaycastClosest(Vector3.New(startPos.x,startPos.y,startPos.z), 
    Vector3.New(dir.x,dir.y,dir.z), length, false, {ActorDefines.CollideGroup.Player})
    -- 如果击中
    if ret.isHit then
        local obj = ret.obj
        if obj then
            if obj.Tag == ActorDefines.ActorTag then
                local actor = nil
                if isServer then
                    actor = ActorManager:GetServerActor(obj)
                else
                    actor = ActorManager:GetClientActor(obj)
                end
                return actor, ret.Position
            end
        end
    end
end


--判断目标是否在圆柱体内
function TargetUtils:CylinderHitTest(targetPos, center, radius, height, tolerance)
    tolerance = tolerance or 0 -- 默认偏差为0
    local centerPos = center:Clone()
    centerPos.y = 0
    targetPos.y = 0
    if centerPos:Distance(targetPos) > radius + tolerance then
        return false
    end
    local halfHeight = height / 2
    if math.abs(targetPos.y - center.y) > halfHeight + tolerance then
        return false
    end
    return true
end

--判断目标是否在扇形内
function TargetUtils:FanHitTest(targetPos, center, direction, radius, height, angle, tolerance)
    tolerance = tolerance or 0 -- 默认偏差为0
    
    -- 先检查是否在圆柱体内
    if not self:CylinderHitTest(targetPos, center, radius, height, tolerance) then
        return false
    end
    
    -- 再检查是否在扇形角度内
    local dir = targetPos - center
    dir.y = 0 -- 忽略y轴差异
    dir:Normalize()
    
    local angleBetween = direction:AngleBetween(dir)
    if angleBetween > (angle / 2) + tolerance then
        return false
    end
    
    return true
end

--判断目标是否在线段内
function TargetUtils:LineHitTest(targetPos, startPos, dir, distance, width, height, tolerance)
    tolerance = tolerance or 0 -- 默认偏差为0
    
    -- 检查高度
    local halfHeight = height / 2
    if math.abs(targetPos.y - startPos.y) > halfHeight + tolerance then
        return false
    end
    
    -- 创建线段端点
    local endPos = startPos + dir * distance
    
    -- 计算点到线段的距离
    local flatTargetPos = targetPos:Clone()
    local flatStartPos = startPos:Clone()
    flatTargetPos.y = 0
    flatStartPos.y = 0
    local flatEndPos = endPos:Clone()
    flatEndPos.y = 0
    
    local lineDist = flatTargetPos:DistanceToLine(flatStartPos, flatEndPos)
    if lineDist > (width / 2) + tolerance then
        return false
    end
    
    -- 检查是否在线段长度范围内
    local lineDir = flatEndPos - flatStartPos
    local targetDir = flatTargetPos - flatStartPos
    local dotProduct = lineDir:Dot(targetDir)
    
    if dotProduct < 0 - tolerance then
        return false -- 在起点之前
    end
    
    if dotProduct > lineDir:Dot(lineDir) + tolerance then
        return false -- 在终点之后
    end
    
    return true
end


return TargetUtils