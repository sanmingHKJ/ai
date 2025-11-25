--[[
    GlobalExtensions.Services.lua - SGF框架全局服务引用
    位置: framework/shared/GlobalExtensions.Services.lua
    
    功能：
    1. 提供所有游戏引擎服务的统一访问入口
    2. 替代旧的MS全局命名空间
    3. 集成到SGF框架中
    
    Version: 4.0.0 (SGF框架)
    原始版本: xplants/ServiceNodes/MainStorage/Scripts/Global.lua
    
    变更：
    - 移除MS命名空间，使用SGF.Services
    - 移除对旧框架模块的引用
    - 保持所有引擎服务的引用
]]

local GlobalServices = {}

--[[
    初始化全局服务引用
    @param sgf SGF框架实例
]]
function GlobalServices.Initialize(sgf)
    local services = {}
    
    -- 核心引擎服务
    services.RunService = game:GetService("RunService")
    services.Players = game:GetService("Players")
    services.TweenService = game:GetService('TweenService')
    services.WorkSpace = game:GetService("WorkSpace")
    services.Environment = services.WorkSpace.Environment
    services.ServerStorage = game:GetService("ServerStorage")
    services.MainStorage = game:GetService("MainStorage")
    services.ContextActionService = game:GetService("ContextActionService")
    services.UserInputService = game:GetService("UserInputService")
    services.WorldService = game:GetService("WorldService")
    
    -- 云服务
    services.CloudService = game:GetService("CloudService")
    services.CloudServerConfigService = game:GetService('CloudServerConfigService')
    
    -- 商店和社交服务
    services.DeveloperStoreService = game:GetService("DeveloperStoreService")
    services.FriendInviteService = game:GetService("FriendInviteService")
    services.FriendService = game:GetService("FriendsService")
    
    -- UI和交互服务
    services.CoreUi = game:GetService("CoreUi")
    services.StarterGui = game:GetService("StarterGui")
    services.Chat = game:GetService("Chat")
    
    -- 物理和工具服务
    services.PhysXService = game:GetService("PhysXService")
    services.UtilService = game:GetService('UtilService')
    services.MouseService = game:GetService('MouseService')
    
    -- 传送和场景服务
    services.TeleportService = game:GetService("TeleportService")
    services.SceneMgr = game:GetService("SceneMgr")
    
    -- 分析服务
    services.AnalyticsService = game:GetService("AnalyticsService")
    
    -- 平台信息
    services.CUR_PLATFORM = services.Environment:GetDeviceType()
    
    -- 保存到SGF框架
    sgf.gameServices = services
    
    sgf.log:info("GlobalServices: 全局服务初始化完成")
    
    return services
end

--[[
    获取服务引用
    @param sgf SGF框架实例
    @param serviceName 服务名称
]]
function GlobalServices.GetService(sgf, serviceName)
    if not sgf.gameServices then
        sgf.log:error("GlobalServices: 服务未初始化")
        return nil
    end
    
    return sgf.gameServices[serviceName]
end

return GlobalServices

