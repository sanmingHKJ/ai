local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local BehaviorProcess = GFScript("AIModule.BTree.BehaviorProcess")
local BehaviorNode = GFScript("AIModule.BTree.BehaviorNode")
local EResult = BehaviorDefines.EResult
local EEvent = BehaviorDefines.EEvent

local BehaviorRoot = Class.New("BehaviorRoot", BehaviorNode)

--运行
function BehaviorRoot:Run(runtime, args)
    local ret = BehaviorRoot.super.Run(self, runtime, args)
    if ret ~= EResult.RUNNING then
        --正常退出一次
        runtime.stepVars = {}
    end
    return ret
end

return BehaviorRoot