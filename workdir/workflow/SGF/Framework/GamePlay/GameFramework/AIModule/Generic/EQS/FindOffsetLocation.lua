local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "FindOffsetLocation",
    type = "EQS",
    Run = function(node, runtime, args)
        local offset = runtime:GetBB(node, args.offsetBBKey,args.offset)
        if not offset then
            return EResult.FAIL
        end
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            local offsetPos = targetActor:GetOffsetPosition(Vec3.New(offset[1],offset[2],offset[3]))
            local validPos = targetActor:GetValidPosition(offsetPos)
            runtime:SetBB(node, args.targetLocationBBKey,validPos:ToTable())
            return EResult.SUCCESS
        end
        return EResult.FAIL
    end
}



return M
