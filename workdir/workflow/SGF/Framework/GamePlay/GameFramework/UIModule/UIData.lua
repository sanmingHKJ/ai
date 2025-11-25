-- 说明:UI数据类
-- 日期:2025年1月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")


local UIData = UIClass.New("UIData")

function UIData:Constructor()
    self.data = {}
    self.bindings = {}
    self.bindFormats = {}
    -- 设置元表来监听数据变化
    setmetatable(self, {
        __newindex = function(t, key, value)
            if key ~= "data" and key ~= "bindings" then
                self:_OnSetData(key, value)
            else
                rawset(self, key, value)
            end
        end,
        __index = function(t, key)
            if key ~= "data" and key ~= "bindings" then
                return self.data[key]
            end
            return rawget(self, key)
        end
    })
end
-- 自定义格式化函数
function UIData:CustomFormat(fmt, ...)
    local args = {...}
    local index = 1
    
    return (fmt:gsub("%%([%a%%])", function(pattern)
        if pattern == "%" then
            return "%"
        elseif pattern == "p" then
            -- 处理百分比格式
            local value = tonumber(args[index])
            index = index + 1
            if value then
                return string.format("%.1f%%", value * 100)
            end
            return "0%"
        else
            -- 使用标准的string.format处理其他格式
            local value = args[index]
            index = index + 1
            return string.format("%" .. pattern, value)
        end
    end))
end
-- 设置数据
function UIData:_OnSetData(key, value)
    self.data[key] = value
    local binding = self.bindings[key]
    local format = self.bindFormats[key]
    if format then
        if type(format) == "function" then
            value = format(value)
        elseif type(format) == "string" then
            value = self:CustomFormat(format, value)
        end
    end
    for _, binding in ipairs(binding) do
        local obj, property, isFunction = binding[1], binding[2], binding[3]
        if isFunction then
            obj[property](obj, value)
        else
            obj[property] = value
        end
    end
end

-- 绑定格式化函数
function UIData:BindFormat(key, func)
    self.bindFormats[key] = func
end

-- 绑定数据到UI对象的属性
function UIData:Bind(key, obj, property, isFunction)
    if not self.bindings[key] then
        self.bindings[key] = {}
    end
    table.insert(self.bindings[key], {obj, property, isFunction})
end

-- 解绑数据
function UIData:Unbind(key, obj, property)
    if not self.bindings[key] then return end
    for i, binding in ipairs(self.bindings[key]) do
        if binding[1] == obj and binding[2] == property then
            table.remove(self.bindings[key], i)
            break
        end
    end
end

-- 清理绑定
function UIData:ClearBindings()
    self.bindings = {}
end

return UIData