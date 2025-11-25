--[[
    特效
    Date: 2025年6月7日
    Author: 揭育龙
    Copyright (c) 2025 迷你创想. All rights reserved.
]]

local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")

local Effect = Class.New("Effect")
local EffectManager = nil

function Effect:Constructor()
    self.id = 0
    self.bindObj = nil
    self.once = false

    if not EffectManager then
        EffectManager = GFScript("CoreModule.Effect.EffectManager")
    end

    self.playCount = 0
    self.visible = true
    self.looping = false
    self.assetId = nil
end

function Effect:Destructor()
    if self.bindObj then
        self.bindObj:Destroy()
        self.bindObj = nil
    end
    self.sharedObject = nil
end

-- 设置ID
function Effect:SetId(id)
    self.id = id
end

-- 获取ID
function Effect:GetId()
    return self.id
end

-- 初始化
function Effect:Init(assetId)
    if not self.bindObj then
        self.bindObj = SandboxNode.New("EffectObject")
        self.bindObj.Name = "EffectObject"
        self.bindObj.Looping = false
        self.bindObj.LocalPosition = Vector3.New(0, 0, 0) 
        self.bindObj.LocalScale = Vector3.New(1.0, 1.0, 1.0)
        self.bindObj.LocalEuler = Vector3.New(0, 0, 0)
        self.bindObj.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        self.bindObj.ResourceLoadMode = Enum.ResourceLoadMode.Default
    end
    self:SetAssetID(assetId)
    self:SetPosition(Vec3.New(0, 0, 0))
    self:SetScale(Vec3.New(1, 1, 1))
    self:SetRotation(Quat.euler(0, 0, 0))
    local listener = nil
    listener = self.bindObj.StopPlaying:Connect(function()
        listener:disconnect()
        listener = nil
        if self.once then
            EffectManager:RecycleEffect(self)
        end
    end)
end

--从缓存池分配出来时
function Effect:OnAllocate()
    self:SetVisible(true)
end

--从缓存池回收时
function Effect:OnRecycle()
    self:SetVisible(false)
    self:Stop()
end

-- 播放
function Effect:Play(once)
    self.once = once
    if self.playCount == 0 then
        self.bindObj:Start()
    else
        self.bindObj:ReStart()
    end

    self.playCount = self.playCount + 1

    self:SetLooping(not once)

end

-- 停止
function Effect:Stop()
    self.bindObj:Stop(0)
end

-- 暂停
function Effect:Pause()
    self.bindObj:Pause()
end

-- 恢复
function Effect:Resume()
    self.bindObj:Start()
end

-- 重放
function Effect:Replay()
    self.bindObj:ReStart()
end 

--设置存活时间
function Effect:SetLifeTime(lifeTime)
    self.lifeTime = lifeTime
    self.lifeTimeEnd = Utils:GetServerTime() + lifeTime
end

--设置位置
function Effect:SetPosition(position)
    self.position = position
    self:_UpdatePosition()
end

-- 设置缩放
function Effect:SetScale(scale)
    self.scale = scale
    self:_UpdateScale()
end

-- 设置旋转
function Effect:SetRotation(quat)
    self.rotation = quat
    self:_UpdateRotation()
end

function Effect:SetVisible(visible)
    self.visible = visible
    self:_UpdateVisible()
end

function Effect:_UpdatePosition()
    if self.position then
        self.bindObj.LocalPosition = Vector3.New(self.position.x, self.position.y, self.position.z)
    end
end

function Effect:_UpdateScale()
    if self.scale then
        self.bindObj.LocalScale = Vector3.New(self.scale.x, self.scale.y, self.scale.z)
    end
end

function Effect:_UpdateRotation()
    if self.rotation then
        self.bindObj.Rotation = Quaternion.New(self.rotation.x, self.rotation.y, self.rotation.z, self.rotation.w)
    end
end

function Effect:_UpdateVisible()
    self.bindObj.Visible = self.visible
end

--设置是否循环
function Effect:SetLooping(looping)
    self.looping = looping
    self:_UpdateLooping()
end


function Effect:_UpdateLooping()
    self.bindObj.Looping = self.looping
end

--设置父节点
function Effect:SetParent(parent)
    self.bindObj.Parent = parent
    self:_UpdatePosition()
    self:_UpdateScale()
    self:_UpdateRotation()
end

-- 设置资源ID
function Effect:SetAssetID(assetId)
    self.assetId = assetId
    self.bindObj:SetAssetID(assetId, function()
        self:_UpdateLooping()
    end)
end

-- 获取资源ID
function Effect:GetAssetID()
    return self.assetId
end

-- 是否死亡
function Effect:IsDead()
    if self.lifeTimeEnd and self.lifeTimeEnd < Utils:GetServerTime() then
        return true
    end
    if self.sharedObject then
        if self.sharedObject.IsDead and self.sharedObject:IsDead() then
            self.sharedObject = nil
            return true
        elseif self.sharedObject.__delete__ then
            self.sharedObject = nil
            return true
        end
    end
    return false
end

--设置共生对象
function Effect:SetSharedObject(sharedObject)
    self.sharedObject = sharedObject
end

--获取共生对象
function Effect:GetSharedObject()
    return self.sharedObject
end
return Effect