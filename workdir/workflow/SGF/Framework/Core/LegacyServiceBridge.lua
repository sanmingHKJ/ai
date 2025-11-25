--[[
    LegacyServiceBridge - 旧系统桥接服务
    
    目的：提供统一的接口访问旧的XPlants模块
    这是一个过渡方案，用于在迁移到纯SGF4.0架构的过程中保持兼容性
    
    功能：
    - 统一访问旧的XPlants命名空间
    - 提供类型安全的访问方法
    - 记录旧系统的使用情况（用于迁移跟踪）
    - 提供降级和错误处理
    
    ⚠️ 重要说明：
    - 这是一个临时的过渡层
    - 所有使用此服务的代码最终都需要迁移到纯SGF服务
    - 不要在新代码中使用此服务
    
    Version: 1.0.0
    Created: 2025-10-22
    Status: Transitional (will be removed after full migration)
]]

local LegacyServiceBridge = {}
LegacyServiceBridge.__index = LegacyServiceBridge

-- 服务元数据
LegacyServiceBridge.VERSION = "1.0.0"
LegacyServiceBridge.STATUS = "transitional"

--[[
    创建新的LegacyServiceBridge实例
    @param sgf (table) StudioGameFramework实例
    @return LegacyServiceBridge实例
]]
function LegacyServiceBridge.new(sgf)
    local self = setmetatable({}, LegacyServiceBridge)
    
    self.sgf = sgf
    self.xplants = _G.XPlants
    
    -- 使用统计（用于迁移跟踪）
    self.usageStats = {
        totalCalls = 0,
        callsByMethod = {},
        callsBySystem = {},
        lastCallTime = 0
    }
    
    -- 警告标志
    self.warningsEnabled = true
    self.warnedMethods = {}
    
    return self
end

--[[
    初始化服务
]]
function LegacyServiceBridge:init()
    if not self.xplants then
        self.sgf.log:warning("[LegacyServiceBridge] XPlants全局对象不存在，某些功能可能不可用")
    else
        self.sgf.log:info("[LegacyServiceBridge] 已初始化（过渡层）", {
            version = self.VERSION,
            status = self.STATUS
        })
    end
end

--[[
    记录使用情况（内部方法）
    @param methodName (string) 方法名称
    @param systemName (string) 调用系统名称（可选）
]]
function LegacyServiceBridge:_recordUsage(methodName, systemName)
    self.usageStats.totalCalls = self.usageStats.totalCalls + 1
    self.usageStats.callsByMethod[methodName] = (self.usageStats.callsByMethod[methodName] or 0) + 1
    
    if systemName then
        self.usageStats.callsBySystem[systemName] = (self.usageStats.callsBySystem[systemName] or 0) + 1
    end
    
    self.usageStats.lastCallTime = os.time()
    
    -- 首次调用时发出警告
    if self.warningsEnabled and not self.warnedMethods[methodName] then
        self.sgf.log:warning("[LegacyServiceBridge] 使用了旧系统访问方法", {
            method = methodName,
            system = systemName,
            message = "请考虑迁移到纯SGF服务"
        })
        self.warnedMethods[methodName] = true
    end
end

--[[
    检查XPlants是否可用
    @return boolean
]]
function LegacyServiceBridge:isAvailable()
    return self.xplants ~= nil
end

-- ============================================================================
-- 核心服务访问方法
-- ============================================================================

--[[
    获取日志服务
    @return XPlants.Log 或 nil
]]
function LegacyServiceBridge:getLog()
    self:_recordUsage("getLog")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.Log
end

--[[
    获取配置服务
    @return XPlants.Config 或 nil
]]
function LegacyServiceBridge:getConfig()
    self:_recordUsage("getConfig")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.Config
end

--[[
    获取UI配置
    @return XPlants.UIConfig 或 nil
]]
function LegacyServiceBridge:getUIConfig()
    self:_recordUsage("getUIConfig")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.UIConfig
end

--[[
    获取事件系统
    @return XPlants.Events 或 nil
]]
function LegacyServiceBridge:getEvents()
    self:_recordUsage("getEvents")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.Events
end

