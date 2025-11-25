--[[
    StudioIntegration - Bridge between SGF and Studio engine

    Features:
    - Studio service access and caching
    - Environment detection (server/client)
    - Network node creation and management
    - ServiceNodes integration
    - Platform-specific optimizations
]]

local StudioIntegration = {}
StudioIntegration.__index = StudioIntegration

--[[
    Create a new StudioIntegration instance
    @return StudioIntegration instance
]]
function StudioIntegration.new()
    local self = setmetatable({}, StudioIntegration)

    -- Environment information
    self.isServer = false
    self.isClient = false
    self.isStudio = false

    -- Cached Studio services
    self.services = {}

    -- ServiceNode mapping
    self.serviceNodes = {
        MainStorage = "MainStorage",
        ServerScriptService = "ServerScriptService",
        StartPlayer = "StartPlayer",
        StarterPlayerScripts = "StartPlayer.StarterPlayerScripts",
        StarterGui = "StarterGui",
        ServerStorage = "ServerStorage",
        WorkSpace = "WorkSpace",
        Players = "Players"
    }

    -- Network nodes
    self.networkNodes = {}

    return self
end

--[[
    Initialize Studio integration
]]
function StudioIntegration:init()
    -- Detect environment
    self:detectEnvironment()

    -- Cache essential services
    self:cacheEssentialServices()

    -- Setup network infrastructure if needed
    self:setupNetworkInfrastructure()
end

--[[
    Detect the current Studio environment
]]
function StudioIntegration:detectEnvironment()
    local success, RunService = pcall(game.GetService, game, "RunService")

    if success and RunService then
        self.isServer = RunService:IsServer()
        self.isClient = RunService:IsClient()
        self.isStudio = RunService:IsStudio()

        self.services.RunService = RunService
    else
        -- Fallback detection
        self.isServer = game.ServerScriptService ~= nil
        self.isClient = game.Players.LocalPlayer ~= nil
    end
end

--[[
    Cache essential Studio services
]]
function StudioIntegration:cacheEssentialServices()
    local essentialServices = {
        "RunService",
        "Players",
        "UserInputService",
        "TweenService",
        "SoundService",
        "Lighting",
        "ReplicatedStorage"
    }

    for _, serviceName in ipairs(essentialServices) do
        local success, service = pcall(game.GetService, game, serviceName)
        if success then
            self.services[serviceName] = service
        end
    end

    -- Cache ServiceNode references
    local success, mainStorage = pcall(game.GetService, game, "MainStorage")
    if success then
        self.services.MainStorage = mainStorage
    end

    if self.isServer then
        local serverStorage = pcall(game.GetService, game, "ServerStorage")
        if success then
            self.services.ServerStorage = serverStorage
        end

        local serverScriptService = pcall(game.GetService, game, "ServerScriptService")
        if success then
            self.services.ServerScriptService = serverScriptService
        end
    end
end

--[[
    Get a Studio service (cached)
    @param serviceName (string) Service name
    @return Studio service instance
]]
function StudioIntegration:getService(serviceName)
    -- Return cached service if available
    if self.services[serviceName] then
        return self.services[serviceName]
    end

    -- Try to get service and cache it
    local success, service = pcall(game.GetService, game, serviceName)
    if success then
        self.services[serviceName] = service
        return service
    else
        error("Failed to get Studio service: " .. serviceName)
    end
end

--[[
    Check if a Studio service is available
    @param serviceName (string) Service name
    @return (boolean) True if service is available
]]
function StudioIntegration:hasService(serviceName)
    if self.services[serviceName] then
        return true
    end

    local success, service = pcall(game.GetService, game, serviceName)
    if success and service then
        self.services[serviceName] = service
        return true
    end

    return false
end

--[[
    Setup network infrastructure
]]
function StudioIntegration:setupNetworkInfrastructure()
    -- Create basic network nodes in MainStorage if they don't exist
    local mainStorage = self:getService("MainStorage")
    if not mainStorage then
        return
    end

    -- Check for existing remote event
    local remoteEvent = mainStorage:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        remoteEvent = self:createNetworkNode("RemoteEvent", "RemoteEvent", mainStorage)
    end

    -- Check for existing remote function
    local remoteFunction = mainStorage:FindFirstChild("RemoteFunction")
    if not remoteFunction then
        remoteFunction = self:createNetworkNode("RemoteFunction", "RemoteFunction", mainStorage)
    end

    self.networkNodes.RemoteEvent = remoteEvent
    self.networkNodes.RemoteFunction = remoteFunction
