-- 说明:进度条控件基类
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local SuperProgressBase = UIClass.New("SuperProgressBase", UIWidget)

function SuperProgressBase:Constructor()
    self.maxValue = 100
    self.value = 0
    self.displayValue = 0

    --第几圈
    self.circle = 0
    self.maxCircle = 1
end 

function SuperProgressBase:Destructor()
    
end

function SuperProgressBase:Init(bindObj)
    if not SuperProgressBase.super.Init(self, bindObj) then
        return false
    end
    return true
end

--设置最大圈数
function SuperProgressBase:SetMaxCircle(maxCircle)
    self.maxCircle = maxCircle
    local value = math.min(self.value, self.maxValue * self.maxCircle)
    self:SetValue(value)
end

--获取最大圈数
function SuperProgressBase:GetMaxCircle()
    return self.maxCircle
end

--设置最大值
function SuperProgressBase:SetMaxValue(maxValue)
    self.maxValue = maxValue
    self:UpdateProgress()
end

--增加当前值
function SuperProgressBase:AddValue(value)
    self:SetValue(self.value + value)
end

--设置当前值
function SuperProgressBase:SetValue(value)
    if value == self.value then
        return
    end
    self.value = value
    if self.maxCircle > 1 then
        self.value = math.min(self.value, self.maxValue * self.maxCircle)
        local circle = math.floor(self.value / self.maxValue)
        if circle ~= self.circle then
            self.circle = circle
            self:OnCircleChanged()
        end
    else
        self.value = math.min(self.value, self.maxValue)
    end
    self:UpdateProgress()
end

--是否为0
function SuperProgressBase:IsDisplayValueAtStart()
    local progress = self.displayValue / self.maxValue
    --只有在不是整数倍的情况下才取模
    if progress ~= math.floor(progress) then
        progress = progress % 1
    end
    return progress == 0
end

--是否为最大值
function SuperProgressBase:IsDisplayValueAtEnd()
    local progress = self.displayValue / self.maxValue
    --只有在不是整数倍的情况下才取模
    if progress ~= math.floor(progress) then
        progress = progress % 1
    end
    return progress == 1
end

--获取最大值
function SuperProgressBase:GetMaxValue()
    return self.maxValue
end

--获取当前值
function SuperProgressBase:GetValue()
    return self.value
end

--设置进度
function SuperProgressBase:SetProgress(progress)
    self:SetValue(self.maxValue * progress)
end

--获取进度
function SuperProgressBase:GetProgress()
    return self.value / self.maxValue
end

--获取进度的小数部分
function SuperProgressBase:GetProgressDecimal()
    return self.value / self.maxValue - math.floor(self.value / self.maxValue)
end

--获取进度的整数部分
function SuperProgressBase:GetProgressInteger()
    return math.floor(self.value / self.maxValue)
end

--获取百分比
function SuperProgressBase:GetPercent()
    local percent = self:GetProgress() * 100
    return percent
end

--设置百分比
function SuperProgressBase:SetPercent(percent)
    self:SetValue(self.maxValue * percent / 100)
end

--获取显示进度
function SuperProgressBase:GetDisplayProgress()
    return self.displayValue / self.maxValue
end

--更新进度
function SuperProgressBase:UpdateProgress()
    if self.displayValue ~= self.value then
        if self.progressAnimationSpeed and self.progressAnimationSpeed > 0 then
            local diff = self.value - self.displayValue
            local duration = math.abs(diff) / self.progressAnimationSpeed 

            self:Tween({
                {"ValueTo", self.value, duration, function(target, value)
                    self.displayValue = value
                    self:OnDisplayProgressChanged()
                end,
                function(target, value)
                    return self.displayValue
                end}
            }):Tag("UpdateProgress"):Start()
        else
            self.displayValue = self.value
            self:OnDisplayProgressChanged()
        end
    end
end

--圈数改变
function SuperProgressBase:OnCircleChanged()

end

--显示进度改变
function SuperProgressBase:OnDisplayProgressChanged()
    local progress = self.displayValue / self.maxValue
    --只有在不是整数倍的情况下才取模
    if progress ~= math.floor(progress) then
        progress = progress % 1
    end
    self:SetDisplayProgress(progress)
end

--设置显示进度
function SuperProgressBase:SetDisplayProgress(progress)
end

--设置进度动画速度
function SuperProgressBase:EnableProgressAnimation(speed)
    self.progressAnimationSpeed = speed
end

--禁用进度动画
function SuperProgressBase:DisableProgressAnimation()
    self.progressAnimationSpeed = nil
end


return SuperProgressBase

