local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local Tween = GFScript("CoreModule.Tween")
local Ease = Class.New("Ease", Action)

--初始化
function Ease:Init(action, easing)
    self.innerAction = action
    Action.Init(self,action.duration)
    self.easing = easing
end

--开始
function Ease:StartWith(target)
    Action.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.isDone = false
end
--停止
function Ease:Stop()
    self.innerAction:Stop()
    Action.Stop(self)
end
--开始
function Ease:OnStart()
end
--更新
function Ease:Update(dt)
    if self.isDone then
        return
    end

    local e1 = Tween[self.easing](self.elapsed / self.duration) * self.duration
    local e2 = Tween[self.easing]((self.elapsed + dt) / self.duration) * self.duration
    local newDt = e2 - e1
    self.elapsed = self.elapsed + dt
    self.innerAction:Update(newDt)
    if self.innerAction:IsDone() then
        --当前action结束
        self.innerAction:Stop()
        self.isDone = true
    end
end

function Ease:IsDone()
    return self.innerAction:IsDone() or self.isDone
end

--克隆
function Ease:Clone()
    local action = Ease.New()
    action:Init(self.innerAction:Clone(),self.easing)
    return action
end

--反向
function Ease:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = Ease.New()
    action:Init(innerAction,self.easing)
    return action
end

return Ease
