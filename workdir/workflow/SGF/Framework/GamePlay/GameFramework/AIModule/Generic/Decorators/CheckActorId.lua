local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'CheckActorId',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local actorId = runtime:GetBB(node, args.actorIdBBKey,args.actorId)
        if not actorId then
            return EResult.FAIL
        end
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            if targetActor:GetActorId() == actorId then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
