local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "PlayMontage",
    type = "Action",
    Run = function(node, runtime, args)
        local t = node:Resume(runtime)
        if t then
            if runtime.ctx.time >= t then
                return EResult.SUCCESS
            else
                return EResult.RUNNING
            end
        end
        --播放动画
        local anim = runtime:GetBB(node, args.animBBKey,args.anim)
        if type(anim) == "table" then
            anim = anim[math.random(1, #anim)]
        end
        runtime.owner.AvatarComponent:PlayAnim(anim)

        local time = runtime:GetBB(node, args.durationBBKey, args.duration)
        local waitTime = 0
        if type(time) == "table" then
            waitTime = Math:Random(time[1], time[2])
        elseif type(time) == "number" then
            waitTime = time
        else
            Log:Error("Wait", "time is not number or table")
            return EResult.FAILURE
        end
        return node:Yield(runtime, runtime.ctx.time + waitTime)
    end,
    
    Abort = function(node, runtime, args)
        
    end
}



return M
