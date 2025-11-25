local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")

local BaseTest = Class.New("BaseTest")


function BaseTest:Constructor()
    self.testName = "BaseTest"
end


function BaseTest:Destructor()
    self.testName = nil
end

--运行服务端测试
function BaseTest:RunServer()
    Log:Info("BaseTest RunServer")
end

--运行客户端测试
function BaseTest:RunClient()
    Log:Info("BaseTest RunClient")
end


return BaseTest