_G.GFExtensions = {}
_G.ExtensionScript = function(scriptName)
    if _G.GFExtensions[scriptName] then
        return _G.GFExtensions[scriptName]
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
    local module = script
    if module then
        for _, name in ipairs(scriptNameList) do
            module = module[name]
            if module == nil then
                print("Can not find scriptNode : "..scriptName)
                break
            end
        end
    end
    if module then
        local m = require(module)
        _G.GFExtensions[scriptName] = m
        return m
    end
end

local Log = GFScript("CoreModule.Log")
local RunService = game:GetService("RunService")

local Extension = {}

Extension.updateList = {}

function Extension:RegisterUpdate(actor)
    table.insert(self.updateList, actor)
end
function Extension:UnRegisterUpdate(actor)
    for k, v in ipairs(self.updateList) do
        if v == actor then
            table.remove(self.updateList, k)
            break
        end
    end
end

--版本号
Extension.version = "1.0.0"
--模块依赖
Extension.moduleNames = {
    "SceneCombatModule",
    --"TowerModule",
}
--已经加载的模块
Extension.modules = {}

--是否已经启动过
Extension.isStartup = false

--更新帧率
Extension.updateRate = 0.0
Extension.curUpdateTime = Extension.updateRate
Extension.laterUpdateRate = 0.0
Extension.curLaterUpdateTime = Extension.laterUpdateRate
Extension.frameNumber = 0
Extension.updateCount = 0
Extension.laterUpdateCount = 0

--根据名称获取其他模块
function Extension:GetModule(name)
    if self.modules[name] then
        return self.modules[name]
    end
    local node = script[name]
    if node then
        -- Log:Debug("Load module successed ["..name.."]")
        local module = require(node)
        if module and not module.isStartup then
            module:Startup()
        end
        if module then
            self.modules[name] = module
        end 
        return module
    end
    return nil
end

--遍历所有模块
function Extension:ForEachModule(func)
    for _, module in pairs(self.modules) do
        func(module)
    end
end


--当更新的时候
function Extension:OnUpdate(dt)
    --更新所有模块
    for _, module in pairs(self.modules) do
        if module.OnUpdate then
            module:OnUpdate(dt)
        end
    end
    for _, actor in ipairs(self.updateList) do
        if actor.OnUpdate then
            actor:OnUpdate(dt)
        end
    end
end
--更新后
function Extension:OnLaterUpdate(dt)
    --更新所有模块
    for _, module in pairs(self.modules) do
        if module.OnLaterUpdate then
            module:OnLaterUpdate(dt)
        end
    end
end

--加载所有模块
function Extension:LoadAllModules()
    for _, moduleName in ipairs(self.moduleNames) do
        local module = self:GetModule(moduleName)
        if module == nil then
            Log:Warn("Load module failed ["..moduleName.."]")
        end
    end
end

--通知所有模块初始化完成
function Extension:NotifyPostInitialization()
    if self.isPostInitialization then
        return
    end
    for _, module in pairs(self.modules) do
        if module.OnPostInitialization then
            module:OnPostInitialization()
        end
    end
    self.isPostInitialization = true

    --收集所有模块的Gm指令
    local GmModule = GameFramework:GetModule("GmModule")
    if GmModule then
        self:ForEachModule(function(module)
            GmModule:CollectGmCommands(module)
        end)
    end
end

--启动
function Extension:Startup()
    if self.isStartup then
        return
    end
    --加载所有模块 
    self:LoadAllModules()
    
    if RunService then
        local updateFunc = function(dt)
            Extension.updateCount = Extension.updateCount + 1
            -- self:OnUpdate(dt)
            --根据更新帧率更新
            if self.updateRate == 0 then
                self:OnUpdate(dt)
            else
                if self.curUpdateTime > 0 then
                    self.curUpdateTime = self.curUpdateTime - dt
                end
                if self.curUpdateTime <= 0 then
                    self.curUpdateTime = self.curUpdateTime + self.updateRate
                    self:OnUpdate(self.updateRate)
                end
            end
        end
        local laterUpdateFunc = function(dt)
            Extension.laterUpdateCount = Extension.laterUpdateCount + 1
            -- self:OnLaterUpdate(dt)
            --根据更新帧率更新
            if self.laterUpdateRate == 0 then
                self:OnLaterUpdate(dt)
            else
                if self.curLaterUpdateTime > 0 then
                    self.curLaterUpdateTime = self.curLaterUpdateTime - dt
                end
                if self.curLaterUpdateTime <= 0 then
                    self.curLaterUpdateTime = self.curLaterUpdateTime + self.laterUpdateRate
                    self:OnLaterUpdate(self.laterUpdateRate)
                end
            end
        end
        RunService:BindToRenderStep("ExtensionFirstUpdate", Enum.RenderPriority.First.Value,
            function(dt)
                Extension.frameNumber = Extension.frameNumber + 1
                updateFunc(dt)
                laterUpdateFunc(dt)
            end)
    end


    self.isStartup = true
end

--设置全局变量
_G.Extension = _G.Extension or Extension

return Extension