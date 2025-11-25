local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "KillSelf",
    type = "Action",
    Run = function(node, runtime, args)
        runtime.owner:Kill()
        return EResult.SUCCESS
    end
}



return M