end

--[[
    Create a network node
    @param nodeType (string) Node type ("RemoteEvent", "RemoteFunction", etc.)
    @param name (string) Node name
    @param parent (SandboxNode) Parent instance (optional, defaults to MainStorage)
    @return Network node instance
]]
function StudioIntegration:createNetworkNode(nodeType, name, parent)
    if not self.isServer then
        return
    end

    parent = parent or self:getService("MainStorage")

    local success, node = pcall(function()
        if nodeType == "RemoteEvent" then
            return SandboxNode.new("RemoteEvent")
        elseif nodeType == "RemoteFunction" then
            return SandboxNode.new("RemoteFunction")
        else
            error("Unsupported network node type: " .. nodeType)
        end
    end)

    if success and node then
        node.Name = name
        node.Parent = parent
        return node
    else
        error("Failed to create network node: " .. nodeType)
    end
end

--[[
    Get a network node
    @param name (string) Node name
    @return Network node instance or nil
]]
function StudioIntegration:getNetworkNode(name)
    return self.networkNodes[name]
end

--[[
    Get all cached services
    @return (table) Service cache
]]
function StudioIntegration:getCachedServices()
    return self.services
end

--[[
    Get environment information
    @return (table) Environment info
]]
function StudioIntegration:getEnvironmentInfo()
    return {
        isServer = self.isServer,
        isClient = self.isClient,
        isStudio = self.isStudio,
        platform = self:getPlatform(),
        deviceType = self:getDeviceType()
    }
end

--[[
    Get platform information
    @return (string) Platform name
]]
function StudioIntegration:getPlatform()
    local userInputService = self.services.UserInputService
    if userInputService then
        if userInputService.TouchEnabled then
            return "Mobile"
        elseif userInputService.GamepadEnabled then
            return "Console"
        else
            return "PC"
        end
    end

    return "Unknown"
end

--[[
    Get device type
    @return (string) Device type
]]
function StudioIntegration:getDeviceType()
    -- In Studio engine, this would use WorkSpace.Environment:GetDeviceType()
    local workSpace = self:getService("WorkSpace")
    if workSpace and workSpace.Environment and workSpace.Environment.GetDeviceType then
        local success, deviceType = pcall(workSpace.Environment.GetDeviceType, workSpace.Environment)
        if success then
            return tostring(deviceType)
        end
    end

    return "Unknown"
end

--[[
    Setup player connections (server-side)
]]
function StudioIntegration:setupPlayerConnections()
    if not self.isServer then
        return
    end

    local players = self:getService("Players")
    if not players then
        return
    end

    -- Return connection objects for cleanup
    local connections = {}

    connections.playerAdded = players.PlayerAdded:Connect(function(player)
        -- Emit SGF event
        if _G.SGF and _G.SGF.events then
            _G.SGF.events:emit("PlayerJoined", { player = player })
        end
    end)

    connections.playerRemoving = players.PlayerRemoving:Connect(function(player)
        -- Emit SGF event
        if _G.SGF and _G.SGF.events then
            _G.SGF.events:emit("PlayerLeaving", { player = player })
        end
    end)

    return connections
end

--[[
    Setup input connections (client-side)
]]
function StudioIntegration:setupInputConnections()
    if not self.isClient then
        return
    end

    local userInputService = self:getService("UserInputService")
    if not userInputService then
        return
    end

    local connections = {}

    connections.inputBegan = userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        -- Emit SGF event
        if _G.SGF and _G.SGF.events then
            _G.SGF.events:emit("InputBegan", {
                input = input,
                keyCode = input.KeyCode,
                userInputType = input.UserInputType
            })
        end
    end)

    connections.inputEnded = userInputService.InputEnded:Connect(function(input, processed)
        if processed then return end

        -- Emit SGF event
        if _G.SGF and _G.SGF.events then
            _G.SGF.events:emit("InputEnded", {
                input = input,
                keyCode = input.KeyCode,
                userInputType = input.UserInputType
            })
        end
    end)

    return connections
end

