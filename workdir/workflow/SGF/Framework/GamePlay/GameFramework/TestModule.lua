local Log = GFScript("CoreModule.Log")
local TestManager = GFScript("TestModule.TestManager")
local TestModule = {}

--版本号
TestModule.version = "1.0.0"
--模块名字
TestModule.moduleName = "TestModule"
--模块描述
TestModule.moduleDesc = "Test模块"
--日志标签
TestModule.logTag = "Test"

--是否已经启动过
TestModule.isStartup = false


--更新
function TestModule:OnUpdate(dt)
    TestManager:Update(dt)
end


--启动
function TestModule:Startup()
    if self.isStartup then
        return
    end

    TestManager:Init()
    

    self.isStartup = true
end

return TestModule