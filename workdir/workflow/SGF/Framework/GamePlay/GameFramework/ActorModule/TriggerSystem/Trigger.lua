local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorDefines = GFScript("ActorModule.ActorDefines")

local Trigger = Class.New("Trigger")

--初始化
function Trigger:Constructor(name, sys, isServer)
    self.name = name
    --系统
    self.triggerSystem = sys
    self.isServer = isServer
    --优先级
    self.priority = 0
    --触发器类型
    self.triggerType = nil
    --触发器数据
    self.triggerData = nil

    --进入触发器
    self.enterTrigger = nil
    --离开触发器
    self.leaveTrigger = nil

    --离开触发器距离
    self.leaveTriggerDistance = 1000

    self.position = Vec3.New()
    self.radius = 0
end

function Trigger:OnDestructor()
    self:UninitEvents()
    if self.leaveTrigger then
        self.leaveTrigger:Destroy()
        self.leaveTrigger = nil
    end
end

--获取名称
function Trigger:GetName()  
    return self.name
end

function Trigger:Init(trigger)
    self.enterTrigger = trigger
    self.priority = trigger:GetAttribute("Priority") or 0
    self.triggerType = trigger:GetAttribute("TriggerType") or "Trigger"
    self.triggerData = trigger:GetAttribute("TriggerData") or nil

    -- --创建离开触发器
    -- self.leaveTrigger = SandboxNode.New("TriggerBox")
    -- self.leaveTrigger.Position = self.enterTrigger.Position
    -- self.leaveTrigger.Rotation = self.enterTrigger.Rotation
    -- self.leaveTrigger.LocalScale = self.enterTrigger.LocalScale
    -- self.leaveTrigger.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    -- self.leaveTrigger.Size = Vector3.New(self.enterTrigger.Size.X + self.leaveTriggerDistance * 2 / self.enterTrigger.LocalScale.X, 
    --     self.enterTrigger.Size.Y + self.leaveTriggerDistance * 2 / self.enterTrigger.LocalScale.Y, 
    --     self.enterTrigger.Size.Z + self.leaveTriggerDistance * 2 / self.enterTrigger.LocalScale.Z)
    
    -- self.leaveTrigger.Parent = self.enterTrigger.Parent

    self.position = Vec3.New(self.enterTrigger.Position.X, self.enterTrigger.Position.Y, self.enterTrigger.Position.Z)
    self.radius = math.min(self.enterTrigger.Size.X, self.enterTrigger.Size.Z) / 2

    self:InitEvents()
end

--是否在触发器内
function Trigger:IsInTrigger(position)
    local pos = position:Clone()
    pos.Y = self.position.Y
    local dis = pos:Distance(self.position)
    return dis <= self.radius
end

--是否离开触发器
function Trigger:IsOutTrigger(position)
    local pos = position:Clone()
    pos.Y = self.position.Y
    local dis = pos:Distance(self.position)
    return dis > self.radius + self.leaveTriggerDistance
end

function Trigger:InitEvents()
    -- self:UninitEvents()

    -- local function GetTriggerAgent(obj)
    --     if obj ~= nil and obj.Tag == ActorDefines.ActorTag then
    --         local actor = nil
    --         local ActorManager = GFScript("ActorModule.ActorManager")
    --         if self.isServer then
    --             actor = ActorManager:GetServerActor(obj)
    --         else
    --             actor = ActorManager:GetClientActor(obj)
    --         end
    --         if actor then
    --             local triggerAgent = actor:GetComponent("TriggerAgent")
    --             if triggerAgent then
    --                 return triggerAgent
    --             end
    --         end
    --     end
    -- end

    -- self.enterTouchedEventId = self.enterTrigger.Touched:Connect(function(other)
    --     local triggerAgent = GetTriggerAgent(other)
    --     if triggerAgent then
    --         self:OnEnter(triggerAgent)
    --     end
    -- end)
    -- self.enterTouchEndedEventId = self.leaveTrigger.TouchEnded:Connect(function(other)

    -- end)

    -- self.leaveTouchedEventId = self.leaveTrigger.Touched:Connect(function(other)

    -- end)
    -- self.leaveTouchEndedEventId = self.leaveTrigger.TouchEnded:Connect(function(other)
    --     local triggerAgent = GetTriggerAgent(other)
    --     if triggerAgent then
    --         self:OnLeave(triggerAgent)
    --     end
    -- end)
end

function Trigger:UninitEvents()
    -- if self.enterTouchedEventId and self.enterTrigger then
    --     self.enterTrigger.Touched:Disconnect(self.enterTouchedEventId)
    --     self.enterTouchedEventId = nil
    -- end
    -- if self.enterTouchEndedEventId and self.enterTrigger then
    --     self.leaveTrigger.TouchEnded:Disconnect(self.enterTouchEndedEventId)
    --     self.enterTouchEndedEventId = nil
    -- end
    -- if self.leaveTouchedEventId and self.leaveTrigger then
    --     self.leaveTrigger.Touched:Disconnect(self.leaveTouchedEventId)
    --     self.leaveTouchedEventId = nil
    -- end
    -- if self.leaveTouchEndedEventId and self.leaveTrigger then
    --     self.leaveTrigger.TouchEnded:Disconnect(self.leaveTouchEndedEventId)
    --     self.leaveTouchEndedEventId = nil
    -- end
end

--设置触发器数据
function Trigger:SetTriggerData(data)
    self.triggerData = data
end

function Trigger:GetTriggerData()
    return self.triggerData
end

function Trigger:GetTriggerSystem()
    return self.triggerSystem
end

function Trigger:GetTriggerType()
    return self.triggerType
end

function Trigger:GetPriority()
    return self.priority
end

function Trigger:GetLeaveTriggerDistance()
    return self.leaveTriggerDistance
end

--当进入触发器
function Trigger:OnEnter(triggerAgent)
    self.triggerSystem:OnEnterTrigger(self, triggerAgent)
end

--当离开触发器
function Trigger:OnLeave(triggerAgent)
    self.triggerSystem:OnLeaveTrigger(self, triggerAgent) 
end

return Trigger