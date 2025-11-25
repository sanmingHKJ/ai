local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "StopMove",
    type = "Action",
    Run = function(node, runtime, args)
        runtime.owner:StopMove()
        return EResult.SUCCESS
    end
}



return M
