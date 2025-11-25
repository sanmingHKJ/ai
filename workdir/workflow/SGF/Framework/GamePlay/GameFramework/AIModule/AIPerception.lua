local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local TargetUtils = GFScript("CombatModule.TargetUtils")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local AIPerception = Class.New("AIPerception", ActorComponent)

--实例化
function AIPerception:Constructor()
    --感应半径
    self.radius = 1000
    --检测高度
    self.height = 500
    --主动式感知
    self.activePerception = false
    --已感知目标列表
    self.perceptionTargets = {}
    --更新频率
    self.fixedUpdateInterval = 0.2
end

--是否主动式感应
function AIPerception:IsActivePerception()
    return self.activePerception
end

--设置主动式感应
function AIPerception:SetActivePerception(active)
    self.activePerception = active
end

--设置感知半径
function AIPerception:SetRadius(radius)
    self.radius = radius
end

function AIPerception:GetRadius()
    return self.radius
end

--设置检测高度
function AIPerception:SetHeight(height)
    self.height = height
end

function AIPerception:GetHeight()
    return self.height
end

--更新
function AIPerception:FixedUpdateServer(dt)
    AIPerception.super.FixedUpdateServer(self, dt)
    
    if self.actor:IsServer() and self.activePerception then
        self:UpdateActivePerception()
    end
end

--更新主动感知
function AIPerception:UpdateActivePerception()
    if self.actor:IsDead() then
        return
    end

    local filterFunc = function(target)
        if target == self.actor then
            return false
        end
        if target:IsDead() or target:IsStealth() then
            return false
        end
        return true
    end

    self.actor:EnableOverlap(true)
    local targets = TargetUtils:SelectCylinderTargets(self.actor:IsServer(), self.actor:GetPosition(), self.radius, self.height, filterFunc)
    self.actor:EnableOverlap(false)

    --检查离开感知的目标
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
            self:OnServerLostPerception(target)
            table.remove(self.perceptionTargets, idx)
        end
    end

    --检查新感知的目标
    for _, target in ipairs(targets) do
        local found = false
        for _, target2 in ipairs(self.perceptionTargets) do
            if target2 == target then
                found = true
                break
            end
        end
        if not found then
            local distance = self.actor:Distance(target) / self.radius
            self:OnServerPerception(target, distance)
            table.insert(self.perceptionTargets, target)
        end
    end
end

--设置Actor
function AIPerception:OnActorSet(actor)
    AIPerception.super.OnActorSet(self, actor)
end

function AIPerception:InitServer()
    AIPerception.super.InitServer(self)
    self.actor:OnServerEvent("Dead", function()
        self.perceptionTargets = {}
    end)
end

--目标是否在半径内
function AIPerception:IsInRadius(target)
    local distance = self.actor:GetPosition():Distance(target:GetPosition())
    if distance > self.radius then
        return false
    end
    return true
end

--感知到目标
function AIPerception:OnServerPerception(target, distance)
    --如果目标是敌对，憎恨目标
    if self.actor.CombatComponent:IsEnemy(target) then
        self.actor.HateComponent:ServerAddHate(target, 1000 - distance * 500)
    end
end

--脱离感知
function AIPerception:OnServerLostPerception(target)
end

return AIPerception