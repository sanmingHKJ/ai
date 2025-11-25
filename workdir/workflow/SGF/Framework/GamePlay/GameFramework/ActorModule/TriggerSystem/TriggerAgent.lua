local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local TriggerAgent = Class.New("TriggerAgent", ActorComponent)

--初始化
function TriggerAgent:Constructor()
    --进入的触发器栈
    self.enterTriggerStack = {}
    self.updateEnabled = true
    self.enterTriggers = {}
end

--获取最后一个进入的触发器
function TriggerAgent:GetLastEnterTrigger()
    if #self.enterTriggerStack > 0 then
        return self.enterTriggerStack[#self.enterTriggerStack]
    end
    return nil
end

--添加进入触发器
function TriggerAgent:AddEnterTrigger(trigger)
    local lastEnterTrigger = self:GetLastEnterTrigger()
    if lastEnterTrigger and lastEnterTrigger.priority > trigger.priority then
        return
    end
    table.insert(self.enterTriggerStack, trigger)
end

--添加离开触发器
function TriggerAgent:RemoveEnterTrigger(trigger)
    for i, enterTrigger in ipairs(self.enterTriggerStack) do
        if enterTrigger == trigger then
            table.remove(self.enterTriggerStack, i)
            break
        end
    end
end

function TriggerAgent:OnEnterTrigger(trigger)
    local lastEnterTrigger = self:GetLastEnterTrigger()
    self:AddEnterTrigger(trigger)
    local newLastEnterTrigger = self:GetLastEnterTrigger()
    if newLastEnterTrigger ~= lastEnterTrigger then
        if lastEnterTrigger then
            self:OnLeave(lastEnterTrigger)
        end
        if newLastEnterTrigger then
            self:OnEnter(newLastEnterTrigger)
        end
    end
end

function TriggerAgent:OnLeaveTrigger(trigger)
    local lastEnterTrigger = self:GetLastEnterTrigger()
    self:RemoveEnterTrigger(trigger)
    local newLastEnterTrigger = self:GetLastEnterTrigger()
    if newLastEnterTrigger ~= lastEnterTrigger then
        if lastEnterTrigger then
            self:OnLeave(lastEnterTrigger)
        end
        if newLastEnterTrigger then
            self:OnEnter(newLastEnterTrigger)
        end
    end
end

--真正进入一个触发器
function TriggerAgent:OnEnter(trigger)
    if self:IsServer() then
        self.actor:FireServer("EnterTrigger", trigger)
    else
        self.actor:FireClient("EnterTrigger", trigger) 
    end
end

--真正离开一个触发器
function TriggerAgent:OnLeave(trigger)
    if self:IsServer() then
        self.actor:FireServer("LeaveTrigger", trigger)
    else
        self.actor:FireClient("LeaveTrigger", trigger) 
    end
end

function TriggerAgent:Update(dt)
    local scene = self.actor:GetScene()
    if scene then
        local triggerSystem = scene:GetTriggerSystem()
        if triggerSystem then  
            triggerSystem:ForEachTriggers(function(trigger)
                if self.enterTriggers[trigger] == nil and trigger:IsInTrigger(self.actor:GetPosition()) then
                    trigger:OnEnter(self)
                    self.enterTriggers[trigger] = true
                end
            end)

            -- for trigger, _ in pairs(self.enterTriggers) do
            --     if trigger:IsOutTrigger(self.actor:GetPosition()) then
            --         trigger:OnLeave(self)
            --         self.enterTriggers[trigger] = nil
            --     end
            -- end
        end
    end
end

return TriggerAgent
