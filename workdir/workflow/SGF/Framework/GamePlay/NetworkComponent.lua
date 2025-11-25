local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local NetworkHelper = require(script.Parent.NetworkHelper)
local NetworkComponent = Class.New("NetworkComponent", ActorComponent)

function NetworkComponent:Destructor()

end

function NetworkComponent:OnConstructor()
    NetworkHelper:RegisterNetObj(self)
end

function NetworkComponent:OnDestructor()
    NetworkHelper:UnregisterNetObj(self)
end

function NetworkComponent:CheckSession(userId)
    return self:GetPlayerId() == userId
end

return NetworkComponent