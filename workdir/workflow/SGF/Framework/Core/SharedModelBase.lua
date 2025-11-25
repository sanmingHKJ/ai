--[[
    SharedModelBase.lua - 共享模型基类
    提供主客机复用的数据结构基类和通用业务算法
    Version: 1.0.0
]]

local SharedModelBase = {
    name = "SharedModelBase",
    version = "1.0.0",
    schema = {},
    
    -- 数据存储
    data = {},
    
    -- 验证规则
    validationRules = {},
    
    -- 计算缓存
    calculationCache = {},
}

-- 创建模型实例
function SharedModelBase.new(initialData)
    local instance = setmetatable({}, {__index = SharedModelBase})
    instance.data = initialData or {}
    instance.calculationCache = {}
    
    -- 验证初始数据
    local valid, error = instance:validate(instance.data)
    if not valid then
        error("Invalid initial data: " .. error)
    end
    
    return instance
end

-- 获取数据
function SharedModelBase:getData()
    return self.data
end

-- 设置数据
function SharedModelBase:setData(data)
    if not data then
        return false
    end
    
    -- 验证数据
    local valid, error = self:validate(data)
    if not valid then
        return false, error
    end
    
    self.data = data
    self:clearCalculationCache()
    return true
end

-- 更新数据
function SharedModelBase:updateData(updates)
    if not updates then
        return false
    end
    
    -- 创建新数据副本
    local newData = {}
    for k, v in pairs(self.data) do
        newData[k] = v
    end
    
    -- 应用更新
    for k, v in pairs(updates) do
        newData[k] = v
    end
    
    -- 验证新数据
    local valid, error = self:validate(newData)
    if not valid then
        return false, error
    end
    
    self.data = newData
    self:clearCalculationCache()
    return true
end

-- 序列化数据
function SharedModelBase:serialize()
    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONEncode(self.data)
    end)
    
    if success then
        return result
    else
        -- 简单序列化备选方案
        return self:simpleSerialize(self.data)
    end
end

-- 反序列化数据
function SharedModelBase:deserialize(serializedData)
    if not serializedData then
        return false
    end
    
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(serializedData)
    end)
    
    if not success then
        -- 尝试简单反序列化
        data = self:simpleDeserialize(serializedData)
    end
    
    if data then
        local valid, error = self:validate(data)
        if valid then
            self.data = data
            self:clearCalculationCache()
            return true
        else
            return false, error
        end
    end
    
    return false, "Failed to deserialize data"
end

-- 验证数据
function SharedModelBase:validate(data)
    if not data then
        return false, "Data cannot be nil"
    end
    
    -- 检查必需字段
    if self.schema then
        for field, fieldType in pairs(self.schema) do
            if data[field] == nil then
                return false, "Missing required field: " .. field
            end
            
            -- 类型检查
            local actualType = type(data[field])
            if fieldType ~= "any" and actualType ~= fieldType then
                return false, string.format("Field %s expected %s, got %s", field, fieldType, actualType)
            end
        end
    end
    
    -- 自定义验证规则
    if self.validationRules then
        for _, rule in ipairs(self.validationRules) do
            local valid, error = rule(data)
            if not valid then
                return false, error
            end
        end
    end
    
    return true, ""
end

-- 通用计算接口
function SharedModelBase:calculate(operation, params)
    params = params or {}
    
    -- 检查缓存
    local cacheKey = operation .. "_" .. self:hashParams(params)
    if self.calculationCache[cacheKey] then
        return self.calculationCache[cacheKey]
    end
    
    local result = nil
    
    -- 基础计算操作
    if operation == "sum" then
        result = self:calculateSum(params)
    elseif operation == "average" then
        result = self:calculateAverage(params)
    elseif operation == "count" then
        result = self:calculateCount(params)
    elseif operation == "max" then
        result = self:calculateMax(params)
    elseif operation == "min" then
        result = self:calculateMin(params)
    else
        -- 调用自定义计算方法
        local methodName = "calculate" .. operation:sub(1,1):upper() .. operation:sub(2)
        if self[methodName] then
            result = self[methodName](self, params)
        end
    end
    
    -- 缓存结果
    if result ~= nil then
        self.calculationCache[cacheKey] = result
    end
    
    return result
