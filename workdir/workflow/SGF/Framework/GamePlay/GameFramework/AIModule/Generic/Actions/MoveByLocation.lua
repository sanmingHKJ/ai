local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "MoveByLocation",
    type = "Action",
    Run = function(node, runtime, args)
        local timeout = 0
        local moveTimeOut = node:Resume(runtime)
        if moveTimeOut ~= nil then
            if runtime.ctx.time >= moveTimeOut then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            end
            local err = runtime:GetBB(node, args.errBBKey,args.err)
            local pos = runtime:GetStepVar(node, "TargetLocation")
            pos = runtime.owner:GetGroundPosition(pos)
            local curPos = runtime.owner:GetPosition()
            local dis = curPos:Distance(pos)
            if dis < err then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            end
            return EResult.RUNNING
        else
            local err = runtime:GetBB(node, args.errBBKey,args.err)
            local targetLocation = runtime:GetBB(node, args.targetLocationBBKey,args.targetLocation)
            local pos = Vec3.New(targetLocation[1],targetLocation[2],targetLocation[3])
            pos = runtime.owner:GetOffsetPosition(pos)
            pos = runtime.owner:GetGroundPosition(pos)
            --移动到目标点才算成功
            local curPos = runtime.owner:GetPosition()
            local dis = curPos:Distance(pos)
            if dis < err then
                return EResult.SUCCESS
            else
                runtime.owner:MoveTo(pos)
                --2倍速度作为超时计算
                timeout = dis / runtime.owner.AvatarComponent:GetFinalMoveSpeed() * 2

                runtime:SetStepVar(node,"TargetLocation", pos)
            end
        end
        return node:Yield(runtime, runtime.ctx.time + timeout)
    end,
    
    Abort = function(node, runtime, args)
        runtime.owner:StopMove()
    end
}



return M
