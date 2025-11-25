local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'Not',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local r
        if node:Resume(runtime) then
            r = runtime.last_ret
        else
            local child = node.children[1]
            if not child then
                return EResult.SUCCESS
            end
            r = child:Run(runtime,child.args)
        end

        if r == EResult.SUCCESS then
            return EResult.FAIL
        elseif r == EResult.FAIL then
            return EResult.SUCCESS
        else
            return node:Yield(runtime)
        end
    end
}

return M
