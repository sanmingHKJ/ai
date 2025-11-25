local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local Utils = GFScript("CoreModule.Utils")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

--behavior类型: Hit Stand RandomMove Patrol Follow Attack Approach Homing

--获取行为
local function GetBehavior(node, runtime, args)
    return runtime:GetBB(node, args.behaviorBBKey)
end
--设置行为
local function SetBehavior(node, runtime, args, behavior)
    local curBehavior = runtime:GetBB(node, args.behaviorBBKey)
    --保存上一个状态
    runtime:SetBB(node, args.prevBehaviorBBKey, curBehavior)
    --保存当前状态
    runtime:SetBB(node, args.behaviorBBKey, behavior)
end
--设置默认行为
local function SetDefaultBehavior(node, runtime, args)
    local behavior = runtime:GetBB(node, args.defaultBehaviorBBKey)
    SetBehavior(node, runtime, args, behavior)
end
--设置死亡行为
local function SetDeadBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Dead")
end
--设置受击行为
local function SetHitBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Hit")
end
--设置战斗行为
local function SetAttackBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Attack")
end
--设置追击行为
local function SetApproachBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Approach")
end
--设置归位行为
local function SetHomingBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Homing")
end

--设置等待状态
local function SetWaitBehavior(node, runtime, args)
    SetBehavior(node, runtime, args, "Wait")
end
local M = {
    name = 'WarriorService',
    type = 'Service',
    Run = function(node, runtime, args)

        local behavior = GetBehavior(node, runtime, args)
        
        if behavior == "Homing" then
            return
        end

        --更新黑板值
        local target = runtime.owner:GetTarget()
        --验证目标合法性
        if target and (not target:GetScene() or target:GetSceneId() ~= runtime.owner:GetSceneId() or target:IsShadow()) then
            target = nil
        end

        local lastTarget = runtime:GetBB(node, args.lastTargetBBKey)

        local enterCombatLocation = runtime.owner:GetEnterCombatLocation()
        runtime:SetBB(node, args.selfBBKey, runtime.owner)
        runtime:SetBB(node, args.masterBBKey, runtime.owner:GetMaster())
        runtime:SetBB(node, args.targetBBKey, target)
        runtime:SetBBVector(node, args.enterCombatLocationBBKey, enterCombatLocation)
        --设置出生点
        runtime:SetBBVector(node, args.bornBBKey, runtime.owner:GetBornPosition())

        if target ~= lastTarget then
            runtime:SetBB(node, args.lastTargetBBKey, target)
        end

        --判断是否死亡
        if runtime.owner:IsDead() then
            SetDeadBehavior(node, runtime, args)
            return
        end

        --行为判断
        if not target then
            local timeEnd = runtime:GetInnerVar(node, "WAIT_BEHAVIOR")
            if timeEnd then
                if Utils:GetServerTime() >= timeEnd then
                    -- SetDefaultBehavior(node, runtime, args)
                    SetHomingBehavior(node, runtime, args)
                    runtime:SetInnerVar(node, "WAIT_BEHAVIOR", nil)
                end
            else
                local waitDuration = runtime:GetBB(node, args.waitDurationBBKey, args.waitDuration)
                if lastTarget and waitDuration and waitDuration > 0 then
                    local waitTimeEnd = Utils:GetServerTime() + waitDuration
                    runtime:SetInnerVar(node, "WAIT_BEHAVIOR", waitTimeEnd)
                    SetWaitBehavior(node, runtime, args)
                else
                    SetDefaultBehavior(node, runtime, args)
                end
            end
            return
        else
            runtime:SetInnerVar(node, "WAIT_BEHAVIOR", nil)
        end
        if target:IsDead() then
            SetHomingBehavior(node, runtime, args)
            runtime.owner:ServerLostTarget("Dead")
            if runtime.owner.HateComponent then
                runtime.owner.HateComponent:ServerClearHate()
            end
            return
        end
        
        --判断是否限制行动
        -- if behavior ~= "Attack" and (runtime.owner:IsDisallowAction() or runtime.owner:IsDisallowMove()) then
        local disallowAction = runtime.owner:IsDisallowAction()
        local disallowMove = runtime.owner:IsDisallowMove()
        if disallowAction or disallowMove then
            SetHitBehavior(node, runtime, args)
            return
        end

        
        local enterCombatLocation = runtime:GetBBVector(node, args.enterCombatLocationBBKey)
        local combatRadius = runtime:GetBB(node, args.combatRadiusBBKey, args.combatRadius)
        local attackRadius = runtime:GetBB(node, args.attackRadiusBBKey, args.attackRadius)
        local enterCombatDistance = enterCombatLocation:Distance(target:GetPosition())

        if enterCombatDistance >= combatRadius then
            SetHomingBehavior(node, runtime, args)
            runtime.owner:ServerLostTarget("TooFar")
            if runtime.owner.HateComponent then
                runtime.owner.HateComponent:ServerClearHate()
            end
            return
        end

        local distance = runtime.owner:Distance(target)
        if not args.disableApproach and distance > attackRadius then
            SetApproachBehavior(node, runtime, args)
            return
        end
        if not args.disableAttack then
            SetAttackBehavior(node, runtime, args)
            return
        end

        SetDefaultBehavior(node, runtime, args)

        return EResult.SUCCESS
    end,
}

return M
