local Class = GFScript("CoreModule.Class")
local StatNetProto = GFScript("StatModule.StatNetProto")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local Log = GFScript("CoreModule.Log")

local StaminaComponent = Class.New("StaminaComponent",EnergyComponent)

-- 构造函数
function StaminaComponent:Awake()
    StaminaComponent.super.Awake(self)
    self.valueStatName = "Stamina"
    self.maxValueStatName = "MaxStamina"
    self.regenStatName = "StaminaRegen"
end

--获取能量名字
function StaminaComponent:GetEnergyName()
    return "Stamina"
end
--启动服务端
function StaminaComponent:OnStartServer()
    StaminaComponent.super.OnStartServer(self)
end
--启动客户端
function StaminaComponent:OnStartClient()
end

-- 使用怒气值
function StaminaComponent:UseStamina(amount)
    -- 检查怒气值是否足够
    if self:GetValue() >= amount then
        self:SubValue(amount)
        return true -- 使用成功
    else
        return false -- 使用失败，怒气值不足
    end
end
--当前值改变事件
function StaminaComponent:OnValueChange(oldValue, newValue)
    if self.actor:IsServer() then
        self.actor:FireServer("StaminaChanged", oldValue, newValue)
    else
        --触发事件
        self.actor:FireClient("StaminaChanged", oldValue, newValue)
    end
    StaminaComponent.super.OnValueChange(self, oldValue, newValue)
end
--设置当前值
function StaminaComponent:SetValue(value)
    --Log:Debug("SetStamina value="..value.." max="..self:GetMaxValue())
    StaminaComponent.super.SetValue(self, value)
end

--设置Actor
function StaminaComponent:OnActorSet(actor)
    StaminaComponent.super.OnActorSet(self, actor)
end



function StaminaComponent:InitServer()
    StaminaComponent.super.InitServer(self)
    local anger = self.actor.StatComponent:GetValue("Stamina")
    self.lastValue = anger
    self.actor:OnServerEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Stamina" then
            local newStamina = self.actor.StatComponent:GetValue("Stamina")
            if newStamina ~= self.lastValue then
                self:OnValueChange(self.lastValue, newStamina)
                self.lastValue = newStamina
            end
        end
    end)
end

function StaminaComponent:InitClient()
    StaminaComponent.super.InitClient(self)
    local anger = self.actor.StatComponent:GetValue("Stamina")
    self.lastValue = anger
    self.actor:OnClientEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Stamina" then
            local newStamina = self.actor.StatComponent:GetValue("Stamina")
            if newStamina ~= self.lastValue then
                self:OnValueChange(self.lastValue, newStamina)
                self.lastValue = newStamina
            end
        end
    end)
end
-----------------------------------------------------------------------

--序列化
function StaminaComponent:Serialize(data, purpose)
    data.version = self.version
    StaminaComponent.super.Serialize(self, data, purpose)
end

--反序列化
function StaminaComponent:Deserialize(data)
    self.version = data.version
    StaminaComponent.super.Deserialize(self, data)
end

return StaminaComponent
