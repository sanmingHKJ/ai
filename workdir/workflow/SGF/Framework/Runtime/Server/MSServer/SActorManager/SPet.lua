local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local SNpc = require( script.Parent.SNpc)

-- 服务端怪物
local SPet = Class.New("SPet", SNpc)

function SPet:InitServer()
    SPet.super.InitServer(self)
end

function SPet:Update(dt)
    SPet.super.Update(self, dt)
end
--更新
function SPet:LaterUpdate(dt)
    SPet.super.LaterUpdate(self, dt)
end

return SPet