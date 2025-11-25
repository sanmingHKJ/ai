local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindRandomLocation",
    type = "EQS",
    Run = function(node, runtime, args)
        local orgin = runtime:GetBB(node, args.orginBBKey,args.orgin)
        local pos = Vec3.New(orgin[1],orgin[2],orgin[3])
        local radius = runtime:GetBB(node, args.radiusBBKey,args.radius)
        local randomPos = Math:RandomPointInRadius(pos, radius)
        runtime:SetBB(node, args.targetLocationBBKey,randomPos:ToTable())
        return EResult.SUCCESS
    end
}



return M
