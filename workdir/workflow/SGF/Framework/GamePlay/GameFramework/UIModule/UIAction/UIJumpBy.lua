-- 说明:跳跃actin
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local Ease = GFScript("UIModule.UIMath.Ease")
local Vec2 = GFScript("UIModule.UIMath.Vec2")

local UIJumpBy = UIClass.New("UIJumpBy", UIAction)

--初始化
function UIJumpBy:Init(duration, delta, height, upCallback,downCallback)
    UIAction.Init(self,duration)
    self.direction = delta:Normalized()
    self.delta = delta:Clone()
    self.height = height
    self.upCallback = upCallback
    self.downCallback = downCallback
    self.preState = -1 --0上升 1下降
    self.previousY = 0
    self.speed = self.delta:Magnitude() / self.duration

    --各阶段曲线
    self.moveEasing = Ease.Easing.Linear
    self.upEasing = Ease.Easing.Linear
    self.downEasing = Ease.Easing.Linear
end

--开始
function UIJumpBy:StartWith(target)
    UIAction.StartWith(self, target)
    self.startPosition = self:GetPosition()
    self.previousPosition = self.startPosition:Clone()
end

--开始
function UIJumpBy:OnStart()
end

--更新
function UIJumpBy:OnUpdate(t, dt)

    local curState = (t <= 0.5) and 0 or 1
    if curState ~= self.preState then
        if curState == 1 then
            --落地
            if self.downCallback ~= nil then
                self.downCallback()
            end
        elseif curState == 0 then
            --上升
            if self.upCallback ~= nil then
                self.upCallback()
            end
        end
        self.preState = curState
    end

    local positionOffset
    if t <= 0.5 then
        positionOffset = self:CalculatePositionOffset(Ease[self.upEasing](t / 0.5) * 0.5)
    else
        positionOffset = self:CalculatePositionOffset(Ease[self.downEasing]((t - 0.5) / 0.5) * 0.5 + 0.5)
    end


    local preProcess = (self.elapsed - dt) / self.duration
    local curProcess = (self.elapsed) / self.duration
    preProcess = Ease[self.moveEasing](preProcess)
    curProcess = Ease[self.moveEasing](curProcess)
    local newDt = (curProcess - preProcess) * self.duration

    local jumpOffset = Vec2.New(0, positionOffset - self.previousY)
    local moveOffset = self.direction * newDt * self.speed

    local position = self:GetPosition()
    local newPos = position + jumpOffset - moveOffset

    self:SetPosition(newPos)

    self.previousY = positionOffset
end

function UIJumpBy:CalculatePositionOffset(t)
    return self.height * 4 * t * (1 - t)
end

--结束
function UIJumpBy:Stop()
    UIAction.Stop(self)
end

--克隆
function UIJumpBy:Clone()
    local action = UIJumpBy.New()
    action:Init(self.duration,self.delta,self.height,self.upCallback,self.downCallback)
    return action
end

--反向
function UIJumpBy:Reverse(target)
    local action = UIJumpBy.New()
    action:Init(self.duration,-self.delta,self.height,self.downCallback,self.upCallback)
    return action
end


return UIJumpBy