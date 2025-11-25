local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local function ret(r)
    return r and EResult.SUCCESS or EResult.FAIL
end

local M = {
    name = 'IsSet',
    type = 'Condition',
    Run = function(node, runtime, args)
        local value = runtime:GetBB(node, args.valueBBKey)
        return ret(value ~= nil and value ~= "")
    end
}

return M
