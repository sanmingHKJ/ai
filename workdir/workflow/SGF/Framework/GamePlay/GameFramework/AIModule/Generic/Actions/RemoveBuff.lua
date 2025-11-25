local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "RemoveBuff",
    type = "Action",
    Run = function(node, runtime, args)
        local buffId = runtime:GetBB(node, args.buffBBKey,args.buff)
        local target = runtime:GetBB(node, args.targetBBKey,args.target)
        if target then
            target.BuffComponent:ServerRemoveBuffByTid(buffId, 1)
        else
            runtime.owner.BuffComponent:ServerRemoveBuffByTid(buffId, 1)
        end
        return EResult.SUCCESS
    end
}



return M
