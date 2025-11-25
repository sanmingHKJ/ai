local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Waypath = GFScript("ActorModule.PathSystem.Waypath")

local TrafficPath = Class.New("TrafficPath", Waypath)

function TrafficPath:Constructor()

end

--初始化
function TrafficPath:Init(scene)
    TrafficPath.super.Init(self, scene)
end

--更新
function TrafficPath:Update(dt)
    TrafficPath.super.Update(self, dt)
end

return TrafficPath