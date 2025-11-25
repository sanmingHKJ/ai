local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local State = GFScript("CoreModule.State")

local StateMachine = Class.New("StateMachine")

--构造函数
function StateMachine:Constructor()
    self.stateList = {}
    self.currentState = nil
    self.nextState = nil
    self.debugEnabled = false
    self.paused = false
end

--初始化
function StateMachine:Init(states, owner, stateChangedCallback)
    self.owner = owner
    self:AddStates(states)
    self.stateChangedCallback = stateChangedCallback
end

--添加状态
function StateMachine:AddStates(states)
    for k, v in pairs(states) do
        if type(v) == "string" then
            local state = self:CreateState(v)
            self.stateList[state:GetName()] = state
        else
            local state = self:CreateState(k)
            self.stateList[state:GetName()] = state
        end
    end
end

function StateMachine:Pause()
    self.paused = true
end

function StateMachine:Resume()
    self.paused = false
end

--更新
function StateMachine:Update(dt)
    if self.paused then
        return
    end
    if self.currentState then
        self.currentState:Update(dt)
    end
    if self.nextState then
        if self.currentState then
            if self.debugEnabled then
                Log:Debug("StateMachine:ChangeState %s -> %s", self.currentState:GetName(), self.nextState:GetName())
            end
            self.currentState:Exit()
        end
        self.currentState = self.nextState
        self.nextState = nil
        self.currentState:Enter()
    end
end

--创建状态
function StateMachine:CreateState(stateName)
    local state = State.New()
    state:SetName(stateName)
    state:Init(self)
    return state
end

--添加状态
function StateMachine:AddState(state)
    self.stateList[state:GetName()] = state
end

--移除状态
function StateMachine:RemoveState(stateName)
    self.stateList[stateName] = nil
end

--切换状态
function StateMachine:ChangeState(stateName)
    local curStateName = ""
    if self.currentState then
        curStateName = self.currentState:GetName()
        self.currentState:Exit()
    end
    self.currentState = self.stateList[stateName]
    self.currentState:Enter()
    if self.stateChangedCallback ~= nil then
        self.stateChangedCallback(curStateName,self.currentState:GetName())
    end

    -- self.nextState = self.stateList[stateName]
    
    -- if self.stateChangedCallback ~= nil then
    --     local curStateName = ""
    --     if self.currentState ~= nil then
    --         curStateName = self.currentState:GetName()
    --     end
    --     self.stateChangedCallback(curStateName,self.nextState:GetName())
    -- end
end

--是否是某个状态
function StateMachine:IsState(stateName)
    if self.currentState then
        return self.currentState:GetName() == stateName
    end
    return false
end

--获取当前的状态
function StateMachine:GetCurrentState()
    if self.currentState then
        return self.currentState:GetName()
    end
    return nil
end

--执行自定义事件
function StateMachine:ExecuteEvent(eventName, ...)
    if self.currentState then
        self.currentState:ExecuteEvent(eventName, ...)
    end
end

--返回模块
return StateMachine