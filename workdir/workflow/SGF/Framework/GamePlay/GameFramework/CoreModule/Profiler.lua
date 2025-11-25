local Log = GFScript("CoreModule.Log")
local Profiler = {}

Profiler.stacks = {}

--开始计时
function Profiler:Start(name, maxTime)
    local stack = {
        startTime = os.clock(),
        maxTime = maxTime or 0,
        name = name,
        elapsedtime = 0,
    }
    table.insert(Profiler.stacks, stack)
end

--结束计时
function Profiler:Stop(callback)
    local stack = Profiler.stacks[#Profiler.stacks]
    if stack then
        local time = os.clock() - stack.startTime + stack.elapsedtime
        if time > stack.maxTime then
            Log:Error("Profiler: " .. stack.name .. " time: " .. time)
        end
        table.remove(Profiler.stacks)
        if #Profiler.stacks > 0 then
            --叠加时间
            local lastStack = Profiler.stacks[#Profiler.stacks]
            lastStack.elapsedtime = lastStack.elapsedtime + time
        end
        if callback then
            callback(time)
        end
        return time
    end
end

return Profiler