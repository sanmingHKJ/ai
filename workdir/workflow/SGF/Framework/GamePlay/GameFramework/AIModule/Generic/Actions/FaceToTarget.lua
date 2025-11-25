local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local RotateTo = GFScript("ActorModule.Action.RotateTo")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FaceToTarget",
    type = "Action",
    Run = function(node, runtime, args)
        local target = runtime:GetBB(node, args.targetBBKey)
        if target then
            runtime.owner:LookAt(target)

            return EResult.SUCCESS
        end
        return EResult.FAIL
    end,
    
    Abort = function(node, runtime, args)
    end
}



return M