--[[
    获取事件常量
    @return XPlants.EventConstants 或 nil
]]
function LegacyServiceBridge:getEventConstants()
    self:_recordUsage("getEventConstants")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.EventConstants
end

--[[
    获取远程管理器
    ⚠️ 注意：RemoteManager应该通过sgf.services:get("network")访问
    @return XPlants.RemoteManager 或 nil
]]
function LegacyServiceBridge:getRemoteManager()
    self:_recordUsage("getRemoteManager")
    
    if not self.xplants then
        return nil
    end
    
    -- 特别警告：RemoteManager应该使用SGF的network服务
    if self.warningsEnabled then
        self.sgf.log:warning("[LegacyServiceBridge] 使用了旧的RemoteManager", {
            message = "请迁移到 sgf.services:get('network')"
        })
    end
    
    return self.xplants.RemoteManager
end

--[[
    获取更新管理器
    @return XPlants.UpdateManager 或 nil
]]
function LegacyServiceBridge:getUpdateManager()
    self:_recordUsage("getUpdateManager")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.UpdateManager
end

--[[
    获取JSON工具
    @return XPlants.Json 或 nil
]]
function LegacyServiceBridge:getJson()
    self:_recordUsage("getJson")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.Json
end

--[[
    获取工具模块
    @return XPlants.Util 或 nil
]]
function LegacyServiceBridge:getUtil()
    self:_recordUsage("getUtil")
    
    if not self.xplants then
        return nil
    end
    
    return self.xplants.Util
end

-- ============================================================================
-- 通用旧系统访问方法
-- ============================================================================

--[[
    获取任意旧系统
    @param systemName (string) 系统名称
    @param callerName (string) 调用者名称（可选，用于统计）
    @return 旧系统实例 或 nil
]]
function LegacyServiceBridge:getLegacySystem(systemName, callerName)
    self:_recordUsage("getLegacySystem", callerName)
    
    if not self.xplants then
        self.sgf.log:error("[LegacyServiceBridge] XPlants全局对象不存在")
        return nil
    end
    
    if not systemName or type(systemName) ~= "string" then
        self.sgf.log:error("[LegacyServiceBridge] 无效的系统名称", { systemName = systemName })
        return nil
    end
    
    local system = self.xplants[systemName]
    
    if not system then
        self.sgf.log:warning("[LegacyServiceBridge] 旧系统不存在", {
            systemName = systemName,
            caller = callerName
        })
    end
    
    return system
end

-- ============================================================================
-- 统计和诊断方法
-- ============================================================================

--[[
    获取使用统计
    @return table 使用统计数据
]]
function LegacyServiceBridge:getUsageStats()
    return {
        totalCalls = self.usageStats.totalCalls,
        callsByMethod = self.usageStats.callsByMethod,
        callsBySystem = self.usageStats.callsBySystem,
        lastCallTime = self.usageStats.lastCallTime,
        uniqueMethods = self:_countKeys(self.usageStats.callsByMethod),
        uniqueSystems = self:_countKeys(self.usageStats.callsBySystem)
    }
end

--[[
    打印使用统计报告
]]
function LegacyServiceBridge:printUsageReport()
    local stats = self:getUsageStats()
    
    print("=== LegacyServiceBridge 使用统计 ===")
    print(string.format("总调用次数: %d", stats.totalCalls))
    print(string.format("使用的方法数: %d", stats.uniqueMethods))
    print(string.format("调用的系统数: %d", stats.uniqueSystems))
    print("\n按方法统计:")
    
    for method, count in pairs(stats.callsByMethod) do
        print(string.format("  %s: %d次", method, count))
    end
    
    if stats.uniqueSystems > 0 then
        print("\n按系统统计:")
        for system, count in pairs(stats.callsBySystem) do
            print(string.format("  %s: %d次", system, count))
        end
    end
    
    print("=====================================")
end

--[[
    启用/禁用警告
    @param enabled (boolean) 是否启用警告
]]
function LegacyServiceBridge:setWarningsEnabled(enabled)
    self.warningsEnabled = enabled
end

-- ============================================================================
-- 内部辅助方法
-- ============================================================================

function LegacyServiceBridge:_countKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return LegacyServiceBridge

