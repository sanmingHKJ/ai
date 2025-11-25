-- 说明:循环action
-- 日期:2024年5月16日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")

local UIRepeat = UIClass.New("UIRepeat", UIAction)
--初始化
function UIRepeat:Init(action, times)
    self.innerAction = action
    UIAction.Init(self, math.huge)
    self.times = times
    self.currentTimes = 0
end
--开始
function UIRepeat:StartWith(target)
    UIRepeat.super.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.currentTimes = 0
end
--停止
function UIRepeat:Stop()
    self.innerAction:Stop()
    UIRepeat.super.Stop(self)
end
--开始
function UIRepeat:OnStart()
end
--更新
function UIRepeat:Update(dt)
    if not self.innerAction then
        return
    end
    self.elapsed = self.elapsed + dt
    self.innerAction:Update(dt)
    if self.innerAction:IsDone() and self.currentTimes < self.times then
        self.currentTimes = self.currentTimes + 1
        local newDt = math.max(0, self.innerAction.elapsed - self.innerAction.duration)
        --重新继续开始
        self.innerAction:StartWith(self.target)
        self.innerAction:Update(0)
        self.innerAction:Update(newDt)
    end
end

--是否完成
function UIRepeat:IsDone()
    return self.currentTimes >= self.times
end

--克隆
function UIRepeat:Clone()
    local action = UIRepeat.New()
    action:Init(self.innerAction:Clone(),self.times)
    return action
end

--反向
function UIRepeat:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = UIRepeat.New()
    action:Init(innerAction,self.times)
    return action
end

return UIRepeat