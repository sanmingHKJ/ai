local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local TestManager = Class.New("TestManager")

--初始化
function TestManager:Init()
end

--更新
function TestManager:Update(dt)
end

--服务端测试
function TestManager:RunServerTest(testName)
    local test = GFScript("TestModule."..testName)
    if test then
        test:RunServer()
    else
        Log:Error("Test not found:"..testName)
    end
end
--客户端测试
function TestManager:RunClientTest(testName)
    local test = GFScript("TestModule."..testName)
    if test then
        test:RunClient()
    else
        Log:Error("Test not found:"..testName)
    end
end

return TestManager