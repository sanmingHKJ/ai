local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local CombatTest = Class.New("CombatTest", BaseTest)


function CombatTest:Constructor()
    self.testName = "CombatTest"
end

--运行服务端测试
function CombatTest:RunServer()
    Log:Info("CombatTest RunServer")
end

--运行客户端测试
function CombatTest:RunClient()
    Log:Info("CombatTest RunClient")
end


return CombatTest