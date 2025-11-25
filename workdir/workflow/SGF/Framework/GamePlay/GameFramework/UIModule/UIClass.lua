-- 说明:多态基类
-- 日期:2024年2月20日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UIClass = {}

-- 添加实例统计开关和存储
UIClass.enableInstanceTracking = false
UIClass.instanceStats = {}

-- 添加快照存储
UIClass.snapshots = {}

-- 延迟销毁列表
UIClass.destroyLaterList = {}

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

-- 创建新类
function UIClass.New(className, parentClass)
    local cls = {}
    cls.__cname = className
    cls.__index = cls

    -- 初始化类的实例计数
    if UIClass.enableInstanceTracking then
        UIClass.instanceStats[className] = {
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
        if UIClass.enableInstanceTracking then
            UIClass.instanceStats[className].activeInstances = UIClass.instanceStats[className].activeInstances + 1
            UIClass.instanceStats[className].totalCreated = UIClass.instanceStats[className].totalCreated + 1
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
        if UIClass.enableInstanceTracking then
            UIClass.instanceStats[className].activeInstances = UIClass.instanceStats[className].activeInstances - 1
        end


        callDestructors(cls, obj)
        obj.__delete__ = true
        setmetatable(obj, nil)
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
        table.insert(UIClass.destroyLaterList, obj)
    end
    
    -- 定义派生类
    function cls.Extend(className)
        return UIClass.New(className, cls)
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
function UIClass.EnableInstanceTracking(enable)
    UIClass.enableInstanceTracking = enable
    if enable then
        UIClass.instanceStats = {}
    end
end

function UIClass.PrintInstanceStats()
    if not UIClass.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    print("\n=== UIClass Instance Statistics ===")
    for className, stats in pairs(UIClass.instanceStats) do
        print(string.format("UIClass: %s", className))
        print(string.format("  Active instances: %d", stats.activeInstances))
        print(string.format("  Total created: %d", stats.totalCreated))
    end
    print("==============================\n")
end

function UIClass.IskindofHelper(obj, cls, cls_name)
    if cls.__cname == cls_name then
        return true
    elseif cls.super then
        return UIClass.IskindofHelper(obj, cls.super, cls_name)
    else
        return false
    end
end

function UIClass.Iskindof(obj, cls_name)
    return UIClass.IskindofHelper(obj, obj.class, cls_name)
end

-- 检查类是否是指定类名的子类
function UIClass.IsSubClassOf(cls, className)
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
function UIClass.InstanceOf(obj, cls)
    return type(obj) == "table" and obj.class == cls
end

function UIClass.IsExpired(obj)
    return obj.__delete__
end

-- 调用父类方法
function UIClass.CallSuper(obj, methodName, ...)
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
function UIClass.CreateSnapshot(snapshotName)
    if not UIClass.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    UIClass.snapshots[snapshotName] = {}
    for className, stats in pairs(UIClass.instanceStats) do
        UIClass.snapshots[snapshotName][className] = {
            activeInstances = stats.activeInstances,
            totalCreated = stats.totalCreated
        }
    end
end

-- 比较两个快照并打印增量信息
function UIClass.PrintSnapshotDiff(oldSnapshotName, newSnapshotName)
    if not UIClass.enableInstanceTracking then
        print("Instance tracking is disabled")
        return
    end
    
    local oldSnapshot = UIClass.snapshots[oldSnapshotName]
    local newSnapshot = UIClass.snapshots[newSnapshotName]
    
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
function UIClass.Update()
    for _, obj in ipairs(UIClass.destroyLaterList) do
        obj:Destroy()
    end
    UIClass.destroyLaterList = {}
end

return UIClass