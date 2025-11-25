local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "MoveToLocation",
    type = "Action",
    Run = function(node, runtime, args)
        local timeout = 0

        local location = args.location or args.targetLocation
        local locationBBKey = args.locationBBKey or args.targetLocationBBKey
        local locationErr = args.locationErr or args.err
        local locationErrBBKey = args.locationErrBBKey or args.errBBKey

        local moveTimeOut = node:Resume(runtime)
        if moveTimeOut ~= nil then
            if runtime.ctx.time >= moveTimeOut then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            end
            local err = runtime:GetBB(node, locationErrBBKey,locationErr)
            local targetLocation = runtime:GetBB(node, locationBBKey,location)
            local pos = Vec3.New(targetLocation[1],targetLocation[2],targetLocation[3])
            local curPos = runtime.owner:GetPosition()
            local dis = curPos:Distance(pos)
            if dis < err then
                runtime.owner:StopMove()
                return EResult.SUCCESS
            end
            return EResult.RUNNING
        else
            local err = runtime:GetBB(node, locationErrBBKey,locationErr)
            local targetLocation = runtime:GetBB(node, locationBBKey,location)
            local pos = Vec3.New(targetLocation[1],targetLocation[2],targetLocation[3])
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
            end
        end
        return node:Yield(runtime, runtime.ctx.time + timeout)
    end,
    
    Abort = function(node, runtime, args)
        runtime.owner:StopMove()
    end
}



return M
