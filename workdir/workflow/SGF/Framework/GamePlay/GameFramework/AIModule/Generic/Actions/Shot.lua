local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "Shot",
    type = "Action",
    Run = function(node, runtime, args)
        local EquipmentComponent = runtime.owner.EquipmentComponent
        if not EquipmentComponent then
            return EResult.FAIL
        end
        local t = node:Resume(runtime)
        if t then
            if runtime.ctx.time >= t then
                EquipmentComponent:StopAttack()
                return EResult.SUCCESS
            else
                return EResult.RUNNING
            end
        end
        local duration = runtime:GetBB(node, args.durationBBKey, args.duration)
        --开枪
        EquipmentComponent:StartAttack()
        return node:Yield(runtime, runtime.ctx.time + duration)
    end,
    
    Abort = function(node, runtime, args)
        local EquipmentComponent = runtime.owner.EquipmentComponent
        if EquipmentComponent then
            EquipmentComponent:StopAttack()
        end
    end
}



return M
