--[[
    GameMain.lua - 主游戏逻辑控制器
    负责客机端3D场景交互逻辑控制和系统协调
    Version: 1.0.0
]]

local GameMain = {
    name = "GameMain",
    version = "1.0.0",
    
    -- SGF框架引用
    sgf = nil,
    
    -- 系统逻辑处理器
    systemLogics = {},
    
    -- 3D交互处理器
    interactionHandlers = {},
    
    -- 输入处理器
    inputHandlers = {},
    
    -- 游戏状态
    gameState = "stopped", -- "stopped" | "starting" | "running" | "paused"
    
    -- 玩家引用
    player = nil,
    character = nil,
    
    -- 相机控制
    camera = nil,
    
    -- 输入服务
    inputService = nil,
    
    -- 事件连接
    connections = {},
    
    -- 更新频率控制
    lastUpdateTime = 0,
    updateInterval = 1/60, -- 60 FPS
}

function GameMain.new(sgf)
    local instance = setmetatable({}, {__index = GameMain})
    instance.sgf = sgf
    instance.systemLogics = {}
    instance.interactionHandlers = {}
    instance.inputHandlers = {}
    instance.connections = {}
    instance.gameState = "stopped"
    
    return instance
end

-- 初始化游戏逻辑
function GameMain:init(sgf)
    if self.gameState ~= "stopped" then
        return false
    end
    
    self.sgf = sgf
    
    -- 获取玩家和相机
    local Players = game:GetService("Players")
    local workSpace = game:GetService("WorkSpace")
    self.player = Players.LocalPlayer
    
    if self.player then
        self.character = self.player.Character or self.player.CharacterAdded:Wait()
        self.camera = workSpace.CurrentCamera
    end
    
    -- 获取输入服务
    self.inputService = game:GetService("UserInputService")
    
    -- 初始化输入处理
    self:initializeInputHandling()
    
    -- 初始化3D交互检测
    self:initialize3DInteraction()
    
    self.sgf.log:info("GameMain initialized")
    return true
end

-- 启动游戏逻辑
function GameMain:start()
    if self.gameState ~= "stopped" then
        return false
    end
    
    self.gameState = "starting"
    
    -- 启动更新循环
    self:startUpdateLoop()
    
    -- 启动系统逻辑
    for systemName, logicHandler in pairs(self.systemLogics) do
        if logicHandler.start then
            local success, error = pcall(logicHandler.start, logicHandler)
            if not success then
                self.sgf.log:error("System logic start failed", {
                    system = systemName,
                    error = error
                })
            end
        end
    end
    
    self.gameState = "running"
    self.sgf.log:info("GameMain started")
    
    return true
end

-- 停止游戏逻辑
function GameMain:stop()
    if self.gameState == "stopped" then
        return true
    end
    
    self.gameState = "stopped"
    
    -- 停止系统逻辑
    for systemName, logicHandler in pairs(self.systemLogics) do
        if logicHandler.stop then
            local success, error = pcall(logicHandler.stop, logicHandler)
            if not success then
                self.sgf.log:error("System logic stop failed", {
                    system = systemName,
                    error = error
                })
            end
        end
    end
    
    -- 断开所有连接
    self:disconnectAllEvents()
    
    self.sgf.log:info("GameMain stopped")
    return true
end

-- 游戏逻辑更新
function GameMain:update(dt)
    if self.gameState ~= "running" then
        return
    end
    
    -- 更新系统逻辑
    for systemName, logicHandler in pairs(self.systemLogics) do
        if logicHandler.update then
            local success, error = pcall(logicHandler.update, logicHandler, dt)
            if not success then
                self.sgf.log:error("System logic update failed", {
                    system = systemName,
                    error = error
                })
            end
        end
    end
    
    -- 更新3D交互检测
    self:update3DInteraction(dt)
end

-- 注册系统交互
function GameMain:registerSystemInteraction(systemName, interactionHandler)
    self.interactionHandlers[systemName] = interactionHandler
    self.sgf.log:debug("System interaction registered", {system = systemName})
end

-- 处理玩家输入
function GameMain:onPlayerInput(inputType, data)
    -- 先让输入处理器处理
    for systemName, handler in pairs(self.inputHandlers) do
        if handler(inputType, data) then
            return true -- 输入被处理
        end
    end
    
    -- 然后让系统逻辑处理
    for systemName, logicHandler in pairs(self.systemLogics) do
        if logicHandler.onPlayerInput then
            local handled = logicHandler:onPlayerInput(inputType, data)
            if handled then
                return true
            end
        end
    end
    
    return false
