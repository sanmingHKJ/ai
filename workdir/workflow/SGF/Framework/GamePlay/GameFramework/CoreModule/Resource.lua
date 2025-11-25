local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ResourceGroup = GFScript("CoreModule.ResourceGroup")

local Resource = {}

Resource.groups = {}
--清理资源间隔
Resource.clearInterval = 60 
--清理资源超时时间
Resource.clearTimeout = 60
--初始化
function Resource:Init()
    self.groups = {}
end

--更新
function Resource:Update(dt)
    self.clearInterval = self.clearInterval - dt
    if self.clearInterval <= 0 then
        self.clearInterval = 60
        for _, group in pairs(self.groups) do
            group:ClearUnusedResources(self.clearTimeout)
        end
    end
end


--获取资源组
function Resource:GetGroup(resType)
    if not self.groups[resType] then
        self.groups[resType] = ResourceGroup.New(resType)
    end
    return self.groups[resType]
end

--加载资源
function Resource:Load(name, resType, callback)
    local group = self:GetGroup(resType)
    group:LoadResource(name, callback)
end

--卸载资源
function Resource:Unload(name, resType)
    local group = self:GetGroup(resType)
    group:UnloadResource(name)
end

return Resource
