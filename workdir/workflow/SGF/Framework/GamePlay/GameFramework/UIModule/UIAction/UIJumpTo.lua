-- 说明:跳跃actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UIUtils = GFScript("UIModule.UIUtils")
local UIJumpBy = GFScript("UIModule.UIAction.UIJumpBy")

local UIJumpTo = UIClass.New("UIJumpTo", UIJumpBy)

--初始化
function UIJumpTo:Init(duration,endPosition,height,upCallback,downCallback)
    UIJumpBy.Init(self,duration,endPosition,height,upCallback,downCallback)
    self.endPosition = endPosition:Clone()
end

--开始
function UIJumpTo:StartWith(target)
    UIJumpBy.StartWith(self, target)
    local targetPos = self:GetPosition()
    self.height = self.height - targetPos.y
    self.delta = self.endPosition - targetPos
    self.direction = self.delta:Normalized()
    self.speed = self.delta:Magnitude() / self.duration
end

--开始
function UIJumpTo:OnStart()
    UIJumpBy.OnStart(self)
end

--克隆
function UIJumpTo:Clone()
    local action = UIJumpTo.New()
    action:Init(self.duration,self.endPosition,self.height,self.upCallback,self.downCallback)
    return action
end

--反向
function UIJumpTo:Reverse(target)
    if not target then
        return self:Clone()
    end
    local action = UIJumpTo.New()
    action:Init(self.duration,UIUtils:GetPosition(target),self.height,self.upCallback,self.downCallback)
    return action
end


return UIJumpTo