local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Action = GFScript("ActorModule.Action")

local ActionInstant = Class.New("ActionInstant", Action)
--更新
function ActionInstant:Update(dt)
    if self.target == nil then
        return true
    end
    if self.firstUpdate then
        self.firstUpdate = false
        self:OnStart()
    end
    self:OnUpdate(1)
    self:OnEnd()
    return true
end

--是否完成
function ActionInstant:IsDone()
    return true
end


return ActionInstant