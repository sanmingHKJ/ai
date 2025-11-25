local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Once",
    type = "Decorator",
    Run = function(node, runtime, args)
        if runtime:GetStepVar(node, "ONCE") ~= nil then
            return EResult.SUCCESS
        end
        if runtime:GetInnerVar(node, "ONCE") ~= nil then
            return EResult.FAIL
        end
        runtime:SetInnerVar(node, "ONCE", true)
        runtime:SetStepVar(node, "ONCE", true)
        return EResult.SUCCESS
    end
}

return M
