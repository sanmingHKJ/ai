_G.GFModules = {}
_G.GFScript = function(scriptName)
    if _G.GFModules[scriptName] then
        return _G.GFModules[scriptName]
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
        _G.GFModules[scriptName] = m
        return m
    end
end

local Log = GFScript("CoreModule.Log")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GameFramework = {}

GameFramework.updateList = {}
GameFramework.laterUpdateList = {}

function GameFramework:RegisterUpdate(actor)
    table.insert(self.updateList, actor)
end
function GameFramework:UnRegisterUpdate(actor)
    for k, v in ipairs(self.updateList) do
        if v == actor then
            table.remove(self.updateList, k)
            break
        end
    end
end
function GameFramework:RegisterLaterUpdate(actor)
    table.insert(self.laterUpdateList, actor)
end
function GameFramework:UnRegisterLaterUpdate(actor)
    for k, v in ipairs(self.laterUpdateList) do
        if v == actor then
            table.remove(self.laterUpdateList, k)
            break
        end
    end
end

--版本号
GameFramework.version = "1.0.0"
--模块依赖
-- rpg-gamedemo只加载必需的核心模块
-- 游戏逻辑由SGF业务系统(GameSystems)实现,不需要GameFramework的游戏模块
GameFramework.moduleNames = {
    "CoreModule",      -- 核心模块(TimerManager, Log, Utils等) - 必需
    "NetworkModule",   -- 网络模块 - 必需
    "UIModule",        -- UI模块 - 必需
    -- 以下模块在rpg-gamedemo中不使用,由SGF业务系统替代
    -- "GmModule",     -- GM命令 - 不需要
    -- "ActorModule",  -- Actor管理 - 不需要(GameFramework的Actor系统)
    -- "CombatModule", -- 战斗模块 - 由CombatSystemServer/Client替代
    -- "StatModule",   -- 属性模块 - 由PlayerSystemServer/Client替代
    -- "PetModule",    -- 宠物模块 - rpg-gamedemo不需要宠物系统
    -- "AIModule",     -- AI模块 - 不需要
    -- "AvatarModule", -- 角色模块 - 不需要
    -- "TestModule",   -- 测试模块 - 不需要
}
--已经加载的模块
GameFramework.modules = {}
--日志等级
GameFramework.logLevel = Log.LogLevel.DEBUG
--日志标签
GameFramework.logTag = nil

--是否已经启动过
GameFramework.isStartup = false

--更新帧率
GameFramework.updateRate = 0.0
GameFramework.curUpdateTime = GameFramework.updateRate
GameFramework.laterUpdateRate = 0.0
GameFramework.curLaterUpdateTime = GameFramework.laterUpdateRate
GameFramework.frameNumber = 0
GameFramework.updateCount = 0
GameFramework.laterUpdateCount = 0

--根据名称获取其他模块
function GameFramework:GetModule(name)
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
function GameFramework:ForEachModule(func)
    for _, module in pairs(self.modules) do
        func(module)
    end
end


--当更新的时候
function GameFramework:OnUpdate(dt)
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
function GameFramework:OnLaterUpdate(dt)
    --更新所有模块
    for _, module in pairs(self.modules) do
        if module.OnLaterUpdate then
            module:OnLaterUpdate(dt)
        end
    end
    for _, actor in ipairs(self.laterUpdateList) do
        if actor.OnLaterUpdate then
            actor:OnLaterUpdate(dt)
        end
    end
end
--当玩家添加的时候
function GameFramework:OnPlayerAdded(player)
    for _, module in pairs(self.modules) do
        if module.OnPlayerAdded then
            module:OnPlayerAdded(player)
        end
    end
end
--当玩家移除的时候
function GameFramework:OnPlayerRemoving(player)
    for _, module in pairs(self.modules) do
        if module.OnPlayerRemoving then
            module:OnPlayerRemoving(player)
        end
    end
end

--加载所有模块
function GameFramework:LoadAllModules()
    for _, moduleName in ipairs(self.moduleNames) do
        local module = self:GetModule(moduleName)
        if module == nil then
            Log:Warn("Load module failed ["..moduleName.."]")
        end
    end
end

--通知所有模块初始化完成
function GameFramework:NotifyPostInitialization()
    if self.isPostInitialization then
        return
    end
    for _, module in pairs(self.modules) do
        if module.OnPostInitialization then
            module:OnPostInitialization()
        end
    end
    self.isPostInitialization = true
end

--启动
function GameFramework:Startup()
    if self.isStartup then
        return
    end
    Log:SetLogLevel(self.logLevel)
    Log:SetLogTag(self.logTag)
    --加载所有模块 
    self:LoadAllModules()
    
    if RunService then
        local updateFunc = function(dt)
            GameFramework.updateCount = GameFramework.updateCount + 1
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
            GameFramework.laterUpdateCount = GameFramework.laterUpdateCount + 1
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
        RunService:BindToRenderStep("GameFrameworkFirstUpdate", Enum.RenderPriority.First.Value,
            function(dt)
                GameFramework.frameNumber = GameFramework.frameNumber + 1
                PCall(function()
                    updateFunc(dt)
                end)
                PCall(function()
                    laterUpdateFunc(dt)
                end)
            end)
        RunService:BindToRenderStep("GameFrameworkInputUpdate", Enum.RenderPriority.Input.Value,
            function(dt)
            end)
        RunService:BindToRenderStep("GameFrameworkCameraUpdate", Enum.RenderPriority.Camera.Value,
            function(dt)
            end)
        RunService:BindToRenderStep("GameFrameworkCharacterUpdate", Enum.RenderPriority.Character.Value,
            function(dt)
            end)

        RunService.RenderStepped:Connect(
            function(dt)
            end)
        RunService.Stepped:Connect(
            function()
            end)
    end

    
    --当玩家添加的时候
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    --当玩家移除的时候
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)

    self.isStartup = true
end

--获取游戏设置
function GameFramework:GetGameSetting()
    if not self.gameSetting then
        local ConfigManager = GFScript("CoreModule.ConfigManager")
        self.gameSetting = ConfigManager:GetAllConfigs("GameSettings")
    end
    return self.gameSetting
end

local Network = GFScript("NetworkModule.Network")

--设置全局变量
_G.GameFramework = _G.GameFramework or GameFramework


GameFramework.UsePCall = false
--安全调用
_G.PCall = function(func,actor)
    if GameFramework.UsePCall then
        local function errorHandler(err)
            -- 确保错误信息是字符串
            err = tostring(err)
            -- 生成完整堆栈跟踪
            --local trace = debug.traceback(err, 2)
            
            if not Network:Error(err,actor) then
                print("Lua Error:", err)
            end
            return err
        end
        
        local ok, errmsg = xpcall(func, errorHandler)
        if not ok then
        end
        return ok, errmsg
    end
    func()
end

math.clamp = function(v, minValue, maxValue)
    return math.max(minValue, math.min(v, maxValue))
end

math.lerp = function(a, b, t)
    return a + (b - a) * t
end

--信号定义
_G.Signal = function() end

return GameFramework