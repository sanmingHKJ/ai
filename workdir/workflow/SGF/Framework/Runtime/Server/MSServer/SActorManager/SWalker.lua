local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local SNpc = require( script.Parent.SNpc)

-- 服务端怪物
local SWalker = Class.New("SWalker", SNpc)

function SWalker:InitServer()
    SWalker.super.InitServer(self)
end

function SWalker:Update(dt)
    SWalker.super.Update(self, dt)
end
--更新
function SWalker:LaterUpdate(dt)
    SWalker.super.LaterUpdate(self, dt)
end

return SWalker