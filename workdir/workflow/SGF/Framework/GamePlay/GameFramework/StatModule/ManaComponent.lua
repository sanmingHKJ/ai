local Class = GFScript("CoreModule.Class")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local Log = GFScript("CoreModule.Log")

local ManaComponent = Class.New("ManaComponent",EnergyComponent)

-- 构造函数
function ManaComponent:Awake()
    ManaComponent.super.Awake(self)
    self.valueStatName = "Mana"
    self.maxValueStatName = "MaxMana"
    self.regenStatName = "ManaRegen"
end

--获取能量名字
function ManaComponent:GetEnergyName()
    return "Mana"
end

--启动服务端
function ManaComponent:OnStartServer()
    ManaComponent.super.OnStartServer(self)
end
--启动客户端
function ManaComponent:OnStartClient()
end

-- 使用法力值
function ManaComponent:UseMana(amount)
    -- 检查法力值是否足够
    if self:GetValue() >= amount then
        self:SubValue(amount)
        return true -- 使用成功
    else
        return false -- 使用失败，法力值不足
    end
end
--当前值改变事件
function ManaComponent:OnValueChange(oldValue, newValue)
    if self.actor:IsServer() then
        self.actor:ServerSyncEnergy("Mana")
    else
        --触发事件
        self.actor:FireClient("ManaChanged", oldValue, newValue)
    end
    ManaComponent.super.OnValueChange(self, oldValue, newValue)
end
--设置当前值
function ManaComponent:SetValue(value)
    --Log:Debug("SetMana value="..value.." max="..self:GetMaxValue())
    ManaComponent.super.SetValue(self, value)
end

return ManaComponent
