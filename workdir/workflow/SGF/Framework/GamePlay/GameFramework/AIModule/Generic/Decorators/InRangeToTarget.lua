local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local Class = GFScript("CoreModule.Class")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'InRangeToTarget',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local range = runtime:GetBB(node, args.rangeBBKey,args.range)
        if not range then
            return EResult.FAIL
        end
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor == nil or Class.IsExpired(targetActor) then
            return EResult.FAIL
        end
        if targetActor then
            local distance = runtime.owner:Distance(targetActor, true)
            local inRange = distance >= range[1] and distance <= range[2]

            if inRange then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
