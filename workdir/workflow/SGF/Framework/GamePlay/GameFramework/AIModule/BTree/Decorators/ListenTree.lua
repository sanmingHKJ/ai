local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult
local EEvent = BehaviorDefines.EEvent

local M = {
    name = "ListenTree",
    type = "Decorator",
    Run = function(node, runtime, args)
        local event = args.event or args.builtin
        runtime:on(event, function()
            if #node.children == 0 then
                return
            end
            local level = #runtime.stack
            local child = node.children[1]
            local ret = child:Run(runtime,child.args)
            if ret == EResult.RUNNING then
                while #runtime.stack > level do
                    local child = runtime:PopStack()
                    runtime:SetNodeStateVar(child, "YIELD", nil)
                end
            end
        end)
        return EResult.SUCCESS
    end
}

return M
