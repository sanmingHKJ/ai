local Class = GFScript("CoreModule.Class")

local LinearValue = Class.New("LinearValue")

--构造函数
function LinearValue:Constructor()
    self.baseValue = 0
    self.bonusValue = 0
end

--根据等级获取值
function LinearValue:Get(level)
    return self.baseValue + self.bonusValue * level
end

return LinearValue