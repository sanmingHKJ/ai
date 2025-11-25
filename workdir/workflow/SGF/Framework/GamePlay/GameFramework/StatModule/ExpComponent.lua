local Class = GFScript("CoreModule.Class")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local Log = GFScript("CoreModule.Log")

-- 创建Level类并继承Energy类
local ExpComponent = Class.New("ExpComponent", EnergyComponent)

ExpComponent.version = 1

-- 构造函数
function ExpComponent:Awake()
    ExpComponent.super.Awake(self)
    self.valueStatName = "exp"
    self.maxValueStatName = "maxExp"
end

--获取能量名字
function ExpComponent:GetEnergyName()
    return "Exp"
end

--启动服务端
function ExpComponent:OnStartServer()

end
--启动客户端
function ExpComponent:OnStartClient()
end

--当前值改变事件
function ExpComponent:OnValueChange(oldValue, newValue)
    self.actor:Fire(self.actor:IsServer(), "ExpChanged", oldValue, newValue)
    ExpComponent.super.OnValueChange(self, oldValue, newValue)
end
--设置当前值
function ExpComponent:SetValue(value, source, sourceKey)
    ExpComponent.super.SetValue(self, value)
end

--增加经验值
--@param amount 经验值
--@param source 来源
--@param sourceKey 来源键
function ExpComponent:AddExp(amount, source, sourceKey)
    self:SetValue(self:GetValue() + amount, source, sourceKey)
end

--减少经验值
--@param amount 经验值
--@param source 来源
--@param sourceKey 来源键
function ExpComponent:SubExp(amount, source, sourceKey)
    self:SetValue(self:GetValue() - amount, source, sourceKey)
end


return ExpComponent