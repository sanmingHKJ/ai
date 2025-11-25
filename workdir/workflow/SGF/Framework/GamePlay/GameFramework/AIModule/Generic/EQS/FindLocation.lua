local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindLocation",
    type = "EQS",
    Run = function(node, runtime, args)
        local locationType
        local locationPos
        local locationRadius

        if args.locationBBKey then
            local location = runtime:GetBB(node, args.locationBBKey,args.location)
            locationType = location[1]
            locationPos = location[2]
            locationRadius = location[3]
        else
            locationType = runtime:GetBB(node, args.findLocationTypeBBKey,args.findLocationType)
            locationPos = runtime:GetBB(node, args.locationPosBBKey,args.locationPos)
            locationRadius = runtime:GetBB(node, args.locationRadiusBBKey,args.locationRadius)
        end

        if locationType == "Random" then
            --随机位置
            local pos = Vec3.New(locationPos[1],locationPos[2],locationPos[3])
            local randomPos = Math:RandomPointInRadius(pos, locationRadius)
            runtime:SetBB(node, args.targetLocationBBKey,randomPos:ToTable())
        elseif locationType == "RandomOfTarget" then
            --以目标为中心随机位置
            locationRadius = locationPos
            local pos = runtime.owner.target and runtime.owner.target:GetPosition() or runtime.owner:GetPosition()
            local randomPos = Math:RandomPointInRadius(pos, locationRadius)
            runtime:SetBB(node, args.targetLocationBBKey,randomPos:ToTable())
        elseif locationType == "Local" then
            --本地位置
            local pos = Vec3.New(locationPos[1],locationPos[2],locationPos[3])
            local localPos = runtime.owner:GetOffsetPosition(pos)
            runtime:SetBB(node, args.targetLocationBBKey,localPos:ToTable())
        elseif locationType == "World" then
            --世界位置
            runtime:SetBB(node, args.targetLocationBBKey,locationPos)
        else
            Log:Error("FindLocation Unknown locationType:"..locationType)
            return EResult.FAIL
        end

        return EResult.SUCCESS
    end
}



return M
