local Log = GFScript("CoreModule.Log")
local Math = GFScript("CoreModule.Math")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

--behavior类型: Hit Stand RandomMove Patrol Follow Attack Approach Homing

--获取行为
local function GetBehavior(node, runtime, args)
    return runtime:GetBB(node, args.behaviorBBKey)
end
--设置行为
local function SetBehavior(node, runtime, args, behavior)
    runtime:SetBB(node, args.behaviorBBKey, behavior)
end
--设置默认行为
local function SetDefaultBehavior(node, runtime, args)
    local behavior = runtime:GetBB(node, args.defaultBehaviorBBKey)
    runtime:SetBB(node, args.behaviorBBKey, behavior)
end

local M = {
    name = 'WalkerService',
    type = 'Service',
    Run = function(node, runtime, args)
        runtime:SetBB(node, args.selfBBKey, runtime.owner)
        runtime:SetBB(node, args.masterBBKey, runtime.owner:GetMaster())
        local behavior = GetBehavior(node, runtime, args)
        --更新黑板值
        local pathName = runtime.owner.walkPath
        local path = nil
        local scene = runtime.owner:GetScene()
        if scene then
            local pedestrianSystem = scene:GetPedestrianSystem()
            if pedestrianSystem then
                path = pedestrianSystem:GetWalkPath(pathName)
            end
        end
        runtime:SetBB(node, args.walkPathBBKey, path)
        --设置出生点
        runtime:SetBBVector(node, args.bornBBKey, runtime.owner:GetBornPosition())

        return EResult.SUCCESS
    end,
}

return M
