local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "ComboAttack",
    type = "Action",
    Run = function(node, runtime, args)
        local target = runtime:GetBB(node, args.targetBBKey,args.target)
        local skills = runtime:GetBB(node, args.skillsBBKey,args.skills)
        local faceToTarget = args.faceToTarget
        local attackIndex = node:Resume(runtime)
        if attackIndex and attackIndex > 0 then
            if runtime.owner:GetCurrentState() == ActorDefines.EActorState.Casting then
                return EResult.RUNNING
            end
            local comboChance = runtime:GetBB(node, args.comboChanceBBKey,args.comboChance)
            if attackIndex < #skills and Math:Random(0,100) < comboChance then
                attackIndex = attackIndex + 1
                if faceToTarget and target then
                    runtime.owner:LookAt(target)
                end
                runtime.owner.SkillComponent:ServerUseSkillBar(skills[attackIndex])
                return node:Yield(runtime, attackIndex)
            end
            return EResult.SUCCESS
        end
        --释放技能
        local index = 1
        if faceToTarget and target then
            runtime.owner:LookAt(target)
        end
        runtime.owner.SkillComponent:ServerUseSkillBar(skills[index])
        return node:Yield(runtime, index)
    end
}



return M