end

-- 计算总和
function SharedModelBase:calculateSum(params)
    local field = params.field
    if not field or not self.data[field] then
        return 0
    end
    
    local value = self.data[field]
    if type(value) == "number" then
        return value
    elseif type(value) == "table" then
        local sum = 0
        for _, v in pairs(value) do
            if type(v) == "number" then
                sum = sum + v
            end
        end
        return sum
    end
    
    return 0
end

-- 计算平均值
function SharedModelBase:calculateAverage(params)
    local sum = self:calculateSum(params)
    local count = self:calculateCount(params)
    return count > 0 and sum / count or 0
end

-- 计算数量
function SharedModelBase:calculateCount(params)
    local field = params.field
    if not field then
        return 0
    end
    
    local value = self.data[field]
    if type(value) == "table" then
        local count = 0
        for _ in pairs(value) do
            count = count + 1
        end
        return count
    elseif value ~= nil then
        return 1
    end
    
    return 0
end

-- 计算最大值
function SharedModelBase:calculateMax(params)
    local field = params.field
    if not field or not self.data[field] then
        return nil
    end
    
    local value = self.data[field]
    if type(value) == "number" then
        return value
    elseif type(value) == "table" then
        local max = nil
        for _, v in pairs(value) do
            if type(v) == "number" then
                if max == nil or v > max then
                    max = v
                end
            end
        end
        return max
    end
    
    return nil
end

-- 计算最小值
function SharedModelBase:calculateMin(params)
    local field = params.field
    if not field or not self.data[field] then
        return nil
    end
    
    local value = self.data[field]
    if type(value) == "number" then
        return value
    elseif type(value) == "table" then
        local min = nil
        for _, v in pairs(value) do
            if type(v) == "number" then
                if min == nil or v < min then
                    min = v
                end
            end
        end
        return min
    end
    
    return nil
end

-- 清除计算缓存
function SharedModelBase:clearCalculationCache()
    self.calculationCache = {}
end

-- 参数哈希
function SharedModelBase:hashParams(params)
    local keys = {}
    for k in pairs(params) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    local hash = ""
    for _, k in ipairs(keys) do
        hash = hash .. k .. ":" .. tostring(params[k]) .. ";"
    end
    
    return hash
end

-- 简单序列化（备选方案）
function SharedModelBase:simpleSerialize(data)
    local function serialize(obj, depth)
        depth = depth or 0
        if depth > 10 then -- 防止无限递归
            return "nil"
        end
        
        local objType = type(obj)
        if objType == "nil" then
            return "nil"
        elseif objType == "boolean" then
            return tostring(obj)
        elseif objType == "number" then
            return tostring(obj)
        elseif objType == "string" then
            return string.format("%q", obj)
        elseif objType == "table" then
            local parts = {}
            table.insert(parts, "{")
            for k, v in pairs(obj) do
                local key = serialize(k, depth + 1)
                local value = serialize(v, depth + 1)
                table.insert(parts, "[" .. key .. "]=" .. value .. ",")
            end
            table.insert(parts, "}")
            return table.concat(parts)
        else
            return "nil"
        end
    end
    
    return serialize(data)
end

-- 简单反序列化（备选方案）
function SharedModelBase:simpleDeserialize(serializedData)
    local success, result = pcall(loadstring, "return " .. serializedData)
    if success and result then
        local success2, data = pcall(result)
        if success2 then
            return data
        end
    end
    return nil
end

-- 克隆数据
function SharedModelBase:clone()
    local clonedData = self:deepCopy(self.data)
    return self.new(clonedData)
end

-- 深拷贝
function SharedModelBase:deepCopy(obj)
    if type(obj) ~= "table" then
        return obj
    end
    
    local copy = {}
    for k, v in pairs(obj) do
        copy[self:deepCopy(k)] = self:deepCopy(v)
    end
    
    return copy
end

return SharedModelBase
