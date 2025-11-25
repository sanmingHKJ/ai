local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local Action = Class.New("Action")

--实例化
function Action:Constructor()
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
function Action:Init(duration)
    --持续时间
    self.duration = duration
    --过去的时间
    self.elapsed = 0
    --是否第一次更新
    self.firstUpdate = true
end

--开始
function Action:StartWith(target)
    self.target = target
    self.isDone = false
    self.elapsed = 0
    self.firstUpdate = true
end
--停止
function Action:Stop()
    if self.stopCallback then
        self.stopCallback(self)
    end
    self.target = nil
end

--更新
function Action:Update(dt)
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
function Action:OnStart()

end

--更新
function Action:OnUpdate(t)

end

--结束
function Action:OnEnd()

end

--是否完成
function Action:IsDone()
    return math.abs(self.elapsed) >= self.duration or self.target == nil or self.isDone
end

--设置Tag
function Action:SetTag(t)
    self.tag = t
end

--立刻结束
function Action:StopImmediately()
    self.elapsed = self.duration
end

--克隆
function Action:Clone()
    return nil
end

--反向
function Action:Reverse(target)
    return nil
end

return Action