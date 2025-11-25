local Class = GFScript("CoreModule.Class")
local Npc = GFScript("ActorModule.Npc")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local Tween = GFScript("CoreModule.Tween")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local TimerManager = GFScript("CoreModule.TimerManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Debugger = GFScript("CoreModule.Debugger")
local SkillManager = GFScript("SkillModule.SkillManager")
local BuffManager = GFScript("BuffModule.BuffManager")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local CombatDefines = GFScript("CombatModule.CombatDefines")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local MainStorage = game:GetService("MainStorage")


local GNpc = Class.New("GNpc", Npc)

function GNpc:Destructor()
end

function GNpc:InitServer()
    GNpc.super.InitServer(self)
        
    -- 状态改变
    self:OnServerEvent("StateChanged", 
        function(oldState, newState)
            if oldState == ActorDefines.EActorState.Moving and newState == ActorDefines.EActorState.Idle then
                -- Log:Debug("oldState: %s newState: %s",tostring(oldState), tostring(newState))
            end
        end)

    self:OnServerEvent("RemoveBuff", 
        function(buff)
        end)

    self:OnServerEvent("Dead",
        function()
        end)
end

function GNpc:InitClient()
    GNpc.super.InitClient(self)

    --监听自身事件
    self:OnClientEvent("SkillEvent",
        function(skill,event,params)
            local func = self["SkillEvent_"..event]
            if type(func) == "function" then
                func(self, skill, params)
            end
        end)
        
    self:OnClientEvent("BuffEvent",
        function(buff,event,params)
            local func = self["BuffEvent_"..event]
            if type(func) == "function" then
                func(self, buff, params)
            end
        end)

    -- 伤害事件
    self:OnClientEvent("TakeDamage",
        function(damageResult)
            self:TakeDamage(damageResult)
        end)

    -- 获得治疗
    self:OnClientEvent("ReceiveHeal",
        function(healResult)
            self:ReceiveHeal(healResult)
        end)

    -- 状态改变
    self:OnClientEvent("StateChanged",
        function(oldState, newState)
            --  Log:Error("@@@ oldState: %s newState: %s",tostring(oldState), tostring(newState))
            self:OnStateChanged(oldState, newState)
        end)
    -- buff添加事件
    self:OnClientEvent("AddBuff",
        function(buff)
            self:OnAddBuff(buff)
        end)
    -- buff移除事件
    self:OnClientEvent("RemoveBuff",
        function(buff)
            self:OnRemoveBuff(buff)
    end)
    -- buff驱散事件
    self:OnClientEvent("DispelBuff",
        function(buff)
            self:OnDispelBuff(buff)
    end)

    self:SetLoadFinishCallback(function()
        self:OnModelLoadFinish()
    end)
end

--加载完成
function GNpc:LoadFinished()
end

function GNpc:Update(dt)
    GNpc.super.Update(self, dt)
end
--更新
function GNpc:LaterUpdate(dt)
    GNpc.super.LaterUpdate(self, dt)
end
-- 设置模型
function GNpc:SetModel(assetName)
    
    self.bindObj.ModelId = assetName
end

-- 获取GameRoot节点
function GNpc:GetGameRoot()
    local workspace = self.scene:GetWorkspace()
    return workspace.GameRoot
end

--加载完毕
function GNpc:OnModelLoadFinish()
    -- self:PlayAnim("Idle")
end
-- 状态改变
function GNpc:OnStateChanged(oldState, newState)
    -- if not oldState then
    --     oldState = "nil"
    -- end
    -- Log:Debug("GNpc:OnStateChanged::: oldState=="..oldState .. "  newState=="..newState)
    if newState == ActorDefines.EActorState.Idle then
        if oldState == ActorDefines.EActorState.KnockUp2 then
            self:PlayOwnerAnim("KnockUpEnd")
        elseif oldState == ActorDefines.EActorState.KnockDown then
            self:PlayOwnerAnim("Idle")
            self.isGetUp = false
        elseif oldState == ActorDefines.EActorState.Moving then
            self:PlayOwnerAnim("Idle")
        end
    elseif newState == ActorDefines.EActorState.Fall then -- 坠落
        self.isGetUp = false
    elseif newState == ActorDefines.EActorState.KnockDown then -- 击倒
        if oldState == ActorDefines.EActorState.KnockUp2 then
            self:PlayOwnerAnim("KnockUpEnd")
            self.isGetUp = false
        -- else
        --     self:PlayOwnerAnim("KnockUpEnd")
        end
    elseif newState == ActorDefines.EActorState.KnockUp then -- 浮空
        local vel = self:GetCustomState("KnockUpVelocity")
        if vel then
            local knockUpVelocity = Vec3.New(vel.x, vel.y, vel.z)
            local height = knockUpVelocity.y --击飞高度
            knockUpVelocity.y = 0
            local distance = knockUpVelocity:Magnitude() --击飞距离
            -- Log:Error("@@@@@@@@@@@@@@@@@@@@ %d %d", height, distance)
            if oldState == ActorDefines.EActorState.KnockUp2 then
                self:PlayOwnerAnim("KnockUpHit")
            else
                if height >= 300 or distance >= 300 then
                    self:PlayOwnerAnim("KnockUpStartHeavy")
                else
                    self:PlayOwnerAnim("KnockUpStart")
                end
            end
        end
    elseif newState == ActorDefines.EActorState.KnockUp2 then -- 浮空开始下落
        self:PlayOwnerAnim("KnockUpLoop")
    elseif newState == ActorDefines.EActorState.Sleep then
            self:PlayOwnerAnim("Sleep")
    elseif newState == ActorDefines.EActorState.Moving then
            self:PlayOwnerAnim(self:GetDerivedMoveAnim())
            self.AvatarComponent:SetAnimSpeed(self:GetDerivedAnimSpeed())
    elseif newState == ActorDefines.EActorState.Dead then
        self:PlayOwnerAnim("Die")
        self.AvatarComponent:EnablePhysics(false)
    end
end
--获取衍生移动动画
function GNpc:GetDerivedMoveAnim()
    return "Move"
    -- local moveType = self.AvatarComponent:GetMoveType()
    -- if moveType == AvatarDefines.EMoveType.Walk then
    --     return "Walk"
    -- elseif moveType == AvatarDefines.EMoveType.Run then
    --     return "Run"
    -- elseif moveType == AvatarDefines.EMoveType.Sprint then
    --     return "Sprint"
    -- end
    -- return "Run"
end
--获取衍生动画速度
function GNpc:GetDerivedAnimSpeed()
    local moveType = self.AvatarComponent:GetMoveType()
    if moveType == AvatarDefines.EMoveType.Walk then
        return self.AvatarComponent.walkAnimSpeed
    elseif moveType == AvatarDefines.EMoveType.Run then
        return self.AvatarComponent.runAnimSpeed
    elseif moveType == AvatarDefines.EMoveType.Sprint then
        return self.AvatarComponent.sprintAnimSpeed
    end
    return self.AvatarComponent.runAnimSpeed
end

--播放动画
function GNpc:PlayAnim(name, layer, normalized)
    if self.AvatarComponent then
        self.AvatarComponent:PlayAnim(name, layer, normalized)
    end
end

function GNpc:PlayOwnerAnim(name, layer, normalized)
    if self.AvatarComponent then
        self.AvatarComponent:PlayOwnerAnim(name, layer, normalized)
    end
end


-- 伤害事件
function GNpc:TakeDamage(damageResult)
end

-- 获得治疗
function GNpc:ReceiveHeal(healResult)

end

return GNpc