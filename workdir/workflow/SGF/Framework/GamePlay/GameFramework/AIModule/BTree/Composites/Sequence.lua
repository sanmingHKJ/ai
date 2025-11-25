local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Sequence',
    type = 'Composite',
    Run = function(node, runtime, args)
        local last_idx, last_ret = node:Resume(runtime)
        if last_idx then
            if not last_ret then
                return EResult.FAIL
            end
            if last_ret == EResult.FAIL then
                return last_ret
            elseif last_ret == EResult.SUCCESS then
                last_idx = last_idx + 1
            else
                Log:Error("%s->${%s}#${$d}: unexpected status error",
                    node.tree.name, node.name, node.id)
            end
        else
            last_idx = 1
        end

        for i = last_idx, #node.children do
            local child = node.children[i]
            local r = child:Run(runtime, child.args)
            if r == EResult.RUNNING then
                return node:Yield(runtime, i)
            end
            if r == EResult.FAIL then
                return r
            end
        end
        return EResult.SUCCESS
    end
}

return M
