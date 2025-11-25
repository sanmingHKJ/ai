-- 说明:队列action
-- 日期:2024年5月16日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")

local UISequence = UIClass.New("UISequence", UIAction)

--初始化
function UISequence:Init(...)
    self.innerActions = {}
    local actions = {...}
    local d = 0
    for i = 1,#actions do
        if actions[i].duration then
            d = d + actions[i].duration
        end
        table.insert(self.innerActions,actions[i])
    end
    UIAction.Init(self,d)
end
--添加action
function UISequence:AddAction(action)
    table.insert(self.innerActions,action)
    if action.duration then
        self.duration = self.duration + action.duration
    end
end
--开始
function UISequence:StartWith(target)
    UIAction.StartWith(self,target)
    --启动第一个
    self.currentActionIndex = 1
    self.currentAction, self.currentActionIndex = self:ExecuteToNextDurationAction(self.currentActionIndex)
    if self.currentAction then
        self.currentAction:StartWith(self.target)
        self.isDone = false
    else
        self.isDone = true
    end
end
--停止
function UISequence:Stop()
    if self.currentAction then
        self.currentAction:Stop()
        self.currentAction = nil
    end
    UIAction.Stop(self)
end
--开始
function UISequence:OnStart()
end
--更新
function UISequence:Update(dt)
    if self.currentAction then
        self.elapsed = self.elapsed + dt
        local newDt = dt

        if self.currentAction.elapsed + dt > self.currentAction.duration then
            newDt = self.currentAction.duration - self.currentAction.elapsed
        end
        self.currentAction:Update(newDt)
        if self.currentAction:IsDone() then
            --当前action结束
            self.currentAction:Stop()
            self.currentAction = nil
            self.currentActionIndex = self.currentActionIndex + 1
            if self.currentActionIndex <= #self.innerActions then
                self.currentAction, self.currentActionIndex = self:ExecuteToNextDurationAction(self.currentActionIndex)
                if self.currentAction then
                    self.currentAction:StartWith(self.target)
                    self.currentAction:Update(dt - newDt)
                else
                    self.isDone = true
                end
            end
        end
    else
        self.isDone = true
    end
end

--执行到下一个duration的action
function UISequence:ExecuteToNextDurationAction(index)
    while index <= #self.innerActions do
        local action = self.innerActions[index]
        if action.duration then
            return action, index
        else
            --直接执行
            action:StartWith(self.target)
            action:Update(1)
            action:Stop()
        end
        index = index + 1
    end
    return nil, index
end

--克隆
function UISequence:Clone()
    local action = UISequence.New()
    local actions = {}  
    for i = 1,#self.innerActions do
        table.insert(actions,self.innerActions[i]:Clone())
    end
    action:Init(actions)
    return action
end

--反向
function UISequence:Reverse(target)
    local action = UISequence.New()
    local actions = {}
    for i = #self.innerActions,1,-1 do
        local reverseAction = self.innerActions[i]:Reverse(target)
        if not reverseAction then
            reverseAction = self.innerActions[i]:Clone()
        end
        table.insert(actions,reverseAction)
    end
    action:Init(actions)
    return action
end



return UISequence
