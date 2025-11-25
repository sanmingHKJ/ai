local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local AvatarManager = {}

--初始化
function AvatarManager:Init()
    RegisterComponentFactory(GFScript("AvatarModule.AvatarComponent"))
    RegisterComponentFactory(GFScript("AvatarModule.Movement"))
    RegisterComponentFactory(GFScript("AvatarModule.CameraController"))
    RegisterComponentFactory(GFScript("AvatarModule.PostProcessing"))
    self.cachedAvatarDatas = {}
end

--更新
function AvatarManager:Update(dt)

end

--获取技能
function AvatarManager:GetAvatarData(tid)
    local avatarData = self.cachedAvatarDatas[tid]
    if avatarData then
        return avatarData
    end
    local AvatarData = GFScript("AvatarModule.AvatarData")
    local newAvatarData = AvatarData.New()
    newAvatarData:LoadConfigFromTid(tid)
    self.cachedAvatarDatas[tid] = newAvatarData 
    return newAvatarData
end

--是否存在技能数据
function AvatarManager:HasAvatarData(tid)
    return DataProviderManager:HasData("Avatar",tid)
end

return AvatarManager