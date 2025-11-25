local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local NetworkIdentity = GFScript("NetworkModule.NetworkIdentity")
local RpcTestComponent = GFScript("TestModule.RpcTestComponent")

local RpcTestNode = Class.New("RpcTestNode")

--初始化
function RpcTestNode:Init()
    self.netIdentity = self:AddComponent(NetworkIdentity.New(self))
    self.rpcTestComp = self:AddComponent(RpcTestComponent.New(self))

    self.netIdentity:AddForScene(self:GetScene())
end




return RpcTestNode
