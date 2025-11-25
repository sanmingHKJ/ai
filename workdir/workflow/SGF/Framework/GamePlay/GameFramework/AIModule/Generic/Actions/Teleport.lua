local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Teleport",
    type = "Action",
    Run = function(node, runtime, args)
        local location = args.location or args.targetLocation
        local locationBBKey = args.locationBBKey or args.targetLocationBBKey

        local targetLocation = runtime:GetBB(node, locationBBKey,location)
        local pos = Vec3.New(targetLocation[1],targetLocation[2],targetLocation[3])
        pos = runtime.owner:GetValidPosition(pos)
        runtime.owner:TeleportTo(pos)
        return EResult.SUCCESS
    end,
    
    Abort = function(node, runtime, args)
    end
}



return M
