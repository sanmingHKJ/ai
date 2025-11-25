local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local StatTest = Class.New("StatTest", BaseTest)


function StatTest:Constructor()
    self.testName = "StatTest"
end

--运行服务端测试
function StatTest:RunServer()
    Log:Info("StatTest RunServer")
end

--运行客户端测试
function StatTest:RunClient()
    Log:Info("StatTest RunClient")
end


return StatTest