-- 说明:速度action
-- 日期:2025年3月7日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local UISpeed = UIClass.New("UISpeed", UIAction)

--初始化
function UISpeed:Init(action, speed)
    self.innerAction = action
    UIAction.Init(self,action.duration / speed)
    self.speed = speed
end

--开始
function UISpeed:StartWith(target)
    UIAction.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.isDone = false
end
--停止
function UISpeed:Stop()
    self.innerAction:Stop()
    UIAction.Stop(self)
end
--开始
function UISpeed:OnStart()
end
--更新
function UISpeed:Update(dt)
    if self.isDone then
        return
    end
    self.elapsed = self.elapsed + dt
    self.innerAction:Update(dt * self.speed)
    if math.abs(self.elapsed) > self.duration then
        --当前action结束
        self.innerAction:Stop()
        self.isDone = true
    end
end

--克隆
function UISpeed:Clone()
    local action = UISpeed.New()
    action:Init(self.innerAction:Clone(),self.speed)
    return action
end

--反向
function UISpeed:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = UISpeed.New()
    action:Init(innerAction,self.speed)
    return action
end

return UISpeed
