-- 说明:间隔执行器
-- 日期:2025年5月30日
-- 支持:揭育龙
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local IntervalExecutor = Class.New("IntervalExecutor")

-- 构造函数
function IntervalExecutor:Constructor()
    self.isRunning = false -- 是否运行
    self.interval = 0 -- 间隔时间
    self.checkCallback = nil -- 检查回调函数
    self.callback = nil -- 回调函数
    self.accumulatedTime = 0 -- 累积时间
    self.compensationEnabled = false -- 是否启用补偿机制
    self.targetExecutionsPerSecond = 0 -- 目标执行次数

    --是否启动时执行
    self.startExecute = true
end

-- 设置间隔时间（秒）
function IntervalExecutor:SetInterval(interval)
    if type(interval) ~= "number" or interval < 0 then
        Log:Error("Invalid interval value")
        return
    end
    self.interval = interval
    self.targetExecutionsPerSecond = interval > 0 and 1 / interval or 0
end

-- 设置是否启动时执行
function IntervalExecutor:SetStartExecute(startExecute)
    self.startExecute = startExecute
end

-- 设置回调函数
function IntervalExecutor:SetCallback(callback)
    if type(callback) ~= "function" then
        Log:Error("Callback must be a function")
        return
    end
    self.callback = callback
end

-- 设置检查回调函数
function IntervalExecutor:SetCheckCallback(checkCallback)
    if type(checkCallback) ~= "function" then
        Log:Error("Check callback must be a function")
        return
    end
    self.checkCallback = checkCallback
end

--执行回调
function IntervalExecutor:ExecuteCallback()
    if self.checkCallback then
        if not self.checkCallback() then
            return
        end
    end
    if self.callback then
        self.callback()
    end
end

-- 设置是否启用补偿机制
function IntervalExecutor:SetCompensationEnabled(enabled)
    self.compensationEnabled = enabled
end

-- 启动执行器
function IntervalExecutor:Start()
    if not self.callback then
        Log:Error("Cannot start: callback not set")
        return
    end
    if self.interval <= 0 then
        Log:Error("Cannot start: invalid interval")
        return
    end
    self.isRunning = true
    self.accumulatedTime = 0

    if self.startExecute then
        self:ExecuteCallback()
    end
end

-- 停止执行器
function IntervalExecutor:Stop()
    self.isRunning = false
end

-- 更新函数，由外部调用
function IntervalExecutor:Update(dt)
    if not self.isRunning or not self.callback or self.interval <= 0 then
        return
    end
    self.accumulatedTime = self.accumulatedTime + dt

    if self.compensationEnabled then
        local executions = math.floor(self.accumulatedTime / self.interval)
        -- 限制最大执行次数
        executions = math.min(executions, 60)
        
        if executions > 0 then
            self.accumulatedTime = self.accumulatedTime - (executions * self.interval)
            if self.callback then
                for i = 1, executions do
                    self:ExecuteCallback()
                end
            end
        end
    else
        if self.accumulatedTime >= self.interval then
            self.accumulatedTime = 0
            self:ExecuteCallback()
        end
    end
end

return IntervalExecutor 