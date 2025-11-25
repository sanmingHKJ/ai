local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Attack",
    type = "Action",
    Run = function(node, runtime, args)
        local attacking = node:Resume(runtime)
        if attacking == 1 then
            if runtime.owner:GetCurrentState() == ActorDefines.EActorState.Casting then
                return EResult.RUNNING
            end
            return EResult.SUCCESS
        end
        --释放技能
        local skillIndex = runtime:GetBB(node, args.skillIndexBBKey,args.skillIndex)
        runtime.owner.SkillComponent:ServerUseSkillBar(skillIndex)
        return node:Yield(runtime, 1)
    end
}



return M
