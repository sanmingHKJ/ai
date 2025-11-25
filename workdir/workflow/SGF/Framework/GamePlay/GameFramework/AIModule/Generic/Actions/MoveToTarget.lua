local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "MoveToTarget",
    type = "Action",
    Run = function(node, runtime, args)
        local timeout = 0
        local moveTimeOut = node:Resume(runtime)
        if moveTimeOut ~= nil then
            if runtime.ctx.time >= moveTimeOut then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            end

            local curPos = runtime.owner:GetPosition()
            if runtime.owner.__moveToTargetStartPos then
                local maxDistance = runtime:GetBB(node, args.maxDistanceBBKey,args.maxDistance)
                if maxDistance and maxDistance > 0 then
                    runtime.owner.__moveToTargetDistance = runtime.owner.__moveToTargetDistance + runtime.owner.__moveToTargetLastPos:Distance(curPos)
                    runtime.owner.__moveToTargetLastPos = curPos

                    if runtime.owner.__moveToTargetDistance > maxDistance then
                        runtime.owner:StopMove()
                        return EResult.SUCCESS
                    end
                end
            end
            local err = runtime:GetBB(node, args.errBBKey,args.err)
            local target = runtime:GetBB(node, args.targetBBKey)
            if target == nil or Class.IsExpired(target) then
                return EResult.FAILURE
            end
            local targetLocation = target:GetPosition()
            targetLocation = target:GetGroundPosition(targetLocation)
            local dis = curPos:Distance(targetLocation)
            if dis < err then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            else
                runtime.owner:MoveTo(targetLocation)
                --2倍速度作为超时计算
                timeout = dis / runtime.owner.AvatarComponent:GetFinalMoveSpeed() * 2
                node:Yield(runtime, runtime.ctx.time + timeout)
            end
            return EResult.RUNNING
        else
            local err = runtime:GetBB(node, args.errBBKey,args.err)
            local target = runtime:GetBB(node, args.targetBBKey)
            if target == nil or Class.IsExpired(target) then
                return EResult.FAILURE
            end
            local targetLocation = target:GetPosition()
            targetLocation = target:GetGroundPosition(targetLocation)
            --移动到目标点才算成功
            local curPos = runtime.owner:GetPosition()
            local dis = curPos:Distance(targetLocation)
            if dis < err then
                return EResult.SUCCESS
            else
                runtime.owner.__moveToTargetStartPos = curPos
                runtime.owner.__moveToTargetLastPos = curPos
                runtime.owner.__moveToTargetDistance = 0
                runtime.owner:MoveTo(targetLocation)
                --2倍速度作为超时计算
                timeout = dis / runtime.owner.AvatarComponent:GetFinalMoveSpeed() * 2
            end
        end
        return node:Yield(runtime, runtime.ctx.time + timeout)
    end,
    
    Abort = function(node, runtime, args)
        runtime.owner:StopMove()
    end
}



return M
