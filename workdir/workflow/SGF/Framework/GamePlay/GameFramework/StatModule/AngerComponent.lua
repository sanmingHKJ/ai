local Class = GFScript("CoreModule.Class")
local StatNetProto = GFScript("StatModule.StatNetProto")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local Log = GFScript("CoreModule.Log")

local AngerComponent = Class.New("AngerComponent",EnergyComponent)

-- 构造函数
function AngerComponent:Awake()
    AngerComponent.super.Awake(self)
    self.valueStatName = "Anger"
    self.maxValueStatName = "MaxAnger"
    self.regenStatName = "AngerRegen"
end

--获取能量名字
function AngerComponent:GetEnergyName()
    return "Anger"
end
--启动服务端
function AngerComponent:OnStartServer()
    AngerComponent.super.OnStartServer(self)
end
--启动客户端
function AngerComponent:OnStartClient()
end

-- 使用怒气值
function AngerComponent:UseAnger(amount)
    -- 检查怒气值是否足够
    if self:GetValue() >= amount then
        self:SubValue(amount)
        return true -- 使用成功
    else
        return false -- 使用失败，怒气值不足
    end
end
--当前值改变事件
function AngerComponent:OnValueChange(oldValue, newValue)
    if self.actor:IsServer() then
        self.actor:FireServer("AngerChanged", oldValue, newValue)
    else
        --触发事件
        self.actor:FireClient("AngerChanged", oldValue, newValue)
    end
    AngerComponent.super.OnValueChange(self, oldValue, newValue)
end
--设置当前值
function AngerComponent:SetValue(value)
    --Log:Debug("SetAnger value="..value.." max="..self:GetMaxValue())
    AngerComponent.super.SetValue(self, value)
end

--设置Actor
function AngerComponent:OnActorSet(actor)
    AngerComponent.super.OnActorSet(self, actor)
end


function AngerComponent:InitServer()
    AngerComponent.super.InitServer(self)
    local anger = self.actor.StatComponent:GetValue("Anger")
    self.lastValue = anger
    self.actor:OnServerEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Anger" then
            local newAnger = self.actor.StatComponent:GetValue("Anger")
            if newAnger ~= self.lastValue then
                self:OnValueChange(self.lastValue, newAnger)
                self.lastValue = newAnger
            end
        end
    end)
end

function AngerComponent:InitClient()
    AngerComponent.super.InitClient(self)
    local anger = self.actor.StatComponent:GetValue("Anger")
    self.lastValue = anger
    self.actor:OnClientEvent("StatChanged", function(name,oldValue,newValue)
        if name == "Anger" then
            local newAnger = self.actor.StatComponent:GetValue("Anger")
            if newAnger ~= self.lastValue then
                self:OnValueChange(self.lastValue, newAnger)
                self.lastValue = newAnger
            end
        end
    end)
end
-----------------------------------------------------------------------

--序列化
function AngerComponent:Serialize(data, purpose)
    data.version = self.version
    AngerComponent.super.Serialize(self, data, purpose)
end

--反序列化
function AngerComponent:Deserialize(data)
    self.version = data.version
    AngerComponent.super.Deserialize(self, data)
end

return AngerComponent
