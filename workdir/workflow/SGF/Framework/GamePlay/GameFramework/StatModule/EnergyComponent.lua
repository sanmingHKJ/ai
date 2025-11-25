local Class = GFScript("CoreModule.Class")
local TimerManager = GFScript("CoreModule.TimerManager")
local Utils = GFScript("CoreModule.Utils")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local EnergyComponent = Class.New("EnergyComponent", ActorComponent)

function EnergyComponent:Constructor()
    self.fixedUpdateInterval = 1
end
function EnergyComponent:Awake()
    self.valueStatName =  "" --当前
    self.maxValueStatName = "" --最大
    self.regenStatName = "" --恢复
    self.nextRegenTimeEnd = 0
end
--销毁
function EnergyComponent:OnDestroy()

end
--获取能量名字
function EnergyComponent:GetEnergyName()
    return "Energy"
end
--设置所属节点
function EnergyComponent:SetActor(actor)
    EnergyComponent.super.SetActor(self, actor)
    if actor then
        if actor.energyComps == nil then
            actor.energyComps = {}
        end
        actor.energyComps[self:GetEnergyName()] = self
    end
end
--启动服务端
function EnergyComponent:OnStartServer()
    self:RegenDelay(1)
end
--启动客户端
function EnergyComponent:OnStartClient()
end

--更新服务端
function EnergyComponent:FixedUpdateServer(dt)
    if self.nextRegenTimeEnd <= Utils:GetServerTime() then
        local regen = self.actor.StatComponent:GetValue(self.regenStatName)
        if regen > 0 then
            local amount = regen * dt
            self:OnRegen(amount)
        end
        self:RegenDelay(1)
    end
end
--延迟恢复
function EnergyComponent:RegenDelay(delayTime)
    self.nextRegenTimeEnd = Utils:GetServerTime() + delayTime
end
--获取百分比
function EnergyComponent:GetPercent()
    return self:GetValue() / self:GetMaxValue()
end

--设置百分比
function EnergyComponent:SetPercent(percent)
    self:SetValue(self:GetMaxValue() * percent)
end

--增加百分比
function EnergyComponent:AddPercent(percent)
    self:SetPercent(self:GetPercent() + percent) 
end

--获取当前值
function EnergyComponent:GetValue()
    local v = self.actor.StatComponent:GetValue(self.valueStatName)
    return v or 0
end
--设置当前值
function EnergyComponent:SetValue(value)
    if self:IsServer() then
        local maxValue = self:GetMaxValue()
        if value > maxValue then
            value = maxValue
        elseif value < 0 then
            value = 0
        end
        self.actor.StatComponent:SetSimpleValue(self.valueStatName, value)
    end
end

--获取最大值
function EnergyComponent:GetMaxValue()
    local v = self.actor.StatComponent:GetValue(self.maxValueStatName)
    return v or 0
end

--是否为0
function EnergyComponent:IsZero()
    return self:GetValue() <= 0
end

--是否满值
function EnergyComponent:IsFull()
    return self:GetValue() >= self:GetMaxValue()
end

function EnergyComponent:SetFull()
    self:SetValue(self:GetMaxValue())
end

--当前值为0时触发
function EnergyComponent:OnZero()

end

--当前值改变事件
function EnergyComponent:OnValueChange(oldValue, newValue)
    
end

--当恢复时
function EnergyComponent:OnRegen(amount)
    self:AddValue(amount)
end

--增加值
function EnergyComponent:AddValue(amount)
    self:SetValue(self:GetValue() + amount)
end
--减少值
function EnergyComponent:SubValue(amount,checkEnough)
    if amount > self:GetValue() then
        if checkEnough then
            return false
        else
            amount = self:GetValue()
        end
    end
    self:SetValue(self:GetValue() - amount)
    return true
end

return EnergyComponent
