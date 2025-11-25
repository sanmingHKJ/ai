local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Check",
    type = "Condition",
    Run = function(node, runtime, args)
        local value = runtime:GetBB(node, args.BBKey)

        return value and EResult.SUCCESS or EResult.FAIL
    end
}

return M
