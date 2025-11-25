local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local RotateTo = GFScript("ActorModule.Action.RotateTo")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "RotateToTarget",
    type = "Action",
    Run = function(node, runtime, args)
        local target = runtime:GetBB(node, args.targetBBKey)
        local turnLeft = runtime:GetBB(node, args.turnLeftBBKey,args.turnLeft)
        local turnRight = runtime:GetBB(node, args.turnRightBBKey,args.turnRight)
        if target then
            local rotating = node:Resume(runtime)
            if rotating and rotating > 0 then
                if runtime.owner.rotating then
                    return EResult.RUNNING
                else
                    if rotating == 1 then
                        --停止左转动画
                        runtime.owner.AvatarComponent:StopAnim(turnLeft)
                    elseif rotating == 2 then
                        --停止右转动画
                        runtime.owner.AvatarComponent:StopAnim(turnRight)
                    end
                    return EResult.SUCCESS
                end
            else
                local targetPos = target:GetPosition()
                runtime.owner:RotateTo(targetPos)

                local rotateDir = 0
                if runtime.owner.AvatarComponent:IsAtLeft(targetPos) then
                    --左转
                    rotateDir = 1
                    runtime.owner.AvatarComponent:PlayAnim(turnLeft)
                elseif runtime.owner.AvatarComponent:IsAtRight(targetPos) then
                    --右转
                    rotateDir = 2
                    runtime.owner.AvatarComponent:PlayAnim(turnRight)
                end

                return node:Yield(runtime, rotateDir)
            end
        end
        return EResult.FAIL
    end,
    
    Abort = function(node, runtime, args)
        local turnLeft = runtime:GetBB(node, args.turnLeftBBKey,args.turnLeft)
        local turnRight = runtime:GetBB(node, args.turnRightBBKey,args.turnRight)
        runtime.owner.AvatarComponent:StopAnim(turnLeft)
        runtime.owner.AvatarComponent:StopAnim(turnRight)
        runtime.owner:StopRotate()
    end
}



return M
