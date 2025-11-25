-- 说明:UI动作基类
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Color = GFScript("UIModule.UIMath.Color")
local UIUtils = GFScript("UIModule.UIUtils")

local UIAction = UIClass.New("UIAction")

--实例化
function UIAction:Constructor()
    --控制的目标
    self.target = nil
    --持续时间
    self.duration = 0
    --标记
    self.tag = nil
    --过去的时间
    self.elapsed = 0
    --是否第一次更新
    self.firstUpdate = true
    --更新回调
    self.updateCallback = nil
    --停止回调
    self.stopCallback = nil
end

--初始化
function UIAction:Init(duration)
    --持续时间
    self.duration = duration
    --过去的时间
    self.elapsed = 0
    --是否第一次更新
    self.firstUpdate = true
end

--开始
function UIAction:StartWith(target)
    self.target = target
    self.isDone = false
    self.elapsed = 0
    self.firstUpdate = true
    if target and target.bindObj then
        self.bindObj = target.bindObj
    else
        self.bindObj = target
    end
end

--停止
function UIAction:Stop()
    if self.stopCallback then
        self.stopCallback(self)
    end
    self.target = nil
end

--更新
function UIAction:Update(dt)
    if self.target == nil then
        return true
    end
    if self.firstUpdate then
        self.firstUpdate = false
        self:OnStart()
    end
	local newDt = dt
	if math.abs(self.elapsed) >= self.duration then
		newDt = 0
    elseif (self.elapsed + dt) > self.duration then
		newDt = self.duration - self.elapsed
		self.elapsed = self.duration + 0.00001
	else
		self.elapsed = self.elapsed + dt
    end
    local t = self.elapsed / self.duration
    t = math.min(t, 1)
    self:OnUpdate(t,newDt)
    if self.updateCallback ~= nil then
        self.updateCallback(self.target, t)
    end
    if math.abs(self.elapsed) >= self.duration then
        self:OnEnd()
        return true
    end
    return false
end

--开始
function UIAction:OnStart()

end

--更新
function UIAction:OnUpdate(t)

end

--结束
function UIAction:OnEnd()

end

--是否完成
function UIAction:IsDone()
    return math.abs(self.elapsed) >= self.duration or self.target == nil or self.isDone
end

--设置Tag
function UIAction:SetTag(t)
    self.tag = t
end

--立刻结束
function UIAction:StopImmediately()
    self.elapsed = self.duration
end

--克隆
function UIAction:Clone()
    return nil
end

--反向
function UIAction:Reverse(target)
    return nil
end

--设置位置
function UIAction:SetPosition(position)
    UIUtils:SetPosition(self.bindObj, position)
end

function UIAction:GetPosition()
    return UIUtils:GetPosition(self.bindObj)
end

--设置大小
function UIAction:SetSize(size)
    UIUtils:SetSize(self.bindObj, size)
end

function UIAction:GetSize()
    return UIUtils:GetSize(self.bindObj)
end
--设置旋转
function UIAction:SetRotation(rotation)
    UIUtils:SetRotation(self.bindObj, rotation)
end

function UIAction:GetRotation()
    return UIUtils:GetRotation(self.bindObj)
end

--设置缩放
function UIAction:SetScale(scale)
    UIUtils:SetScale(self.bindObj, scale)
end

function UIAction:GetScale()
    return UIUtils:GetScale(self.bindObj)
end

--设置颜色
function UIAction:SetColor(color)
    UIUtils:SetColorInHierarchy(self.bindObj, color)
end

function UIAction:GetColor()
    return UIUtils:GetColor(self.bindObj)
end

--设置透明度
function UIAction:SetAlpha(alpha)
    UIUtils:SetAlphaInHierarchy(self.bindObj, alpha)
end

function UIAction:GetAlpha()
    return UIUtils:GetAlpha(self.bindObj)
end


return UIAction
