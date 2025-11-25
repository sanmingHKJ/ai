local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "SetMovementState",
    type = "Action",
    Run = function(node, runtime, args)
        local state = runtime:GetBB(node, args.stateBBKey,args.state)
        runtime.owner:ChangeState(state)
        return EResult.SUCCESS
    end
}



return M
