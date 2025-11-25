local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local BehaviorNode = GFScript("AIModule.BTree.BehaviorNode")
local BehaviorRuntime = GFScript("AIModule.BTree.BehaviorRuntime")

local GenericRuntime = Class.New("GenericRuntime", BehaviorRuntime)


return GenericRuntime