--[[
    Create a tween using Studio's TweenService
    @param instance (SandboxNode) SandboxNode to tween
    @param tweenInfo (table) Tween configuration
    @param properties (table) Properties to tween
    @return Tween object
]]
function StudioIntegration:createTween(instance, tweenInfo, properties)
    local tweenService = self:getService("TweenService")
    if not tweenService then
        error("TweenService not available")
    end

    -- Convert SGF tween info to Studio TweenInfo if needed
    local studioTweenInfo
    if type(tweenInfo) == "table" then
        studioTweenInfo = TweenInfo.new(
            tweenInfo.duration or 1,
            tweenInfo.easingStyle or Enum.EasingStyle.Linear,
            tweenInfo.easingDirection or Enum.EasingDirection.Out,
            tweenInfo.repeatCount or 0,
            tweenInfo.reverses or false,
            tweenInfo.delayTime or 0
        )
    else
        studioTweenInfo = tweenInfo
    end

    return tweenService:Create(instance, studioTweenInfo, properties)
end

--[[
    Play a sound using Studio's SoundService
    @param soundId (string) Sound asset ID
    @param properties (table) Sound properties (optional)
    @return Sound instance
]]
function StudioIntegration:playSound(soundId, properties)
    local soundService = self:getService("SoundService")
    if not soundService then
        error("SoundService not available")
    end

    properties = properties or {}

    local sound = SandboxNode.new("Sound")
    sound.SoundId = soundId
    sound.Volume = properties.volume or 0.5
    sound.Pitch = properties.pitch or 1
    sound.PlaybackSpeed = properties.playbackSpeed or 1

    if properties.parent then
        sound.Parent = properties.parent
    else
        sound.Parent = soundService
    end

    sound:Play()

    -- Auto-cleanup after playing
    if not properties.loop then
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end

    return sound
end

--[[
    Get local player (client-side)
    @return LocalPlayer instance or nil
]]
function StudioIntegration:getLocalPlayer()
    if not self.isClient then
        return nil
    end

    local players = self:getService("Players")
    return players and players.LocalPlayer or nil
end

--[[
    Get all players (server-side)
    @return Array of Player instances
]]
function StudioIntegration:getAllPlayers()
    local players = self:getService("Players")
    if players and players.GetPlayers then
        return players:GetPlayers()
    else
        return {}
    end
end

--[[
    Find player by user ID
    @param userId (number) User ID
    @return Player instance or nil
]]
function StudioIntegration:findPlayerByUserId(userId)
    local players = self:getService("Players")
    if players and players.GetPlayerByUserId then
        local success, player = pcall(players.GetPlayerByUserId, players, userId)
        return success and player or nil
    end
    return nil
end

--[[
    Wait for child with timeout
    @param parent (SandboxNode) Parent instance
    @param childName (string) Child name
    @param timeout (number) Timeout in seconds (optional, defaults to 5)
    @return Child instance or nil
]]
function StudioIntegration:waitForChild(parent, childName, timeout)
    if not parent or not parent.WaitForChild then
        return nil
    end

    timeout = timeout or 5

    local success, child = pcall(parent.WaitForChild, parent, childName, timeout)
    return success and child or nil
end

--[[
    Get Studio integration statistics
    @return (table) Integration statistics
]]
function StudioIntegration:getStats()
    return {
        environment = {
            isServer = self.isServer,
            isClient = self.isClient,
            isStudio = self.isStudio,
            platform = self:getPlatform(),
            deviceType = self:getDeviceType()
        },
        cachedServices = #self:getCachedServiceNames(),
        networkNodes = #self:getNetworkNodeNames()
    }
end

--[[
    Get cached service names
    @return (table) Array of cached service names
]]
function StudioIntegration:getCachedServiceNames()
    local names = {}
    for name, _ in pairs(self.services) do
        table.insert(names, name)
    end
    return names
end

--[[
    Get network node names
    @return (table) Array of network node names
]]
function StudioIntegration:getNetworkNodeNames()
    local names = {}
    for name, _ in pairs(self.networkNodes) do
        table.insert(names, name)
    end
    return names
end

--[[
    Cleanup integration resources
]]
function StudioIntegration:cleanup()
    -- Clear service cache
    self.services = {}

    -- Clear network nodes
    self.networkNodes = {}
end

return StudioIntegration