end

function GameMain:update3DInteraction(dt)

end

-- 处理3D交互
function GameMain:on3DInteraction(objectId, interactionType)
    -- 分发给相关的系统处理器
    for systemName, handler in pairs(self.interactionHandlers) do
        local success, handled = pcall(handler, objectId, interactionType)
        if success and handled then
            self.sgf.log:debug("3D interaction handled", {
                system = systemName,
                object = objectId,
                interaction = interactionType
            })
            return true
        end
    end
    
    return false
end

-- 初始化输入处理
function GameMain:initializeInputHandling()
    if not self.inputService then
        return
    end
    
    -- 键盘输入
    local keyConnection = self.inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local inputType = "key"
        local data = {
            keyCode = input.KeyCode,
            userInputType = input.UserInputType
        }
        
        self:onPlayerInput(inputType, data)
    end)
    table.insert(self.connections, keyConnection)
    
    -- 鼠标输入
    local mouseConnection = self.inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local inputType = "mouse"
            local data = {
                button = "left",
                position = input.Position
            }
            
            self:onPlayerInput(inputType, data)
        end
    end)
    table.insert(self.connections, mouseConnection)
end

-- 初始化3D交互检测
function GameMain:initialize3DInteraction()
    if not self.inputService then
        return
    end
    
    -- 鼠标点击检测
    local clickConnection = self.inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:detectClickInteraction(input.Position)
        end
    end)
    table.insert(self.connections, clickConnection)
    
    -- 鼠标悬停检测
    local hoverConnection = self.inputService.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self:detectHoverInteraction(input.Position)
        end
    end)
    table.insert(self.connections, hoverConnection)
end

-- 检测点击交互
function GameMain:detectClickInteraction(screenPosition)
    local camera = self.camera
    if not camera then return end
    
    local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {self.character}
    
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.SandboxNode
        local objectId = self:getObjectId(hitPart)
        
        if objectId then
            self:on3DInteraction(objectId, "click")
        end
    end
end

-- 检测悬停交互
function GameMain:detectHoverInteraction(screenPosition)
    local camera = self.camera
    if not camera then return end
    
    local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {self.character}
    
    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    
    local objectId = nil
    if raycastResult then
        local hitPart = raycastResult.SandboxNode
        objectId = self:getObjectId(hitPart)
    end
    
    -- 处理悬停状态变化
    if objectId ~= self.lastHoveredObject then
        if self.lastHoveredObject then
            self:on3DInteraction(self.lastHoveredObject, "leave")
        end
        
        if objectId then
            self:on3DInteraction(objectId, "hover")
        end
        
        self.lastHoveredObject = objectId
    end
end

-- 获取对象ID
function GameMain:getObjectId(part)
    if not part then return nil end
    
    -- 检查部件是否有交互标识
    local objectValue = part:FindFirstChild("ObjectId")
    if objectValue and objectValue:IsA("StringValue") then
        return objectValue.Value
    end
    
    -- 检查父级模型
    local model = part.Parent
    if model and model:IsA("Model") then
        local modelObjectValue = model:FindFirstChild("ObjectId")
        if modelObjectValue and modelObjectValue:IsA("StringValue") then
            return modelObjectValue.Value
        end
        
        -- 使用模型名称作为ID
        return model.Name
    end
    
    -- 使用部件名称作为ID
    return part.Name
end

-- 启动更新循环
function GameMain:startUpdateLoop()
    local RunService = game:GetService("RunService")
    
    local updateConnection = RunService.RenderStepped:Connect(function()
        local currentTime = os.time()
        local dt = currentTime - self.lastUpdateTime
        
        if dt >= self.updateInterval then
            self:update(dt)
            self.lastUpdateTime = currentTime
        end
    end)
    
    table.insert(self.connections, updateConnection)
end

-- 断开所有事件连接
function GameMain:disconnectAllEvents()
    for _, connection in ipairs(self.connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    self.connections = {}
end

-- 获取游戏状态
function GameMain:getState()
    return self.gameState
end

-- 获取统计信息
function GameMain:getStats()
    return {
        gameState = self.gameState,
        systemLogicCount = self:getTableSize(self.systemLogics),
        interactionHandlerCount = self:getTableSize(self.interactionHandlers),
        inputHandlerCount = self:getTableSize(self.inputHandlers),
        connectionCount = #self.connections,
        lastUpdateTime = self.lastUpdateTime
    }
end

-- 获取表大小
function GameMain:getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return GameMain
