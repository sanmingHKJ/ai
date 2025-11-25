local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local M = {
    name = 'AlwaysSuccess',
    type = 'Decorator',
    Run = function(node, runtime, args)
        local yeild, last_ret = node:Resume(runtime)
        if yeild then
            if last_ret == EResult.RUNNING then
                Log:Error("%s->${%s}#${$d}: unexpected status error",
                    node.tree.name, node.name, node.id)
            end
            return EResult.SUCCESS
        end

        local child = node.children[1]
        if not child then
            return EResult.SUCCESS
        end
        local r = child:Run(runtime,child.args)
        if r == EResult.RUNNING then
            return node:Yield(runtime)
        end
        return EResult.SUCCESS
    end
}

return M
