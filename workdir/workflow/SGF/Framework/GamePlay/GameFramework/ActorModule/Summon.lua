local Class = GFScript("CoreModule.Class")
local Npc = GFScript("ActorModule.Npc")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")

--召唤物
local Summon = Class.New("Summon", Npc)

function Summon:SetCollideTag(tag, boundSize)
    self.collideBoundSize = boundSize

    local character = self:GetCharacter()
    if character ~= nil then
        local collideBox = character:FindFirstChild("CollideBox")
        if collideBox ~= nil then
            collideBox.Tag = tag
            if boundSize ~= nil then
                collideBox.Size = Vector3.New(boundSize.x, boundSize.y, boundSize.z)
            end            
        end
    end
end

--获取半径
function Summon:GetRadius()
    local boundSize = self.collideBoundSize
    if boundSize ~= nil then
        return math.max(boundSize.z, math.max(boundSize.x, boundSize.y)) * 0.5
    end
    return Summon.super.GetRadius(self)
end

function Summon:InitServer()
    Summon.super.InitServer(self)
    --加上持续时间
    self.duration = self.duration or 0
    --过去的时间
    self.elapsed = 0
    --监听自身事件
    self:OnServerEvent("ApplyDamage",
        function(damageData)
            local master = self:GetMaster()
            if master then
                master:FireServer("ApplyDamage", damageData)
            end
        end)
        
    self:OnServerEvent("CauseDamage",
    function(damageResult)
        local master = self:GetMaster()
        if master then
            master:FireServer("CauseDamage", damageResult)
        end
    end)
    self:OnServerEvent("Kill",
        function(target) 
            local master = self:GetMaster()
            if master then
                master:FireServer("Kill", target)
            end
        end)
end

function Summon:Update(dt)
    Summon.super.Update(self, dt)
    
end

--更新客户端
function Summon:UpdateServer(dt)
    Summon.super.UpdateServer(self, dt)

    if self.duration > 0 then
        self.elapsed = self.elapsed + dt
        if self.elapsed >= self.duration then
            self.actorManager:ServerDestroyActor(self)
        end
    end
end

--设置持续时间
function Summon:SetDuration(duration)
    self.duration = duration
    self.elapsed = 0
end

--获取剩余时间
function Summon:Remaining()
    return self.duration - self.elapsed
end

-- 销毁
function Summon:Destory()
    self.actorManager:ServerDestroyActor(self)
end

return Summon