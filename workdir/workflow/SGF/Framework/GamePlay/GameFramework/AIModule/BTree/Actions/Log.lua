local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Log",
    type = "Action",
    Run = function(node, runtime, args)
        local msg = args.logContent or args
        Log:Debug(tostring(msg))
        return EResult.SUCCESS
    end
}



return M
