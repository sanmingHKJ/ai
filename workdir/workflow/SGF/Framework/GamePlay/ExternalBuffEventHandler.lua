local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local BuffEventHandler = GFScript("BuffModule.BuffEventHandler")

local ExternalBuffEventHandler = {}
-- ExternalBuffEventHandler.__index = function(table, key)
--     local value = rawget(ExternalBuffEventHandler, key)
--     if value then
--         return value
--     end
--     return SkillEventHandler[key]
-- end
setmetatable(ExternalBuffEventHandler, {__index = BuffEventHandler})



return ExternalBuffEventHandler