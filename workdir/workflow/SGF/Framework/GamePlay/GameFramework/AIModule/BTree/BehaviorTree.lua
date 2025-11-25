local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local BehaviorNode = GFScript("AIModule.BTree.BehaviorNode")
local BehaviorRoot = GFScript("AIModule.BTree.BehaviorRoot")
local EResult = BehaviorDefines.EResult
local EEvent = BehaviorDefines.EEvent

local BehaviorTree = Class.New("BehaviorTree")
--自定义的处理器
BehaviorTree.process = {}
--自动id分配
BehaviorTree.autoUniqueId = 1000
--实例化
function BehaviorTree:Constructor(name)
    self.name = name
end

--初始化
function BehaviorTree:Init(data)
    if not data then
        return
    end
    self.root = BehaviorRoot.New(nil, data,self)
end

--运行
function BehaviorTree:Run(runtime)
    local lastRet
    if #runtime.stack > 0 then
        local lastNode = runtime.stack[#runtime.stack]
        while lastNode do
            lastRet = lastNode:Run(runtime)
            if lastRet == EResult.RUNNING then
                break
            end
            lastNode = runtime.stack[#runtime.stack]
        end
    else
        self:Dispatch(runtime,EEvent.BEFORE_RUN)
        lastRet = self.root:Run(runtime)
    end
    if runtime.abort then
        runtime.nodeStateVars = {}
        runtime.stepVars = {}
        runtime.stack = {}
        runtime.abort = nil
        runtime.serviceStack = {}
        runtime.lastRet = nil
        self:Dispatch(runtime,EEvent.INTERRUPTED)
        return EResult.ABORT
    elseif lastRet == EResult.SUCCESS then
        self:Dispatch(runtime,EEvent.AFTER_RUN)
        self:Dispatch(runtime,EEvent.AFTER_RUN_SUCCESS)
    elseif lastRet == EResult.FAIL then
        self:Dispatch(runtime,EEvent.AFTER_RUN)
        self:Dispatch(runtime,EEvent.AFTER_RUN_FAILURE)
    end
    return lastRet
end

--触发事件
function BehaviorTree:Dispatch(runtime,event, ...)
    local handlers = runtime.handlers[event]
    if handlers then
        for _, callback in ipairs(handlers) do
            callback(...)
        end
    end
end

--中断
function BehaviorTree:Interrupt(runtime)
    if #runtime.stack > 0 then
        self:Dispatch(runtime,BehaviorEvent.INTERRUPTED)
        runtime.nodeStateVars = {}
        runtime.stack = {}
    end
end

--是否正在运行
function BehaviorTree:IsRunning(runtime)
    return #runtime.stack > 0
end

--是否终止
function BehaviorTree:IsAbort(runtime)
    return runtime.abort
end

--获取自动id
function BehaviorTree:GetUniqueId()
    BehaviorTree.autoUniqueId = BehaviorTree.autoUniqueId + 1
    return BehaviorTree.autoUniqueId
end

--注册处理器
function BehaviorTree:RegisterProcess(process)
    self.process[process.name] = process
end

return BehaviorTree