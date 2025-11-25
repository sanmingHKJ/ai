local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local State = Class.New("State")

--构造函数
function State:Constructor()
    self.stateMachine = nil
end

--初始化
function State:Init(stateMachine)
    self.stateMachine = stateMachine
    self.enterCallback = stateMachine.owner[self:GetName().."_Enter"]
    self.exitCallback = stateMachine.owner[self:GetName().."_Exit"]
    self.updateCallback = stateMachine.owner[self:GetName().."_Update"]

    self.eventCallbacks = {}
end

--获取状态机
function State:GetStateMachine()
    return self.stateMachine
end

--获取状态名
function State:GetName()
    return self.name
end

--设置状态名
function State:SetName(name)
    self.name = name
end

--进入
function State:Enter()
    if self.enterCallback then
        self.enterCallback(self.stateMachine.owner)
    end
end

--退出
function State:Exit()
    if self.exitCallback then
        self.exitCallback(self.stateMachine.owner)
    end
end

--执行自定义事件
function State:ExecuteEvent(eventName, ...)
    local eventCallback = self.eventCallbacks[eventName]
    if eventCallback then
        eventCallback(self.stateMachine.owner, ...)
        return
    end
    eventCallback = self.stateMachine.owner[self:GetName().."_"..eventName]
    if eventCallback then
        self.eventCallbacks[eventName] = eventCallback
        eventCallback(self.stateMachine.owner, ...)
    end
end

--更新
function State:Update(dt)
    if self.updateCallback then
        self.updateCallback(self.stateMachine.owner, dt)
    end
end

--返回模块
return State