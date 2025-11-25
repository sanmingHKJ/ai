-- 说明:UI资源
-- 日期:2025年5月8日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UILog = GFScript("UIModule.UILog")
local UIResourceGroup = GFScript("UIModule.UIResourceGroup")

local UIResource = {}

UIResource.groups = {}
--清理资源间隔
UIResource.clearInterval = 60 
--清理资源超时时间
UIResource.clearTimeout = 60

UIResource.asyncGetImageSizeTasks = {}

--初始化
function UIResource:Init()
    self.groups = {}
end

--更新
function UIResource:Update(dt)
    self.clearInterval = self.clearInterval - dt
    if self.clearInterval <= 0 then
        self.clearInterval = 60
        for _, group in pairs(self.groups) do
            group:ClearUnusedResources(self.clearTimeout)
        end
    end

    local now = os.time()
    for id, task in pairs(self.asyncGetImageSizeTasks) do
        if (task.watchObj and UIClass.IsExpired(task.watchObj)) or now > task.timeEnd then
            task.callback(false, task.control, task.originWidth, task.originHeight)
            self.asyncGetImageSizeTasks[id] = nil
        else
            local width = task.control.ResourceSize.X
            local height = task.control.ResourceSize.Y
            if width ~= task.originWidth or height ~= task.originHeight then
                task.callback(true, task.control, width, height)
                self.asyncGetImageSizeTasks[id] = nil
            end
        end
    end
end


--获取资源组
function UIResource:GetGroup(resType)
    if not self.groups[resType] then
        self.groups[resType] = UIResourceGroup.New(resType)
    end
    return self.groups[resType]
end

--加载资源
function UIResource:Load(name, resType, callback)
    local group = self:GetGroup(resType)
    group:LoadResource(name, callback)
end

--卸载资源
function UIResource:Unload(name, resType)
    local group = self:GetGroup(resType)
    group:UnloadResource(name)
end



--异步获取图片大小
function UIResource:AsyncGetImageSize(control, callback, timeout, watchObj)
    local id = control.ID
    local originWidth = control.ResourceSize.X
    local originHeight = control.ResourceSize.Y
    self.asyncGetImageSizeTasks[id] = {
        control = control,
        originWidth = originWidth,
        originHeight = originHeight,
        callback = callback,
        watchObj = watchObj,
        timeEnd = os.time() + (timeout or 3),
    }
end

return UIResource
