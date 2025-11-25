local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")

local Repeat = Class.New("Repeat", Action)
--初始化
function Repeat:Init(action, times)
    self.innerAction = action
    Action.Init(self, math.huge)
    self.times = times
    self.currentTimes = 0
end
--开始
function Repeat:StartWith(target)
    Repeat.super.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.currentTimes = 0
end
--停止
function Repeat:Stop()
    self.innerAction:Stop()
    Repeat.super.Stop(self)
end
--开始
function Repeat:OnStart()
end
--更新
function Repeat:Update(dt)
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
function Repeat:IsDone()
    return self.currentTimes >= self.times
end

--克隆
function Repeat:Clone()
    local action = Repeat.New()
    action:Init(self.innerAction:Clone(),self.times)
    return action
end

--反向
function Repeat:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = Repeat.New()
    action:Init(innerAction,self.times)
    return action
end

return Repeat