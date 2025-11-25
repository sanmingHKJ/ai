local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'InRangeHealth',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local minHealth = 0
        local maxHealth = 0

        if args.rangeBBKey or args.range then
            local range = runtime:GetBB(node, args.rangeBBKey,args.range)
            if range then
                minHealth = range[1]
                maxHealth = range[2]
            end
        else
            minHealth = runtime:GetBB(node, args.minHealthBBKey,args.minHealth)
            maxHealth = runtime:GetBB(node, args.maxHealthBBKey,args.maxHealth)
        end
        
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if not targetActor then
            targetActor = runtime.owner
        end
        if targetActor then
            local percent = targetActor.HealthComponent:GetPercent() * 100
            if percent >= minHealth and percent <= maxHealth then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
