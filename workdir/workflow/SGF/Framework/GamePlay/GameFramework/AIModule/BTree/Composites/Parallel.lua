local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Parallel',
    type = 'Composite',
    Run = function(node, runtime, args)
        local last_idx, last_ret = node:Resume(runtime)
        if last_idx then
            if not last_ret then
                return EResult.FAIL
            end
            if last_ret == EResult.RUNNING then
                return last_ret
            end
            last_idx = last_idx + 1
        else
            last_idx = 1
        end

        for i = last_idx, #node.children do
            local child = node.children[i]
            local r = child:Run(runtime,child.args)
            if r == EResult.RUNNING then
                return node:Yield(runtime, i)
            end
        end
        return EResult.SUCCESS
    end
}

return M
