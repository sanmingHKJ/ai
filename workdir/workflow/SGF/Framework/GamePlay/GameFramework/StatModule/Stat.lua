local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Stat = Class.New("Stat")


--实例化
--参数name:属性类型，见StatDefines.EStatType,字符串形式
--参数value:属性值
function Stat:Constructor(name, value)
    self.name = name
    self.value = value
    --判断名字结尾是否已Per结束
    self.isPercent = Utils:EndWith(name, "Per")
    --将Per前面的字符串取出来
    if self.isPercent then
        self.addToStatName = string.sub(name, 1, #name - 3)
    end
end

--设置属性值
function Stat:SetValue(value, silent)
    if self.value == value then
        return
    end
    local oldValue = self.value
    self.value = value
    if not silent then
        self:OnStatChanged(oldValue, value)
    end
end
--获取名字
function Stat:GetName()
    return self.name
end
--获取属性值
function Stat:GetValue()
    return self.value
end

--属性改变事件
function Stat:OnStatChanged(oldValue, newValue)
    -- body
end

--克隆
function Stat:Clone()
    return Stat.New(self.name, self.value)
end

return Stat