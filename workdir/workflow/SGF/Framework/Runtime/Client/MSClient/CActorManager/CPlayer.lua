-- 玩家控制类
local Class = GFScript("CoreModule.Class")
local Player = GFScript("ActorModule.Player")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local TimerManager = GFScript("CoreModule.TimerManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local ActorManager = GFScript("ActorModule.ActorManager")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local SkillManager = GFScript("SkillModule.SkillManager")
local BuffManager = GFScript("BuffModule.BuffManager")
local CombatDefines = GFScript("CombatModule.CombatDefines")
local Tween = GFScript("CoreModule.Tween")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local Debugger = GFScript("CoreModule.Debugger")
local WeatherManager = GFScript("ActorModule.Weather.WeatherManager")
local SkillEventHandler = GFScript("SkillModule.SkillEventHandler")
local MainStorage = game:GetService("MainStorage")
local CPlayer = Class.New("CPlayer", Player)
local UIManager = GFScript("UIModule.UIManager")
local AnimComp = require(script.AnimComp)
local MoveCtrlComp = require(script.MoveCtrlComp)
local Cloner = require(script.Cloner)
local ActorHelper = require(MainStorage.Framework.GamePlay.ActorHelper)

function CPlayer:Constructor()
end

function CPlayer:Destructor()
    MS.NetworkHelper:UnregisterNetObj(self)
end

function CPlayer:InitClient()
    MS.NetworkHelper:RegisterNetObj(self)
    CPlayer.super.InitClient(self)
    
    self.node = self:GetCharacter()
    -- self.moveCtrlComp = MoveCtrlComp.New(self) -- 角色移动控制

    
    self:OnClientEvent("PetLevelChanged",
        function(petId, oldLevel, newLevel)
            local pet = self.PetComponent:GetPetById(petId)
            if pet then
                Log:Error("@@@@@ PetLevelChanged, petId = %d, oldLevel = %d, newLevel = %d", petId, oldLevel, newLevel)
            end
        end)
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
    
    self:OnClientEvent("Kill", 
        function(target)
            SoundManager:PlaySound("UI", "sandboxId://FK_AUD/Weapon/Rifle/kill.mp3", {volume = 1.0})
        end)

    -- 死亡
    self:OnClientEvent("Dead", 
        function()
        end)

    -- 击杀者
    self:OnClientEvent("KilledBy", 
        function(causer)
        end)
    
    -- 复活
    self:OnClientEvent("Revive",
        function()
        end)

    --造成伤害
    self:OnClientEvent("CauseDamage",
        function(damageResult)
            SoundManager:PlaySound("UI", "sandboxId://FK_AUD/Weapon/Rifle/Gun_hit.mp3", {volume = 1.0})
            self:CauseDamage(damageResult)
        end)

    -- 承受伤害
    self:OnClientEvent("TakeDamage",
        function(damageResult)
            SoundManager:PlaySound("UI", "sandboxId://FK_AUD/Weapon/Rifle/Gun_hit.mp3", {volume = 1.0})
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
            self:OnStateChanged(oldState, newState)
        end)
    --目标改变
    self:OnClientEvent("TargetChanged",
        function(oldTarget, newTarget)
        end)
    self:OnClientEvent("TargetLocked",
        function(target)
        end)
    -- 属性改变
    self:OnClientEvent("StatChanged",
        function(statName, oldValue, newValue)
            self:OnStatChanged(statName, oldValue, newValue)
        end)
    self:OnClientEvent("SkillCoolDown",
        function(skill)
        end)
    self:OnClientEvent("AngerChanged",
        function(oldValue, newValue)
            
        end)
    self:OnClientEvent("StaminaChanged",
        function(oldValue, newValue)
        end)
    self:OnClientEvent("HealthChanged",
        function(oldValue, newValue)   
        end)
    -- buff添加事件
    self:OnClientEvent("AddBuff",
        function(buff)
        end)
    -- buff移除事件
    self:OnClientEvent("RemoveBuff",
        function(buff)
        end)
    -- buff驱散事件
    self:OnClientEvent("DispelBuff",
        function(buff)
            self:OnDispelBuff(buff)
        end)
    
    self:OnClientEvent("AnimInitFinished", 
        function()
        end)

    self:OnClientEvent("AvatarLoadFinished", 
        function()
            local mainLobbyModule = UIManager:GetView("MainLobbyModule")
            if mainLobbyModule then
                mainLobbyModule:ListenWeaponEvents()
            end
        end)

    --蓄力
    self:OnClientEvent("SkillChargeStart", 
        function(skill, chargeLevel, chargeValue)
        end)

    self:OnClientEvent("SkillChargeLevelChanged", 
        function(skill, chargeLevel)
        end)

    self:OnClientEvent("SkillChargeEnd", 
        function(skill)
        end)

    self:OnClientEvent("EnterTrigger", 
        function(trigger)

        end)

    self:OnClientEvent("LeaveTrigger",
        function(trigger)
        end)
end

--启动客户端
function CPlayer:OnStartClient()
    if self:IsLocalPlayer() then
        self:InitLocalUI()
    end
end
--初始化本地UI
function CPlayer:InitLocalUI()
   
end
--反初始化本地UI
function CPlayer:FinitLocalUI()
    
end
--加载数据完毕
function CPlayer:LoadFinished()

    self:SetModel()
    
    -- 调试信息：玩家加载完成
    local playerId = self:GetPlayerId()
    local playerName = self.node and self.node.Name or "Unknown"
    local playerType = self:IsLocalPlayer() and "本地玩家" or "其他玩家"
    print("[DEBUG] 玩家加载完成 - " .. playerType .. ": " .. playerId .. " (" .. playerName .. ")")

    if self:IsLocalPlayer() then
        -- 绑定移动状态
        -- self.moveCtrlComp:BindContextActions()
        -- 初始化时更新缓存的瞄准镜配置值
        --self:UpdateCachedScopeConfig()
    end

    

    CPlayer.super.LoadFinished(self)
end

function CPlayer:Update(dt)
    CPlayer.super.Update(self, dt)

    if self:IsLocalPlayer() then
        -- self.moveCtrlComp:Update()

    end
    
end

--更新客户端
function CPlayer:UpdateClient(dt)
    CPlayer.super.UpdateClient(self, dt)
end

function CPlayer:Reset()
end

-- 设置模型
function CPlayer:SetModel(modelId)
    if self.AvatarComponent == nil or self.AvatarComponent:GetActor() == nil then
        return
    end
end


--播放动画
function CPlayer:PlayAnim(name, layer, normalized)
    if self.AvatarComponent then
        self.AvatarComponent:PlayAnim(name, layer, normalized)
    end
end

function CPlayer:PlayOwnerAnim(name, layer, normalized)
    if self.AvatarComponent then
        self.AvatarComponent:PlayOwnerAnim(name, layer, normalized)
    end
end

-- 状态改变
function CPlayer:OnStateChanged(oldState, newState)
    -- if not oldState then
    --     oldState = "nil"
    -- end
    -- Log:Error("PlayerControl:OnStateChanged::: oldState=="..oldState .. "  newState=="..newState .. "  UserId==".. self:GetPlayerId().. "  Name=="..self.node.Name)

    -- if newState == ActorDefines.EActorState.Idle then
    --     self:PlayOwnerAnim("Idle")
    -- elseif newState == ActorDefines.EActorState.Moving then -- 移动
    --     self:PlayOwnerAnim("Run")
    -- elseif newState == ActorDefines.EActorState.Jump then -- 跳跃
    -- elseif newState == ActorDefines.EActorState.NearDeath then --濒临死亡
    -- elseif newState == ActorDefines.EActorState.Dead then -- 死亡
    -- end
end

-- 属性改变
function CPlayer:OnStatChanged(statName, oldValue, newValue)
    
end

function CPlayer:IsCanMove()
    return not self.StatComponent:HasValue("BanMove")
end

-- 硬直状态
function CPlayer:IsStiff()
end

-- 是否可以更新索敌状态
function CPlayer:CanAutoSelectUpdate()
end

-- 获取闪避动画
function CPlayer:GetRollAnimation()
    return self.rollAnimation or "DodgeFront"
end
-- 记录闪避动画
function CPlayer:SetRollAnimation(animation)
    self.rollAnimation = animation
end

-- 玩家死亡
function CPlayer:OnDead(data)
    if self:IsLocalPlayer() then
        self.node:Move(MS.Utils.VECZERO, true)
    end
end

-- 获取GameRoot节点
function CPlayer:GetGameRoot()
    if self.scene == nil then
        return nil
    end
    local workspace = self.scene:GetWorkspace()
    return workspace.GameRoot
end



-- 玩家离开
function CPlayer:Release()
	self.node = nil
end



--获取死亡的时间
function CPlayer:GetDeathTime()
end

--残留时间已到
function CPlayer:OnDeathTimeEnd()
end

--是否可以播放受击动作
function CPlayer:CanPlayHitAnim()
    local curState = self:GetCurrentState()
    if curState ~= ActorDefines.EActorState.KnockUp 
        and curState ~= ActorDefines.EActorState.KnockUp2
        and curState ~= ActorDefines.EActorState.KnockBack 
        and curState ~= ActorDefines.EActorState.KnockDown then
            return true
    end
    return false
end

-- 设置换弹状态
function CPlayer:SetReloading(isReloading)
    self.isReloading = isReloading
end

-- 获取换弹状态
function CPlayer:IsReloading()
    return self.isReloading
end

-- 激活武器事件
function CPlayer:OnActiveWeapon(item)
    
end

-- 卸下武器事件
function CPlayer:OnDeactiveWeapon(item)
    
end

-----------------------------------技能事件-----------------------------------
function CPlayer:StopDashMove()
    
end

-- 造成伤害
function CPlayer:CauseDamage(damageResult)

end
-- 伤害事件
function CPlayer:TakeDamage(damageResult)
    -- 没有受到伤害
    if damageResult.damage <= 0 then
        return
    end

    if damageResult.target.bindObj == self.bindObj then
        --伤害飘字
        -- MS.Events:Trigger(MS.EventID.ShowBMText, 
        --     {text = math.floor(damageResult.damage), target = damageResult.target:GetCharacter(), type = damageResult.damageType})
        -- if damageResult.otherData.isPlayHit and self:CanPlayHitAnim() then
            -- self:PlayAnimByPoseState("Hit") -- 目前受击动画和射击动画冲突，先不播放受击动画
        -- end

        -- 受击特效
    end
end

-- 获得治疗
function CPlayer:ReceiveHeal(healResult)
    
end

return CPlayer