local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindFanLocation",
    type = "EQS",
    Run = function(node, runtime, args)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        local radius = runtime:GetBB(node, args.radiusBBKey,args.radius)
        local randomAngle = runtime:GetBB(node, args.randomAngleBBKey,args.randomAngle)
        local angleOffset = runtime:GetBB(node, args.angleOffsetBBKey,args.angleOffset)
        local angle = Math:Random(-randomAngle,randomAngle) + angleOffset
        local orient = Quat.New()
        orient:FromEuler(Vec3.New(0,angle,0))
        local randomPos = targetActor:GetPosition() + orient * targetActor:GetForward() * radius
        runtime:SetBB(node, args.targetLocationBBKey,randomPos:ToTable())
        return EResult.SUCCESS
    end
}



return M
