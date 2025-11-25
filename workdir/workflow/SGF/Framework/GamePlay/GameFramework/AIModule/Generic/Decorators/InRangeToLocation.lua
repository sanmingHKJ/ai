local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'InRangeToLocation',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local range = runtime:GetBB(node, args.rangeBBKey,args.range)
        if not range then
            return EResult.FAIL
        end
        local targetLocation = runtime:GetBB(node, args.targetLocationBBKey, args.targetLocation)
        if targetLocation then
            local curPos = runtime.owner:GetPosition()
            local distance = curPos:Distance(targetLocation)
            local inRange = distance >= range[1] and distance <= range[2]

            if inRange then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
