local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")

local ResourceGroup = Class.New("ResourceGroup")

local resTypeMap = {
    ["Texture"] = Enum.AssetResType.Texture,
    ["Audio"] = Enum.AssetResType.Audio,
    ["Bone"] = Enum.AssetResType.Bone,
    ["Model"] = Enum.AssetResType.Model,
    ["Material"] = Enum.AssetResType.Material,
    ["Particle"] = Enum.AssetResType.Particle,
    ["Cubemap"] = Enum.AssetResType.Cubemap,
    ["Skeleton"] = Enum.AssetResType.Skeleton,
    ["AnimController"] = Enum.AssetResType.AnimController,
    ["AnimClip"] = Enum.AssetResType.AnimClip,
    ["AnimSkClip"] = Enum.AssetResType.AnimSkClip,
    ["Mesh"] = Enum.AssetResType.Mesh,
}

--构造函数
function ResourceGroup:Constructor(resType)
    self.resType = resType
    self.resources = {}
end

--加载资源
function ResourceGroup:LoadResource(name, callback)
    local oldRes = self.resources[name]
    if oldRes then
        if oldRes.state == "loaded" then
            oldRes.useCount = oldRes.useCount + 1
            oldRes.useTime = Utils:GetServerTime()
            callback(true, oldRes)
            return
        else
            oldRes.useCount = oldRes.useCount + 1
            table.insert(oldRes.callbacks, callback)
            return
        end
    end
    local res  = {
        name = name,
        state = "loading",
        loader = nil,
        useCount = 1,
        callbacks = {callback},
        needUnload = false,
        startTime = Utils:GetServerTime(),
        endTime = 0,
        loadTime = 0,
    }
    
    res.loader = SandboxNode.New('AssetContent')
    local listener = nil
    listener = res.loader.LoadFinish:Connect(function(success)
        res.state = "loaded"
        local now = Utils:GetServerTime()
        res.endTime = now
        res.loadTime = now - res.startTime
        if res.needUnload or not success then
            if not success and res.callbacks then
                for _, callback in ipairs(res.callbacks) do
                    callback(false, res)
                end
            end
            self:UnloadResource(name)
        else
            --记录时间
            res.useTime = now
            if res.callbacks then
                for _, callback in ipairs(res.callbacks) do
                    callback(true, res)
                end
            end
            res.callbacks = nil
        end
        listener:Disconnect()
        listener = nil
    end)
    res.loader:Load(resTypeMap[self.resType], name)
    self.resources[name] = res
end

--卸载资源，不卸载，仅减少引用计数
function ResourceGroup:UnloadResource(name)
    local res = self.resources[name]
    if res then
        if res.useCount > 0 then
            res.useCount = res.useCount - 1
            return
        end
    end
end

--强制卸载资源
function ResourceGroup:ForceUnloadResource(name)
    local res = self.resources[name]
    if res then
        if res.state == "loading" then
            res.callbacks = nil
            res.needUnload = true
            return
        end
        res.loader:Destroy()
        self.resources[name] = nil
    end
end

--清理长时间未使用的资源
function ResourceGroup:ClearUnusedResources(timeOut)
    timeOut = timeOut or 60
    local now = Utils:GetServerTime()
    local unloadList = {}   
    for name, res in pairs(self.resources) do
        if res.state == "loaded" and res.useTime < now - timeOut and res.useCount == 0 then
            table.insert(unloadList, name)
        end
    end
    for _, name in ipairs(unloadList) do
        self:ForceUnloadResource(name)
    end
end

return ResourceGroup

