local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindNextPatrolLocation",
    type = "EQS",
    Run = function(node, runtime, args)
        local patrolInfo = runtime:GetInnerVar(node, "PATROL")
        if patrolInfo == nil then
            patrolInfo = {
                pointIndex = 1,--巡逻点索引
                dir = 1,--正向寻找
            }
        end
        local points = runtime:GetBB(node, args.pointsBBKey,args.points)
        if #points <= 1 then
            return EResult.FAIL
        end
        local nextIndex = 0
        if patrolInfo.dir == 1 then
            nextIndex = patrolInfo.pointIndex + 1
        else
            nextIndex = patrolInfo.pointIndex - 1
        end
        if nextIndex > #points then
            patrolInfo.dir = -1
            nextIndex = patrolInfo.pointIndex - 1
        elseif nextIndex < 1 then
            patrolInfo.dir = 1
            nextIndex = patrolInfo.pointIndex + 1
        end
        patrolInfo.pointIndex = nextIndex

        runtime:SetBB(node, args.targetLocationBBKey,points[nextIndex])

        runtime:SetInnerVar(node, "PATROL", patrolInfo)
        return EResult.SUCCESS
    end
}



return M
