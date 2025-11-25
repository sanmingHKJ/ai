-- 说明:圆环布局控件
-- 日期:2025年2月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperCricleLayout = UIClass.New("SuperCricleLayout", UIWidget)

function SuperCricleLayout:Constructor()
    self.startAngle = 0
    self.endAngle = 360
    self.radius = 0
    self.angleOffset = 0
end

function SuperCricleLayout:Destructor()
    
end

--初始化
function SuperCricleLayout:Init(bindObj)
    if not SuperCricleLayout.super.Init(self, bindObj) then
        return false
    end
    self:Refresh()
    return true
end

--设置起始角度
function SuperCricleLayout:SetStartAngle(startAngle)
    self.startAngle = startAngle
    self:Refresh()
end

--设置结束角度
function SuperCricleLayout:SetEndAngle(endAngle)
    self.endAngle = endAngle
end

--设置半径
function SuperCricleLayout:SetRadius(radius)
    self.radius = radius
    self:Refresh()
end

--获取起始角度
function SuperCricleLayout:GetStartAngle()
    return self.startAngle
end

--获取结束角度
function SuperCricleLayout:GetEndAngle()
    return self.endAngle
end

--获取半径
function SuperCricleLayout:GetRadius()
    return self.radius
end

--设置角度偏移
function SuperCricleLayout:SetAngleOffset(angleOffset)
    self.angleOffset = angleOffset
    self:Refresh()
end

--获取角度偏移
function SuperCricleLayout:GetAngleOffset()
    return self.angleOffset
end

--重绘  
function SuperCricleLayout:OnRefresh()
    if not self.bindObj then
        return
    end
    local screenRect = self:GetScreenRect()
    local children = self.bindObj.Children
    for i, child in ipairs(children) do
        local angle = self.startAngle + (self.endAngle - self.startAngle) * (i - 1) / #children
        local pos = UIUtils:CalculateCirclePos(self.radius, self.radius, angle + self.angleOffset)
        UIUtils:SetScreenPosition(child, pos + screenRect:GetCenter())
    end
end

return SuperCricleLayout
