local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'CanAttack',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        local skills = runtime:GetBB(node, args.skillsBBKey,args.skills)
        if targetActor then
            local canAttack = false
            for _, skillIndex in ipairs(skills) do
                if targetActor.SkillComponent:CanUseSkillBar(skillIndex) then
                    canAttack = true
                    break
                end
            end
            if canAttack then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
