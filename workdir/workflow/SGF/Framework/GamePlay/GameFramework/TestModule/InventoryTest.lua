local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local InventoryTest = Class.New("InventoryTest", BaseTest)


function InventoryTest:Constructor()
    self.testName = "InventoryTest"
end

--运行服务端测试
function InventoryTest:RunServer()
    Log:Info("InventoryTest RunServer")
end

--运行客户端测试
function InventoryTest:RunClient()
    Log:Info("InventoryTest RunClient")
end


return InventoryTest