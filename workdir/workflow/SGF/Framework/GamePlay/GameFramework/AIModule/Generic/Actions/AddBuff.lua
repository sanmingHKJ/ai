local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "AddBuff",
    type = "Action",
    Run = function(node, runtime, args)
        local buffId = runtime:GetBB(node, args.buffBBKey,args.buff)
        local target = runtime:GetBB(node, args.targetBBKey,args.target)
        if target then
            target.BuffComponent:ServerAddBuffByTid(runtime.owner, buffId)
        else
            runtime.owner.BuffComponent:ServerAddBuffByTid(runtime.owner, buffId)
        end
        return EResult.SUCCESS
    end
}



return M
