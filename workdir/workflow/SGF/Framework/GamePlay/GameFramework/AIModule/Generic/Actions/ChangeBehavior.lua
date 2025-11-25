local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "ChangeBehavior",
    type = "Action",
    Run = function(node, runtime, args)
        local behavior = runtime:GetBB(node, args.behaviorBBKey, args.behavior)
        local behaviorBBKey = "RT_Behavior"
        local value = runtime:SetBB(node, behaviorBBKey, behavior)
        return EResult.SUCCESS
    end
}



return M
