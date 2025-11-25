local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local NetworkComponent = GFScript("NetworkModule.NetworkComponent")
local RpcTestComponent = Class.New("RpcTestComponent", NetworkComponent)

--初始化
function RpcTestComponent:Init()
    Log:Info("RpcTest Init")
end

function RpcTestComponent:CmdGetPlayerInfo()
    Rpc("RpcPlayerInfo", {name = "Test", age = 18}) 
end

function RpcTestComponent:RpcPlayerInfo(playerInfo)
    Log:Info("RpcPlayerInfo name:%s age:%d", playerInfo.name, playerInfo.age)
end

return RpcTestComponent