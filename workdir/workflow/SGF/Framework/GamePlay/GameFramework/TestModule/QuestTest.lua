local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local QuestTest = Class.New("QuestTest", BaseTest)


function QuestTest:Constructor()
    self.testName = "QuestTest"
end

--运行服务端测试
function QuestTest:RunServer()
    Log:Info("QuestTest RunServer")
end

--运行客户端测试
function QuestTest:RunClient()
    Log:Info("QuestTest RunClient")
end


return QuestTest