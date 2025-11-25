local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local BuffTest = Class.New("BuffTest", BaseTest)


function BuffTest:Constructor()
    self.testName = "BuffTest"
end

--运行服务端测试
function BuffTest:RunServer()
    Log:Info("BuffTest RunServer")
end

--运行客户端测试
function BuffTest:RunClient()
    Log:Info("BuffTest RunClient")
end


return BuffTest