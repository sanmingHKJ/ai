local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'HasStatValue',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            local hasStat = targetActor.StatComponent:HasValue(args.stat)

            if hasStat then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
