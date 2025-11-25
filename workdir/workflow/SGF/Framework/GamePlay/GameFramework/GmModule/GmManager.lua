local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local GmManager = {}

--初始化
function GmManager:Init()
    RegisterComponentFactory(GFScript("GmModule.GmComponent"))

    self.gmCommands = {}
    self.categories = {}
    self.orderedCategories = {}
end

function GmManager:IsOpenGm()
    local gameSetting = GameFramework:GetGameSetting()
    if gameSetting == nil then
        Log:Error("GameSettings not found")
        return false
    end
    if gameSetting.General.gmEnabled and XPlants.Config.IsTestMode then
        return true
    end
    local RunService = game:GetService("RunService")
    if RunService:IsStudio() then
        return true
    end
    return false
end

--更新
function GmManager:Update(dt)

end
-- 注册GM命令
-- @param category 分类名称
-- @param name 命令名称
-- @param desc 命令描述
-- @param callback 命令回调函数
-- @param isServer 是否是服务器命令
function GmManager:RegisterCommand(category, order, name, example, desc, callback, isServer)
    isServer = isServer == nil and true or isServer
    if not self.gmCommands[category] then
        self.gmCommands[category] = {}
    end
    table.insert(self.gmCommands[category], {
        name = name,
        desc = desc,
        example = example,
        callback = callback,
        isServer = isServer
    })

    self:SetCategory(category, order)
end

-- 设置分类顺序
function GmManager:SetCategory(category, order)
    self.categories[category] = order
    local sortedCategories = {}
    
    -- 收集所有分类
    for category, _ in pairs(self.gmCommands) do
        table.insert(sortedCategories, category)
    end
    
    -- 根据order排序分类
    table.sort(sortedCategories, function(a, b)
        local orderA = self.categories[a] or math.huge
        local orderB = self.categories[b] or math.huge
        return orderA < orderB
    end)
    self.orderedCategories = sortedCategories
end

--是否是服务器指令
function GmManager:IsServerCommand(cmdString)
    local args = {}
    for arg in cmdString:gmatch("%S+") do
        --如果arg是number，就转换成number
        if tonumber(arg) then
            table.insert(args, tonumber(arg))
        else
            table.insert(args, arg)
        end
    end
    
    if #args < 1 then
        Log:Warn("GM command is empty")
        return false
    end
    
    local cmdName = args[1]
    table.remove(args, 1)
    for _, commands in pairs(self.gmCommands) do
        for _, command in ipairs(commands) do
            if command.name == cmdName then
                return command.isServer
            end
        end
    end
    return false
end

-- 执行GM命令
-- @param cmdString 完整的命令字符串，格式：命令 参数1 参数2 参数3...
function GmManager:ExecuteCommand(player, cmdString)

    if not self:IsOpenGm() then
        return false
    end
    
    local args = {}
    for arg in cmdString:gmatch("%S+") do
        --如果arg是number，就转换成number
        if tonumber(arg) then
            table.insert(args, tonumber(arg))
        elseif arg == "true" then
            table.insert(args, true)
        elseif arg == "false" then
            table.insert(args, false)
        else
            table.insert(args, arg)
        end
    end
    
    if #args < 1 then
        Log:Warn("GM command is empty")
        return false
    end
    
    local cmdName = args[1]
    table.remove(args, 1)
    
    -- 查找命令
    for _, commands in pairs(self.gmCommands) do
        for _, command in ipairs(commands) do
            if command.name == cmdName then
                local canExecute = false
                if command.isServer and player:IsServer() then
                    canExecute = true
                elseif not command.isServer and not player:IsServer() then
                    canExecute = true
                end
                if canExecute then
                    Log:StartRecordError()
                    local success, result = pcall(command.callback, player, unpack(args))
                    local errorLog = Log:StopRecordError()
                    if errorLog then
                        player:Say(errorLog)
                    end
                    if not success then
                        Log:Error("GM command execution failed: " .. tostring(result))
                        return false
                    end
                    return true
                end
            end
        end
    end
    
    Log:Warn("Unknown GM command: " .. cmdName)
    return false
end

-- 获取所有命令列表
-- @return 按分类排序的命令列表
function GmManager:GetCommandList()
    local result = {}
    
    -- 首先添加有序分类
    for _, category in ipairs(self.orderedCategories) do
        if self.gmCommands[category] then
            result[category] = self.gmCommands[category]
        end
    end
    
    -- 添加未排序的分类
    for category, commands in pairs(self.gmCommands) do
        if not result[category] then
            result[category] = commands
        end
    end
    
    return result
end

--获取分类
function GmManager:GetCategories()
    return self.categories
end

--获取分类顺序
function GmManager:GetOrderedCategories()
    return self.orderedCategories
end

--根据分类获取命令  
function GmManager:GetCommandListByCategory(category)
    local result = {}
    local commands = self.gmCommands[category]
    for _, command in ipairs(commands) do
        table.insert(result, {
            name = command.name,
            example = command.example,
            desc = command.desc,
            isServer = command.isServer
        })
    end
    return result
end


return GmManager