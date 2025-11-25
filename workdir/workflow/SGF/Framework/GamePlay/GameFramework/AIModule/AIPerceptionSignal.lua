local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local TargetUtils = GFScript("CombatModule.TargetUtils")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local AIPerceptionSignal = Class.New("AIPerceptionSignal", ActorComponent)

--实例化
function AIPerceptionSignal:Constructor()
    self.fixedUpdateInterval = 0.2
    --检查半径
    self.radius = 5000
    --检测高度
    self.height = 500

    --已经感知的目标
    self.perceptionTargets = {}
end

--设置感知半径
function AIPerceptionSignal:SetRadius(radius)
    self.radius = radius
end

function AIPerceptionSignal:GetRadius()
    return self.radius
end

function AIPerceptionSignal:SetHeight(height)
    self.height = height
end

function AIPerceptionSignal:GetHeight()
    return self.height
end

--丢失全部感知对象
function AIPerceptionSignal:ClearPerceptionTargets()
    for _, target in ipairs(self.perceptionTargets) do
        if target.AIPerception then
            target.AIPerception:OnServerLostPerception(self.actor)
        end
    end
    self.perceptionTargets = {}
end

--更新服务端
function AIPerceptionSignal:FixedUpdateServer(dt)
    AIPerceptionSignal.super.FixedUpdateServer(self, dt)

    if self.actor:IsDead() or self.actor:IsStealth() then
        self:ClearPerceptionTargets()
        return
    end

    local filterFunc = function(target)
        if target == self.actor then
            return false
        end
        if not target.AIPerception then
            return false
        end
        if target:IsDead() or target:IsStealth() then
            return false
        end
        if not target.AIPerception:IsInRadius(self.actor) and not target.AIPerception:IsActivePerception() then
            return false
        end
        return true
    end
    self.actor:EnableOverlap(true)
    local targets = TargetUtils:SelectCylinderTargets(self.actor:IsServer(), self.actor:GetPosition(), self.radius, self.height, filterFunc)
    self.actor:EnableOverlap(false)
    --判断离开感知的目标
    for idx = #self.perceptionTargets, 1, -1 do
        local target = self.perceptionTargets[idx]
        local found = false
        for _, target2 in ipairs(targets) do
            if target2 == target then
                found = true
                break
            end
        end
        if not found then
            --离开感知
            if not Class.IsExpired(target.AIPerception) then
                target.AIPerception:OnServerLostPerception(self.actor)
            end
            table.remove(self.perceptionTargets, idx)
        end
    end
    --判断感知的目标
    for _, target in ipairs(targets) do
        local found = false
        for _, target2 in ipairs(self.perceptionTargets) do
            if target2 == target then
                found = true
                break
            end
        end
        if not found then
            --感知
            local distance = self.actor:Distance(target) / self.radius
            if not Class.IsExpired(target.AIPerception) then
                target.AIPerception:OnServerPerception(self.actor, distance)
            end
            table.insert(self.perceptionTargets, target)
        end
    end
end


--设置Actor
function AIPerceptionSignal:OnActorSet(actor)
    AIPerceptionSignal.super.OnActorSet(self, actor)
end

function AIPerceptionSignal:InitServer()
    AIPerceptionSignal.super.InitServer(self)
    self.actor:OnServerEvent("Dead", function()
        self.perceptionTargets = {}
    end)
end


return AIPerceptionSignal