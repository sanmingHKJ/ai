local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Trigger = GFScript("ActorModule.TriggerSystem.Trigger")

local TriggerSystem = Class.New("TriggerSystem")

function TriggerSystem:Constructor()
    self.triggers = {}
end

function TriggerSystem:OnDestructor()
    self:DestroyAllTriggers()
end

--初始化
function TriggerSystem:Init(scene, isServer)
    self.scene = scene
    self.isServer = isServer
end

--当进入触发器
function TriggerSystem:OnEnterTrigger(trigger, triggerAgent)
    triggerAgent:OnEnterTrigger(trigger)
end

--当离开触发器
function TriggerSystem:OnLeaveTrigger(trigger, triggerAgent)
    triggerAgent:OnLeaveTrigger(trigger)
end


--添加路径
function TriggerSystem:AddTrigger(name, node)
    local trigger = Trigger.New(name, self, self.isServer)
    trigger:Init(node)
    table.insert(self.triggers, trigger)
    return trigger
end

--初始化路径
function TriggerSystem:InitTriggers(rootNodes)
    self:DestroyAllTriggers()
    if rootNodes then
        for _, node in ipairs(rootNodes.Children) do
            local name = node.Name
            self:AddTrigger(name, node, isServer)
        end
    end
end

--销毁所有路径
function TriggerSystem:DestroyAllTriggers()
    for _, trigger in ipairs(self.triggers) do
        trigger:Destroy()
    end
    self.triggers = {}
end

--遍历所有触发器
function TriggerSystem:ForEachTriggers(func)
    for _, trigger in ipairs(self.triggers) do
        func(trigger)
    end
end

return TriggerSystem