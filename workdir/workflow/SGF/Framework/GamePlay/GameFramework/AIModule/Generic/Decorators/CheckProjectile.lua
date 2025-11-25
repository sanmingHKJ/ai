local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'CheckProjectile',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local state = runtime:GetBB(node, args.stateBBKey,args.state)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            if targetActor:GetCurrentState() == state then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
