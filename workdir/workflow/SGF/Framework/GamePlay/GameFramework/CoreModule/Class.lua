local Class = {}

-- 添加实例统计开关和存储
Class.enableInstanceTracking = false
Class.instanceStats = {}

-- 添加快照存储
Class.snapshots = {}

-- 延迟销毁列表
Class.destroyLaterList = {}

-- 添加debug模式开关
Class.debugMode = false

-- 递归调用构造函数
local function callConstructors(cls, obj, ...)
    if cls.super then
        callConstructors(cls.super, obj, ...)
    end
    local constructor = rawget(cls, "Constructor")
    if constructor then
        constructor(obj, ...)
    end
end

local function callOnConstructors(cls, obj, ...)
    if cls.super then
        callOnConstructors(cls.super, obj, ...)
    end
    local onConstructor = rawget(cls, "OnConstructor")
    if onConstructor then
        onConstructor(obj, ...)
    end
end

-- 递归调用析构函数
local function callDestructors(cls, obj)
    local destructor = rawget(cls, "Destructor")
    if destructor then
        destructor(obj)
    end
    if cls.super then
        callDestructors(cls.super, obj)
    end
end

local function callOnDestructors(cls, obj)
    local onDestructor = rawget(cls, "OnDestructor")
    if onDestructor then
        onDestructor(obj)
    end
    if cls.super then
        callOnDestructors(cls.super, obj)
    end
end

-- 计算哈希名称
local function hashName(className)
    local hash = 0
    for i = 1, #className do
        hash = (hash * 33 + string.byte(className, i)) % 0x7FFFFFFF
    end
    return hash
end

