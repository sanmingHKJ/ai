local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = "RepeatUntilSuccess",
    type = "Decorator",
    Run = function(node, runtime, max_loop)
        max_loop = max_loop or node.args.maxLoop or math.maxinteger

        local count, resume_ret = node:Resume(runtime)
        if count then
            if resume_ret == EResult.SUCCESS then
                return EResult.SUCCESS
            elseif count >= max_loop then
                return EResult.FAIL
            else
                count = count + 1
            end
        else
            count = 1
        end

        local child = node.children[1]
        if not child then
            return EResult.FAIL
        end
        local r = child:Run(runtime,child.args)
        if r == EResult.SUCCESS then
            return EResult.SUCCESS
        else
            return node:Yield(runtime, count)
        end
    end
}

return M
