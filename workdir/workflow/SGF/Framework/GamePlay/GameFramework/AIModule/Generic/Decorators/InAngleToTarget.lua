local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'InAngleToTarget',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local angle = runtime:GetBB(node, args.angleBBKey,args.angle)
        local targetActor = runtime:GetBB(node, args.targetBBKey)
        if targetActor then
            local checkValue = runtime:GetStepVar(node, "INANGLE")
            if checkValue ~= nil then
                if checkValue then
                    return EResult.SUCCESS
                else
                    return EResult.FAIL
                end
            end
            local dir = targetActor:GetPosition() - runtime.owner:GetPosition()
            dir:Normalize()
            local a = runtime.owner:GetForward():AngleBetween(dir)
            local check = a <= angle
            
            runtime:SetStepVar(node, "INANGLE", check)
            if check then
                return EResult.SUCCESS
            end
        end
        return EResult.FAIL
    end
}

return M
