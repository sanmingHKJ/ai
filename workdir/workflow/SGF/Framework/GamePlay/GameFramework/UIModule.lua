-- 说明:UI模块
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
_G.UIModules = {}

if not GFScript then
_G.GFScript = function(scriptName)
    if _G.UIModules[scriptName] then
        return _G.UIModules[scriptName]
    end
    --通过.号分割scriptName
    local function split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    local scriptNameList = split(scriptName, ".")
    local module = script.Parent
    if module then
        for _, name in ipairs(scriptNameList) do
            module = module[name]
            if module == nil then
                break
            end
        end
    end
    if module then
        local m = require(module)
        _G.UIModules[scriptName] = m
        return m
    end
end
end

local UILog = GFScript("UIModule.UILog")
local UIClass = GFScript("UIModule.UIClass")
local UIManager = GFScript("UIModule.UIManager")
local UIActionRunner = GFScript("UIModule.UIActionRunner")
local UITimer = GFScript("UIModule.UITimer")
local UIResource = GFScript("UIModule.UIResource")
local UIModule = {}
--版本号
UIModule.version = "1.0.0"
--模块名字
UIModule.moduleName = "UIModule"
--模块描述
UIModule.moduleDesc = "UI模块"
--日志标签
UIModule.logTag = "UI"

--是否已经启动过
UIModule.isStartup = false


--更新
function UIModule:OnUpdate(dt)
    UIManager:Update(dt)
    UIActionRunner:Update(dt)
    UITimer:Update(dt)
    UIResource:Update(dt)   

    UIClass:Update()
end


--启动
function UIModule:Startup()
    if self.isStartup then
        return
    end

    UIManager:Init()
    UIActionRunner:Init()
    UITimer:Init()
    UIResource:Init()

    self.isStartup = true
end

return UIModule 