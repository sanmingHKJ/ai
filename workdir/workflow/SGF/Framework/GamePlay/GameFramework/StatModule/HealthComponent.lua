local Class = GFScript("CoreModule.Class")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local Log = GFScript("CoreModule.Log")

-- 创建Health类并继承Energy类
local HealthComponent = Class.New("HealthComponent",EnergyComponent)

HealthComponent.version = 1

-- 构造函数
function HealthComponent:Awake()
    HealthComponent.super.Awake(self)
    self.multiLives = false
    self.valueStatName = "Health"
    self.maxValueStatName = "MaxHealth"
    self.regenStatName = "HealthRegen"
end
--获取能量名字
function HealthComponent:GetEnergyName()
    return "Health"
end

--启动服务端
function HealthComponent:OnStartServer()
    HealthComponent.super.OnStartServer(self)
end
--启动客户端
function HealthComponent:OnStartClient()
end

--增加值
function HealthComponent:AddValue(amount)
    local diffValue = self:GetMaxValue() - self:GetValue()
    HealthComponent.super.AddValue(self, amount)

    if diffValue >= amount then
        return amount
    end
    return math.max(0, diffValue)
end

-- 检查生命值是否为0
function HealthComponent:IsDead()
    return self:GetValue() <= 0
end
--当前值改变事件
function HealthComponent:OnValueChange(oldValue, newValue)
    if self.actor:IsServer() then
        self.actor:FireServer("HealthChanged", oldValue, newValue)
    else
        --触发事件
        self.actor:FireClient("HealthChanged", oldValue, newValue)
    end
    HealthComponent.super.OnValueChange(self, oldValue, newValue)
    
    if newValue <= 0 then
        self:OnZero()
    end
end

-- 濒死状态
function HealthComponent:IsNearDeath()
    return self:IsDead() and self.multiLives
end

-- 是否多条命
function HealthComponent:SetMultiLives(value)
    self.multiLives = value
end

--同步属性到character
function HealthComponent:SyncToCharacter()
    local character = self.actor:GetCharacter()
    if character then
        character.MaxHealth = self:GetMaxValue()
        character.Health = self:GetValue()
    end
end

--空值后
function HealthComponent:OnZero()
    self.actor:NotifyDead()
end

--复活
function HealthComponent:Revive()
    self:SetValue(self:GetMaxValue())
end
--设置Actor
function HealthComponent:OnActorSet(actor)
    HealthComponent.super.OnActorSet(self, actor)
end


function HealthComponent:InitServer()
    HealthComponent.super.InitServer(self)
    local health = self.actor.StatComponent:GetValue("Health")
    self.lastValue = health
    self.actor:OnServerEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Health" then
            self:SyncToCharacter()
            local newHealth = self.actor.StatComponent:GetValue("Health")
            if newHealth ~= self.lastValue then
                self:OnValueChange(self.lastValue, newHealth)
                self.lastValue = newHealth
            end
        end
    end)
end

function HealthComponent:InitClient()
    HealthComponent.super.InitClient(self)
    local health = self.actor.StatComponent:GetValue("Health")
    self.lastValue = health
    self.actor:OnClientEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Health" then
            local newHealth = self.actor.StatComponent:GetValue("Health")
            if newHealth ~= self.lastValue then
                self:OnValueChange(self.lastValue, newHealth)
                self.lastValue = newHealth
            end
        end
    end)
end
-----------------------------------------------------------------------

--序列化
function HealthComponent:Serialize(data, purpose)
    data.version = self.version
    HealthComponent.super.Serialize(self, data, purpose)
end

--反序列化
function HealthComponent:Deserialize(data)
    self.version = data.version
    HealthComponent.super.Deserialize(self, data)
end

-- 返回Health类
return HealthComponent
