local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local function ret(r)
    return r and EResult.SUCCESS or EResult.FAIL
end

local M = {
    name = 'IsBehavior',
    type = 'Condition',
    Run = function(node, runtime, args)
        local behaviorBBKey = "RT_Behavior"
        local value = runtime:GetBB(node, behaviorBBKey)
        return ret(value == args.behavior)
    end
}

return M