-- 创建已销毁对象的代理元表
local function createDestroyedObjectProxy(obj, destroyStack)
    local proxy = {}
    local className = obj.class and obj.class.__cname or "Unknown"
    local mt = {
        IsExpired = function(t)
            return true
        end,
        __index = function(t, k)
            if Class.debugMode then
                local text = string.format("[ERROR] 访问已销毁对象: %s.%s", className, k)
                text = text .. "\n[ERROR] 对象销毁时的堆栈信息:"
                text = text .. "\n    " .. destroyStack
                text = text .. "\n[ERROR] 当前访问堆栈:"
                text = text .. "\n    " .. debug.traceback(nil,nil,2)
                print(text)
            end
        end,
        __newindex = function(t, k, v)
            if Class.debugMode then
                local text = string.format("[ERROR] 设置已销毁对象: %s.%s", className, k)
                text = text .. "\n[ERROR] 对象销毁时的堆栈信息:"
                text = text .. "\n    " .. destroyStack
                text = text .. "\n[ERROR] 当前访问堆栈:"
                text = text .. "\n    " .. debug.traceback(nil,nil,2)
                print(text)
            end
        end,
        __call = function(t, ...)
            if Class.debugMode then
                local text = string.format("[ERROR] 调用已销毁对象的方法")
                text = text .. "\n[ERROR] 对象销毁时的堆栈信息:"
                text = text .. "\n    " .. destroyStack
                text = text .. "\n[ERROR] 当前访问堆栈:"
                text = text .. "\n    " .. debug.traceback(nil,nil,2)
                print(text)
            end
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- 创建新类
function Class.New(className, parentClass)
    local cls = {}
    cls.__cname = className
    cls.__index = cls

    -- 初始化类的实例计数
    if Class.enableInstanceTracking then
        Class.instanceStats[className] = {
            activeInstances = 0,
            totalCreated = 0
        }
    end

    if parentClass then
        cls.super = parentClass
        setmetatable(cls, { __index = parentClass })
    end

    -- 创建类的实例
    function cls.New(...)
        local obj = setmetatable({}, cls)
        obj.class = cls
        obj.super = cls.super  -- 为实例添加 super 引用

        -- 更新实例统计
        if Class.enableInstanceTracking then
            Class.instanceStats[className].activeInstances = Class.instanceStats[className].activeInstances + 1
            Class.instanceStats[className].totalCreated = Class.instanceStats[className].totalCreated + 1
        end

        callConstructors(cls, obj, ...)
        callOnConstructors(cls, obj, ...)
        return obj
    end

    -- 销毁实例
    function cls.Destroy(obj)
        if obj.__delete__ then
            print("obj is already deleted")
            return
        end

        callOnDestructors(cls, obj)

        -- 更新实例统计
        if Class.enableInstanceTracking then
            Class.instanceStats[className].activeInstances = Class.instanceStats[className].activeInstances - 1
        end

        callDestructors(cls, obj)
        obj.__delete__ = true
        
        -- 在debug模式下，记录销毁信息并创建代理
        if Class.debugMode then
            local destroyStack = debug.traceback(nil,nil,2)
            -- 创建代理对象替换原对象
            local proxy = createDestroyedObjectProxy(obj, destroyStack)
            -- 将原对象的所有引用替换为代理
            for k, v in pairs(obj) do
                obj[k] = nil
            end
            for k, v in pairs(proxy) do
                obj[k] = v
            end
            setmetatable(obj, getmetatable(proxy))
            rawset(obj, "__delete__", true)
        else
            setmetatable(obj, nil)
        end
    end
    
    --延迟销毁
    function cls.DestroyLater(obj)
        if obj.__delete__ then
            print("obj is already deleted")
            return
        end
        if obj.__destroy__later__ then
            print("obj is already destroyed later")
            return
        end
        obj.__destroy__later__ = true
        table.insert(Class.destroyLaterList, obj)
    end
    
    -- 定义派生类
    function cls.Extend(className)
        return Class.New(className, cls)
    end

    -- 获取哈希名称
    function cls.GetHashName()
        if not cls.__hashName then
            cls.__hashName = hashName(cls.__cname)
        end
        return cls.__hashName
    end

    return cls
end

-- 添加实例统计相关的工具函数
function Class.EnableInstanceTracking(enable)
    Class.enableInstanceTracking = enable
    if enable then
        Class.instanceStats = {}
    end
end

function Class.PrintInstanceStats()
    if not Class.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    print("\n=== Class Instance Statistics ===")
    for className, stats in pairs(Class.instanceStats) do
        print(string.format("Class: %s", className))
        print(string.format("  Active instances: %d", stats.activeInstances))
        print(string.format("  Total created: %d", stats.totalCreated))
    end
    print("==============================\n")
end

function Class.IskindofHelper(obj, cls, cls_name)
    if cls.__cname == cls_name then
        return true
    elseif cls.super then
        return Class.IskindofHelper(obj, cls.super, cls_name)
    else
        return false
    end
end

function Class.Iskindof(obj, cls_name)
    return Class.IskindofHelper(obj, obj.class, cls_name)
end

-- 检查类是否是指定类名的子类
function Class.IsSubClassOf(cls, className)
    local currentClass = cls
    while currentClass do
        if currentClass.__cname == className then
            return true
        end
        currentClass = currentClass.super
    end
    return false
end

-- 检查对象是否是指定类名的实例
function Class.InstanceOf(obj, cls)
    return type(obj) == "table" and obj.class == cls
end

function Class.IsExpired(obj)
    return obj.__delete__
end

-- 调用父类方法
function Class.CallSuper(obj, methodName, ...)
    local superClass = obj.super
    while superClass do
        local method = superClass[methodName]
        if method then
            return method(obj, ...)
        end
        superClass = superClass.super
    end
    error("Super method '" .. methodName .. "' not found", 2)
end

-- 创建实例统计快照
function Class.CreateSnapshot(snapshotName)
    if not Class.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    Class.snapshots[snapshotName] = {}
    for className, stats in pairs(Class.instanceStats) do
        Class.snapshots[snapshotName][className] = {
            activeInstances = stats.activeInstances,
            totalCreated = stats.totalCreated
        }
    end
end

-- 比较两个快照并打印增量信息
function Class.PrintSnapshotDiff(oldSnapshotName, newSnapshotName)
    if not Class.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    local oldSnapshot = Class.snapshots[oldSnapshotName]
    local newSnapshot = Class.snapshots[newSnapshotName]
    
    if not oldSnapshot or not newSnapshot then
        print("Snapshot not found")
        return
    end
    
    print(string.format("\n=== Instance Diff: %s -> %s ===", oldSnapshotName, newSnapshotName))
    
    -- 收集所有类名
    local allClasses = {}
    for className, _ in pairs(oldSnapshot) do allClasses[className] = true end
    for className, _ in pairs(newSnapshot) do allClasses[className] = true end
    
    -- 计算并排序增量
    local diffs = {}
    for className, _ in pairs(allClasses) do
        local oldStats = oldSnapshot[className] or {activeInstances = 0, totalCreated = 0}
        local newStats = newSnapshot[className] or {activeInstances = 0, totalCreated = 0}
        
        local instanceDiff = newStats.activeInstances - oldStats.activeInstances
        if instanceDiff ~= 0 then
            table.insert(diffs, {
                className = className,
                diff = instanceDiff
            })
        end
    end
    
    -- 按照差异绝对值降序排序
    table.sort(diffs, function(a, b)
        return math.abs(a.diff) > math.abs(b.diff)
    end)
    
    -- 打印差异
    for _, diff in ipairs(diffs) do
        local sign = diff.diff > 0 and "+" or ""
        print(string.format("  %s: %s%d", diff.className, sign, diff.diff))
    end
    print("==============================\n")
end

--更新
function Class.Update()
    for _, obj in ipairs(Class.destroyLaterList) do
        obj:Destroy()
    end
    Class.destroyLaterList = {}
end

return Class