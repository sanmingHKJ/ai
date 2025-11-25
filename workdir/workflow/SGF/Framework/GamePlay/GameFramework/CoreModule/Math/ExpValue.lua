local Class = GFScript("CoreModule.Class")

local ExpValue = Class.New("ExpValue")

--构造函数
function ExpValue:Constructor()
    self.baseValue = 0
    self.mulValue = 0
end

--根据等级获取值
function ExpValue:Get(level)
    return self.mulValue * math.pow(self.baseValue, level - 1)
end

return ExpValue