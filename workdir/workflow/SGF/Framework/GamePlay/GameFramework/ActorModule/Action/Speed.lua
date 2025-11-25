local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")
local Speed = Class.New("Speed", Action)

--初始化
function Speed:Init(action, speed)
    self.innerAction = action
    Action.Init(self,action.duration / speed)
    self.speed = speed
end

--开始
function Speed:StartWith(target)
    Action.StartWith(self,target)
    self.innerAction:StartWith(target)
    self.isDone = false
end
--停止
function Speed:Stop()
    self.innerAction:Stop()
    Action.Stop(self)
end
--开始
function Speed:OnStart()
end
--更新
function Speed:Update(dt)
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
function Speed:Clone()
    local action = Speed.New()
    action:Init(self.innerAction:Clone(),self.speed)
    return action
end

--反向
function Speed:Reverse(target)
    local innerAction = self.innerAction:Reverse(target)
    if not innerAction then
        innerAction = self.innerAction:Clone()
    end
    local action = Speed.New()
    action:Init(innerAction,self.speed)
    return action
end

return Speed
