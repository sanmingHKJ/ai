local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'IsCasting',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local skillTid = runtime:GetBB(node, args.skillTidBBKey,args.skillTid)
        if not skillTid then
            return EResult.FAIL
        end
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            local currentSkillTid = targetActor.SkillComponent:GetCurrentSkillTid()
            if currentSkillTid == skillTid then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
