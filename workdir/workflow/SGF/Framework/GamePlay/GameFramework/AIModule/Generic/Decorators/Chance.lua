local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Chance',
    type = 'Decorator',
    Run = function(node, runtime, args, firstRun)
        local chance = runtime:GetBB(node, args.chanceBBKey,args.chance)
        if not chance then
            return EResult.FAIL
        end
        local chanceValue = runtime:GetInnerVar(node, "CHANCE")
        if chanceValue == nil or firstRun then
            chanceValue = Math:Random(0,100)
            runtime:SetInnerVar(node, "CHANCE", chanceValue)
        end
        local inChance = chanceValue < chance
        if inChance then
            return EResult.SUCCESS
        end
        return EResult.FAIL
    end
}

return M
