local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local Utils = GFScript("CoreModule.Utils")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Cooldown',
    type = 'Decorator',
    Run = function(node, runtime, args)
        if runtime:GetStepVar(node, "COOLDOWN") ~= nil then
            return EResult.SUCCESS
        end
        local timeEnd = runtime:GetInnerVar(node, "COOLDOWN")
        if timeEnd then
            if timeEnd <= Utils:GetServerTime() then
                -- local cooldown = runtime:GetBB(node, args.cooldownBBKey, args.cooldown)
                -- runtime:SetInnerVar(node, "COOLDOWN", Utils:GetServerTime() + cooldown)
                -- runtime:SetStepVar(node, "COOLDOWN", true)
                return EResult.SUCCESS
            else
                return EResult.FAIL
            end
        end
        -- local cooldown = runtime:GetBB(node, args.cooldownBBKey, args.cooldown)
        -- if not cooldown then
        --     return EResult.FAIL
        -- end
        -- runtime:SetInnerVar(node, "COOLDOWN", Utils:GetServerTime() + cooldown)
        -- runtime:SetStepVar(node, "COOLDOWN", true)
        return EResult.SUCCESS
    end
}

return M
