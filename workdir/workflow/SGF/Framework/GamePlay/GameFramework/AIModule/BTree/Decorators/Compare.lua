local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local EResult = BehaviorDefines.EResult

local function ret(r)
    return r and EResult.SUCCESS or EResult.FAIL
end

local M = {
    name = 'Compare',
    type = 'Condition',
    Run = function(node, runtime, args)
        local bbKey = args.objectBBKey or args.BBKey
        if bbKey == nil then
            Log:Error('args error')
            return EResult.FAIL
        end
        local value = runtime:GetBB(node, bbKey)

        if args.op == '==' then
            return ret(value == args.value)
        elseif args.op == '>' then
            return ret(value > args.value)
        elseif args.op == '>=' then
            return ret(value >= args.value)
        elseif args.op == '<' then
            return ret(value < args.value)
        elseif args.op == '<=' then
            return ret(value <= args.value)
        else
            Log:Error('args error')
        end
    end
}

return M
