local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'HasBuff',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local buffId = runtime:GetBB(node, args.buffBBKey,args.buff)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            local hasBuff = targetActor.BuffComponent:HasBuff(buffId)
            if hasBuff then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
