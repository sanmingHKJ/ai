local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Class = GFScript("CoreModule.Class")
local BaseTest = GFScript("TestModule.BaseTest")

local SkillTest = Class.New("SkillTest", BaseTest)


function SkillTest:Constructor()
    self.testName = "SkillTest"
end

--运行服务端测试
function SkillTest:RunServer()
    Log:Info("SkillTest RunServer")
end

--运行客户端测试
function SkillTest:RunClient()
    Log:Info("SkillTest RunClient")
end


return SkillTest