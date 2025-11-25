local Log = GFScript("CoreModule.Log")
local UIExtendManager = ExtensionScript("UIExtendModule.UIExtendManager")
local UIExtendModule = {}

--版本号
UIExtendModule.version = "1.0.0"
--模块名字
UIExtendModule.moduleName = "UIExtendModule"
--模块描述
UIExtendModule.moduleDesc = "UI扩展模块"
--日志标签
UIExtendModule.logTag = "UIExtendData"

--是否已经启动过
UIExtendModule.isStartup = false


--更新
function UIExtendModule:OnUpdate(dt)
    UIExtendManager:Update(dt)
end


--启动
function UIExtendModule:Startup()
    if self.isStartup then
        return
    end

    UIExtendManager:Init()
    

    self.isStartup = true
end

return UIExtendModule