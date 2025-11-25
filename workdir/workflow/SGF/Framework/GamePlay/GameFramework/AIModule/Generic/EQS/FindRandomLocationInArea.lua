local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindRandomLocationInArea",
    type = "EQS",
    Run = function(node, runtime, args)
        local orgin = runtime:GetBB(node, args.orginBBKey,args.orgin)
        local pos = Vec3.New(orgin[1],orgin[2],orgin[3])
        local area = runtime:GetBB(node, args.areaBBKey,args.area)
        local startX, startY, endX, endY = area[1], area[2], area[3], area[4]
        local randomX = Math:Random(startX, endX)
        local randomY = Math:Random(startY, endY)
        runtime:SetBB(node, args.targetLocationBBKey,{randomX, pos.y, randomY})
        return EResult.SUCCESS
    end
}



return M
