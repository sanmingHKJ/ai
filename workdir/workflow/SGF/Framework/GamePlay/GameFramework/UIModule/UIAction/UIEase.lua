-- 说明:缓动action
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local Ease = GFScript("UIModule.UIMath.Ease")
local UIEase = UIClass.New("UIEase", UIAction)

--初始化
function UIEase:Init(action, easing)
    self.innerAction = action
    UIAction.Init(self,action.duration)
    self.easing = easing
end

--开始
function UIEase:StartWith(target)
    UIAction.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.isDone = false
end
--停止
function UIEase:Stop()
    self.innerAction:Stop()
    UIAction.Stop(self)
end
--开始
function UIEase:OnStart()
end
--更新
function UIEase:Update(dt)
    if self.isDone then
        return
    end

    local e1 = Ease[self.easing](self.elapsed / self.duration) * self.duration
    local e2 = Ease[self.easing]((self.elapsed + dt) / self.duration) * self.duration
    local newDt = e2 - e1
    self.elapsed = self.elapsed + dt
    self.innerAction:Update(newDt)
    if math.abs(self.elapsed) > self.duration then
        --当前action结束
        self.innerAction:Stop()
        self.isDone = true
    end
end

--克隆
function UIEase:Clone()
    local action = UIEase.New()
    action:Init(self.innerAction:Clone(),self.easing)
    return action
end

--反向
function UIEase:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = UIEase.New()
    action:Init(innerAction,self.easing)
    return action
end

return UIEase
