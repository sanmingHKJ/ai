local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindNextWaypoint",
    type = "EQS",
    Run = function(node, runtime, args)
        local waypointInfo = runtime:GetInnerVar(node, "WAYPOINT")
        if waypointInfo == nil then
            waypointInfo = {
                pointIndex = -1,--巡逻点索引
                dir = 1,--正向寻找
            }
        end
        local walkpath = runtime:GetBB(node, args.walkPathBBKey)
        if not walkpath then
            return EResult.FAIL
        end
        local nextWaypoint = nil
        if waypointInfo.pointIndex == -1 then
            nextWaypoint = walkpath:FindNearestWaypoint(runtime.owner:GetPosition())
            if nextWaypoint == nil then
                return EResult.FAIL
            end
        else
            nextWaypoint = walkpath:GetNextWaypoint(waypointInfo.pointIndex, runtime.owner.walkDir == -1)
            if nextWaypoint == nil then
                return EResult.FAIL
            end
        end
        
        waypointInfo.pointIndex = nextWaypoint.index
        local targetLocation = nextWaypoint:GetRandomPosition()

        targetLocation = runtime.owner:GetGroundPosition(targetLocation)
        
        runtime:SetBB(node, args.targetWaypointBBKey,nextWaypoint)  
        runtime:SetBB(node, args.targetLocationBBKey,targetLocation:ToTable())

        runtime:SetInnerVar(node, "WAYPOINT", waypointInfo)
        return EResult.SUCCESS
    end
}



return M
