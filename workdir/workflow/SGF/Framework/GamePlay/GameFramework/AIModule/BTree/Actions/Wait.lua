local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local Math = GFScript("CoreModule.Math")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Wait',
    type = 'Action',
    Run = function(node, runtime, args)
        local t = node:Resume(runtime)
        if t then
            if runtime.ctx.time >= t then
                return EResult.SUCCESS
            else
                return EResult.RUNNING
            end
        end
        local waitTimeBBKey = args.waitTimeBBKey or args.BBKey
        local waitTime = args.waitTime or args.time
        
        local time = runtime:GetBB(node, waitTimeBBKey, waitTime)
        local waitTime = 0
        if type(time) == "table" then
            waitTime = Math:Random(time[1], time[2])
        elseif type(time) == "number" then
            waitTime = time
        else
            Log:Error("Wait", "time is not number or table")
            return EResult.FAILURE
        end
        waitTime = math.max(waitTime, 0)
        return node:Yield(runtime, runtime.ctx.time + waitTime)
    end
}

return M
