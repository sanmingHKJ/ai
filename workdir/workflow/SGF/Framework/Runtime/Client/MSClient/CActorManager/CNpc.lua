-- 怪物控制类
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
local ActorManager = GFScript("ActorModule.ActorManager")
local MainStorage = game:GetService("MainStorage")

local ActorHelper = require(MainStorage.Framework.GamePlay.ActorHelper)

local CNpc = Class.New("CNpc", Npc)

function CNpc:Constructor()
end

function CNpc:Destructor()
    MS.NetworkHelper:UnregisterNetObj(self)
    --反注册所有事件
    -- if self.footStepEvent then
    --     self.footStepEvent:Disconnect()
    --     self.footStepEvent = nil
    -- end
    -- if self.timelineEvent then
    --     self.timelineEvent:Disconnect()
    --     self.timelineEvent = nil
    -- end

    -- self:ClearShaderModify()
    -- self:RemoveAllEffect()

    -- if self.isRimColorForever then
    --     local materials = self:GetModelMaterials()
    --     for i, mat in ipairs(materials) do
    --         mat:SetKey("USE_RIM_COLOR", false)
    --     end
    --     self.isRimColorForever = false
    -- end

    -- if self.playerTitleUI ~= nil then
    --     self.playerTitleUI:FollowTarget(nil)
    --     self.playerTitleUI:Destroy()
    --     self.playerTitleUI = nil
    -- end
end

function CNpc:InitClient()
    MS.NetworkHelper:RegisterNetObj(self)
    CNpc.super.InitClient(self)
	self.node = self.bindObj
    self.isGetUp = false
    self.effects = {} -- 存储特效Id
    self.rimColorStack = {}

    self:Regist()
    -- self:SetModel('SandboxId://FK_ANI/034010101/034010101Skin.prefab')

    self:SetLoadFinishCallback(function()
        self:OnModelLoadFinish()
    end)
end

--加载完成
function CNpc:LoadFinished()
    self.effects = {} -- 存储特效Id

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
            --  Log:Debug("oldState: %s newState: %s",tostring(oldState), tostring(newState))
            self:OnStateChanged(oldState, newState)
        end)
    -- 属性改变
    self:OnClientEvent("StatChanged",
        function(statName, oldValue, newValue)
            self:OnStatChanged(statName, oldValue, newValue)
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
        
    self:OnClientEvent("AnimInitFinished",
    function()
        -- 动画Clip帧事件通知
        local animator = self.AvatarComponent:GetAnimator()
        if animator then    
            if self.footStepEvent then
                self.footStepEvent:Disconnect()
                self.footStepEvent = nil
            end
            self.footStepEvent = animator.ClipsEventNotify:Connect(function(key, value)
                if key == "StepL" then
                    self:PlayFootstepSound(true, true)
                elseif key == "StepR" then                   
                    self:PlayFootstepSound(true, false)
                end                                 
            end)
        end
    end)

    -- 开枪
    self:OnClientEvent("Shooting",
        function()
            self.clientShooting = true
            local isMoving = self.AvatarComponent:IsMoving()
            if isMoving and not self:IsWaistShoot() then
                -- 射击状态下根据移动方向播放对应动画
                local dirAnim = self:GetFourDirectionAnim()
                self:PlayAnimByPoseState(dirAnim)
            end
            
        end)
    -- 停止射击
    self:OnClientEvent("StopShooting",
        function()
            self.clientShooting = false
        end)

    -- 装弹
    self:OnClientEvent("Reload",
        function()
            self:SetReloading(true)
            local isMoving = self.AvatarComponent:IsMoving()
            if isMoving then
                self:PlayAnimByPoseState("Move")
            end
            -- 打断Run动作，变成Walk动作，速度也得降下来
            self:SetMoveType(AvatarDefines.EMoveType.Move)
        end)

    -- 装弹结束
    self:OnClientEvent("ReloadFinished",
        function()
            self:SetReloading(false)
            local isMoving = self.AvatarComponent:IsMoving()
            if isMoving then
                self:PlayAnimByPoseState("Run")
            end
            if not self:IsAim() and 
                not self:IsWaistShoot() and 
                not self:IsProne() and 
                not self:IsCrouch() then
                -- 恢复速度
                self:SetMoveType(AvatarDefines.EMoveType.Run)
            end
        end)

    -- 使用物品
    self:OnClientEvent("UseItem",
        function(storageComponent, item)
            self:OnUseItem(item)
        end)

    -- 停止使用物品
    self:OnClientEvent("StopUseItem",
        function(storageComponent, item)
            self:OnStopUseItem(item)
        end)
end

-- 注册相关事件
function CNpc:Regist()

end

function CNpc:Update(dt)
    CNpc.super.Update(self, dt)

end
--更新
function CNpc:LaterUpdate(dt)
    CNpc.super.LaterUpdate(self, dt)
end
-- 设置模型
function CNpc:SetModel(assetName)
    -- local modelId = 'SandboxId://FK_ANI/034010101/034010101_Skin.prefab'
    
    self.node.ModelId = assetName
end

-- 获取武器子状态机
function CNpc:GetWeaponSubStateMachine()
    local activeWeapon = self.EquipmentComponent:GetActiveWeapon()
    if activeWeapon then
        if activeWeapon.data and activeWeapon.data.subStateMachine then
            return activeWeapon.data.subStateMachine
        end
    end
    return "M4A1"
end

-- 获取动画前缀
function CNpc:GetAnimPrefix(name)
    -- 通用动画，不是在子状态机里的动画
    if string.find(name, "HealSyringeSelf") or -- 医疗针
        string.find(name, "FixArmorSelf") or -- 修理装甲
        string.find(name, "Rescue") or -- 救援
        string.find(name, "KnockedDown") or -- 击倒
        string.find(name, "Swap") then -- 换武器
        return ""
    end

    return self:GetWeaponSubStateMachine() .. "."
end

-- 获取姿势状态
function CNpc:GetPoseState()
    if self:IsCrouch() then -- 蹲下
        return "Crouch"
    elseif self:IsProne() then -- 趴下
        return "Prone"
    elseif self:IsAim() then -- 瞄准
        return "Aim"
    elseif self:IsWaistShoot() or self.clientShooting then -- 腰射
        return "Waist"
    end
    return ""
end

--获取衍生移动动画
function CNpc:GetDerivedMoveAnim()
    local moveType = self.AvatarComponent:GetMoveType()
    if moveType == AvatarDefines.EMoveType.Walk then
        return "Walk"
    elseif moveType == AvatarDefines.EMoveType.Run then
        return "Run"
    elseif moveType == AvatarDefines.EMoveType.Sprint then
        return "Sprint"
    end
    return "Run"
end
--获取衍生动画速度
function CNpc:GetDerivedAnimSpeed()
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

-- 因为目前只有四向动画，所以这里需要特殊处理，将MoveFront左右和MoveBack左右动画改为MoveFront和MoveBack
function CNpc:AdjustmentDirections(name)
    if string.find(name, "MoveFrontLeft") or string.find(name, "MoveBackLeft")  or string.find(name, "MoveFrontRight") or string.find(name, "MoveBackRight") then
        name = self:GetFourDirectionAnim()
    end
    return name
end

-- 获取GameRoot节点
function CNpc:GetGameRoot()
    if self.scene == nil then
        return nil
    end
    local workspace = self.scene:GetWorkspace()
    return workspace.GameRoot
end

--播放动画
function CNpc:PlayAnim(name, layer, normalized)
    if self.AvatarComponent then
        local isMoving = self.AvatarComponent:IsMoving()
        name = self:GetAnimPrefix(name) .. name
        if isMoving and (name == "Shoot" or name == "Reload" or string.find(name, "Swap")) then
            layer = self:GetUpLayerIdx()
            self:SetUpLayerWeight(1)
        end
        -- print('ttttttttttttttttttttttt CNpc  普通播放动画  layer='..(layer or 0)..' name='..name)
        self.AvatarComponent:PlayAnim(name, layer, normalized)
    end
end

--根据姿势状态播放动画
function CNpc:PlayAnimByPoseState(name, layer, normalized)
    if self.AvatarComponent then
        local isMoving = self.AvatarComponent:IsMoving()
        local poseState = self:GetPoseState()
        local isCrouch = self:IsCrouch()
        local isAim = self:IsAim()
        local isWaist = self:IsWaistShoot()
        local isProne = self:IsProne()
        local isWalk = self:IsWalk() -- 静步走状态
        local isAlert = self:IsAlert()

        -- 如果角色在移动并且在Shoot和Reload的时候需要使用上层layer索引
        if isMoving and (name == "Shoot" or name == "Reload" or string.find(name, "Swap")) then
            layer = self:GetUpLayerIdx()
            -- 设置上层layer的权重为1
            self:SetUpLayerWeight(1)
        elseif not self:IsLowerBodyMove(name) then
            -- 设置上层layer的权重为0
            self:SetUpLayerWeight(0)
        end

        -- 静步走状态
        if isWalk then
            if name == "Run" then
                name = "Walk" -- 静步走状态下要播放Walk动画
            elseif name == "Walk" and (isAim or isCrouch or isProne) then
                name = "Move" -- 静步走状态下的Move动画(没有Walk动作，所以播放Move动画)
            end
        end

        if Utils:IsNullOrEmpty(poseState) then -- 没有Pose
            -- 普通Run（没有Pose状态）的时候，根据移动方向播放对应动画
            local inputDir = self.AvatarComponent:GetInputDir()
            local dirAnim = self:GetEightDirectionAnim()
            if string.find(name, "Run") or string.find(name, "Move") or (name == "Walk" and not isWalk) then
                if not self:IsFrontDirection(dirAnim) and not inputDir:IsZero() then
                    name = "Walk"
                    self:SetMoveType(AvatarDefines.EMoveType.Move)  -- 这里会导致GetMoveDirectionAnim返回Move状态
                elseif self:IsReloading() then
                    name = "Move"
                elseif self.isStaminaDepleted then
                    
                else
                    if dirAnim == "MoveFrontLeft" then -- 前左
                        name = "RunLeft"
                    elseif dirAnim == "MoveFrontRight" then -- 前右
                        name = "RunRight"
                    else
                        name = "Run"
                    end
                    self:SetMoveType(AvatarDefines.EMoveType.Run)
                end
            elseif isAlert then -- 戒备状态
                if isMoving then
                    if dirAnim == "MoveFront" then
                        name = "Run" -- 前进方向播放Run动画
                    end
                else
                    name = "Waist".. name -- 非移动状态播放WaistIdle动画
                end
            end
            name = self:GetAnimPrefix(name) .. name
        else
            -- TODO
            -- 因为目前只有四向动画，所以这里需要特殊处理，将MoveFront左右和MoveBack左右动画改为MoveFront和MoveBack
            name = self:AdjustmentDirections(name)

            -- 如果是四向移动动画
            if self:IsLowerBodyMove(name) then
                -- 蹲下状态下的动画
                if isCrouch then
                    if isAim then
                        name = "Aim" .. name
                    elseif isWaist or isAlert then
                        name = "Waist" .. name
                    end
                elseif isProne or isAim then
                    
                elseif not isWaist and isAlert and self:IsFrontDirection(name) then -- 戒备状态下,前进方向播放Run动画
                    name = "Run"
                    poseState = ""
                end
                name = self:GetAnimPrefix(name) .. poseState .. name
            else
                -- 如果是Move则需要将name改为MoveFront（非战斗的状态下朝向都是单项）
                if name == "Move" then
                    if isAim or isWaist or isAlert or isProne then
                        name = self:GetFourDirectionAnim()
                    end
                elseif name == "Run" then
                    name = "Move"  -- 有Pose状态时，Run动画改为Move动画
                end
                -- 蹲下状态下的动画
                if isCrouch then
                    if isAim then
                        name = "Aim" .. name
                    elseif isWaist or isAlert then
                        name = "Waist" .. name
                    end
                elseif isProne then
                    -- name = "Aim" .. name -- 趴下或者趴下瞄准都通用同个动作
                end
                name = self:GetAnimPrefix(name) .. poseState .. name
            end
        end
        -- 跑的时候取消戒备状态
        if string.find(name, "Run") then
            self:CancelAlert()
        end
        --print('ttttttttttttttttttttttt CNpc  PlayAnimByPoseState  layer='..(layer or 0)..' name='..name)
        self.AvatarComponent:PlayAnim(name, layer, normalized)
    end
end

-- 取消戒备状态
function CNpc:CancelAlert()
    if self:IsAlert() then
        self:CallServer(MS.Protocol.ClientMSGID.CANCEL_ALERT_REQ)
    end
end

-- 判断是否下半身四向移动
function CNpc:IsLowerBodyMove(name)
    if name == "MoveFront" or name == "MoveBack" or name == "MoveLeft" or name == "MoveRight" then
        return true
    end
    return false
end

-- 设置移动类型
function CNpc:SetMoveType(moveType)
    if not self:IsWalk() then -- 静步走状态下，蹲和趴不会取消掉静步状态和静步移速
        self.AvatarComponent:SetMoveType(moveType)
    end
end

-- 获取移动方向对应的动画名称
function CNpc:GetEightDirectionAnim()
    local inputDir = self.AvatarComponent:GetInputDir()
    if not inputDir or inputDir:Magnitude() < 0.1 then return "MoveFront" end
    
    -- 获取角色的前向和右向
    local forward = self.AvatarComponent:GetForward()
    local right = self.AvatarComponent:GetRight()
    
    -- 计算移动方向在角色前向和右向上的投影
    local forwardDot = inputDir:Dot(forward)  -- 与前方的点积
    local rightDot = inputDir:Dot(right)      -- 与右方的点积
    
    -- 定义斜向判定的阈值（可以根据需要调整）
    local DIAGONAL_THRESHOLD = 0.6  -- cos(45°) ≈ 0.707，我们用0.6使斜向判定更容易触发
    
    -- 判断是否为斜向移动
    if math.abs(forwardDot) > DIAGONAL_THRESHOLD and math.abs(rightDot) > DIAGONAL_THRESHOLD then
        -- 斜向移动
        if forwardDot > 0 then
            -- 前斜
            if rightDot > 0 then
                return "MoveFrontLeft"  -- 前左
            else
                return "MoveFrontRight" -- 前右
            end
        else
            -- 后斜
            if rightDot > 0 then
                return "MoveBackLeft"   -- 后左
            else
                return "MoveBackRight"  -- 后右
            end
        end
    elseif math.abs(rightDot) > math.abs(forwardDot) then
        -- 纯左右移动
        if rightDot > 0 then
            return "MoveLeft"   -- 向左移动
        else
            return "MoveRight"  -- 向右移动
        end
    else
        -- 纯前后移动
        if forwardDot > 0 then
            return "MoveFront"  -- 向前移动
        else
            return "MoveBack"   -- 向后移动
        end
    end
end

-- 获取四向动画
function CNpc:GetFourDirectionAnim()
    local inputDir = self.AvatarComponent:GetInputDir()
    if not inputDir or inputDir:Magnitude() < 0.1 then return "MoveFront" end
    
    -- 获取角色的前向和右向
    local forward = self.AvatarComponent:GetForward()
    local right = self.AvatarComponent:GetRight()
    
    -- 计算移动方向在角色前向和右向上的投影
    local forwardDot = inputDir:Dot(forward)  -- 与前方的点积
    local rightDot = inputDir:Dot(right)      -- 与右方的点积
    
    if math.abs(rightDot) > math.abs(forwardDot) then
        -- 纯左右移动
        if rightDot > 0 then
            return "MoveLeft"   -- 向左移动
        else
            return "MoveRight"  -- 向右移动
        end
    else
        -- 纯前后移动
        if forwardDot > 0 then
            return "MoveFront"  -- 向前移动
        else
            return "MoveBack"   -- 向后移动
        end
    end
end

--加载完毕
function CNpc:OnModelLoadFinish()
    -- self:PlayAnim("Idle")
end
-- 状态改变
function CNpc:OnStateChanged(oldState, newState)
    -- if not oldState then
    --     oldState = "nil"
    -- end
    -- Log:Debug("CNpc:OnStateChanged::: oldState=="..oldState .. "  newState=="..newState)
    if newState == ActorDefines.EActorState.Idle then
        if oldState == ActorDefines.EActorState.Moving then
            if not self:IsStiff() then
                local curAnimName = self.AvatarComponent:GetCurrentStateName()
                if curAnimName == "Run" and self:IsAlert() then -- 跑的时候取消戒备状态
                    self:CancelAlert()
                else
                    self:PlayAnimByPoseState("Idle")
                end
            end
        elseif oldState == ActorDefines.EActorState.Fly then
            self:PlayAnimByPoseState("JumpEnd")
        end
    elseif newState == ActorDefines.EActorState.Moving then -- 移动
        if not self:IsStiff() then
            if self:IsAim() or self:IsWaistShoot() or self:IsAlert() or self:IsProne() then -- 这里没有Self:IsCrouch()，因为蹲下状态下的移动动画是CrouchMove
                -- 瞄准状态下根据移动方向播放对应动画
                local dirAnim = self:GetFourDirectionAnim()
                self:PlayAnimByPoseState(dirAnim)
            else
                self:PlayAnimByPoseState(self:GetDerivedMoveAnim())
            end
        end
    elseif newState == ActorDefines.EActorState.Jump then -- 跳跃
        self:PlayAnimByPoseState("JumpStart")
    elseif newState == ActorDefines.EActorState.NearDeath then --濒临死亡
        self:PlayAnim("EnterKnockedDown")
    elseif newState == ActorDefines.EActorState.Dead then -- 死亡
        -- if oldState ~= ActorDefines.EActorState.NearDeath then
        --     self:PlayAnim("KnockedDownDead")
        -- else
            self:PlayAnim("Dead")
        -- end
    end
end

-- 属性改变
function CNpc:OnStatChanged(statName, oldValue, newValue)
    -- 瞄准状态改变
    if statName == "Aim" then
        local isCrouch = self:IsCrouch()
        local isProne = self:IsProne()
        local isWalk = self:IsWalk() -- 静步走状态
        local isWaistShoot = self:IsWaistShoot()
        local isMoving = self.AvatarComponent:IsMoving()
        if newValue == 1 then -- 瞄准开启
            if isMoving then
                if isCrouch then -- 蹲下状态
                    if isWaistShoot then -- 蹲下腰射状态
                        self:PlayAnim("CrouchWaistTurnAim")
                    else
                        self:PlayAnim("CrouchIdleTurnAim")
                    end
                elseif isProne then -- 趴下状态
                else
                    if isWaistShoot then -- 腰射状态
                        self:PlayAnim("WaistTurnAim")
                    else
                        self:PlayAnim("MoveTurnAim", self:GetUpLayerIdx())
                        -- 瞄准状态下根据移动方向播放对应动画
                        local dirAnim = self:GetFourDirectionAnim()
                        self:PlayAnimByPoseState(dirAnim)
                    end
                end
            else
                if isCrouch then -- 蹲下状态
                    if isWaistShoot then -- 蹲下腰射状态
                        self:PlayAnim("CrouchWaistTurnAim")
                    else
                        self:PlayAnim("CrouchIdleTurnAim")
                    end
                elseif isProne then -- 趴下状态
                else
                    if isWaistShoot then -- 腰射状态
                        self:PlayAnim("WaistTurnAim")
                    else
                        self:PlayAnim("TurnAim")
                    end
                end
            end
        else  -- 瞄准关闭（瞄准取消是不会回到戒备状态（Waist）的）
            if isMoving then
                if isWalk then -- 静步走状态
                    if isCrouch then
                        -- 播放CrouchAimMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    else
                        self:PlayAnimByPoseState("Walk")
                    end
                else
                    if isCrouch then
                        -- 播放CrouchAimMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    elseif isProne then
                        -- 趴下时取消了蹲下状态，但是由于状态还未同步到客户端，这里不播放动画，由趴下状态的动画覆盖
                    else
                        self:PlayAnimByPoseState("Run")
                    end
                end
            else
                if isCrouch then
                    self:PlayAnim("CrouchIdle")
                elseif isProne then
                    -- 趴下动作会覆盖掉蹲下动作，所以这里不播放CrouchBack动画
                else
                    self:PlayAnim("AimBack")
                end
            end
        end
    elseif statName == "Shooting" then
        if newValue == 1 then
            self:SetMoveType(AvatarDefines.EMoveType.Move)
        else -- 射击结束
            if self.AvatarComponent:IsMoving() then
                if self:IsAim() or self:IsWaistShoot() or self.clientShooting then
                    -- 瞄准状态下根据移动方向播放对应动画
                    local dirAnim = self:GetEightDirectionAnim()
                    self:PlayAnimByPoseState(dirAnim)
                else
                    self:PlayAnimByPoseState(self:GetDerivedMoveAnim())
                end
            else
                -- 此时已经没有Waist状态了，手动改成WaistIdle动画
                if self:IsProne() then
                    self:PlayAnimByPoseState("Idle")
                else
                    self:PlayAnimByPoseState("WaistIdle")
                end
            end
        end
        if not self:IsAim() and 
            not self:IsWaistShoot() and 
            not self:IsProne() and 
            not self:IsCrouch() then
            -- 恢复速度
            self:SetMoveType(AvatarDefines.EMoveType.Run)
        end
    elseif statName == "Crouch" then
        local isAim = self:IsAim()
        local isWaistShoot = self:IsWaistShoot()
        local isProne = self:IsProne()
        local isWalk = self:IsWalk() -- 静步走状态
        local isMoving = self.AvatarComponent:IsMoving()
        local curAnimName = self.AvatarComponent:GetCurrentStateName()
        if newValue == 1 then -- 蹲下
            if isMoving then
                if isAim then
                    -- 播放CrouchAimMove动画，根据移动方向播放对应动画
                    self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                else
                    self:PlayAnim("CrouchMove")
                end
            else
                if isAim then
                    self:PlayAnim("AimTurnCrouchAim")
                else
                    if isWaistShoot then -- 蹲下腰射状态
                        self:PlayAnim("WaistTurnCrouch")
                    elseif isProne then
                        -- 蹲下时取消了趴下状态，但是由于状态还未同步到客户端，所以这里需要播放TurnCrouch动画
                        self:PlayAnim("TurnCrouch")
                    else
                        if string.find(curAnimName, "Run") then
                            self:PlayAnimByPoseState("Move")
                        elseif string.find(curAnimName, "Walk") then -- 静步走状态
                            self:PlayAnimByPoseState("Move") -- 静步走状态下的蹲下动作，播放Move动画（没有Walk动作）
                        else
                            self:PlayAnim("TurnCrouch")
                        end
                    end
                end
            end
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 0)
        else -- 蹲下结束
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 1)
            if isMoving then
                if isWalk then -- 静步走状态
                    if isAim then
                        -- 播放CrouchAimMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    else
                        self:PlayAnimByPoseState("Walk")
                    end
                else
                    if isAim then
                        -- 播放CrouchAimMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    elseif isProne then
                        -- 趴下时取消了蹲下状态，但是由于状态还未同步到客户端，这里不播放动画，由趴下状态的动画覆盖
                    else
                        self:PlayAnimByPoseState("Run")
                    end
                end
            else
                if isAim then
                    if isWaistShoot then
                        self:PlayAnim("CrouchAimTrunAim")
                    else
                        self:PlayAnim("CrouchAimTrunAim")
                    end
                elseif isProne then
                    -- 趴下动作会覆盖掉蹲下动作，所以这里不播放CrouchBack动画
                else
                    self:PlayAnim("CrouchBack")
                end
            end
        end
    elseif statName == "Prone" then -- 趴下
        local isAim = self:IsAim()
        local isWaistShoot = self:IsWaistShoot()
        local isWalk = self:IsWalk() -- 静步走状态
        local isCrouch = self:IsCrouch() -- 蹲下状态
        local isMoving = self.AvatarComponent:IsMoving()
        local curAnimName = self.AvatarComponent:GetCurrentStateName()
        if newValue == 1 then -- 趴下
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 0)
            if isMoving then
                if isAim then
                    self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                elseif isCrouch then
                    -- 趴下时取消了蹲下状态，但是由于状态还未同步到客户端，这里不播放动画，由趴下状态的动画覆盖
                    local dirAnim = self:GetFourDirectionAnim()
                    self:PlayAnim("Prone" .. dirAnim)
                else
                    self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                end
            else
                if isAim then
                    self:PlayAnim("TurnProne")
                else
                    self:PlayAnim("TurnProne")
                end
            end
        else -- 趴下结束
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 1)
            if isMoving then
                if isWalk then -- 静步走状态
                    if isAim then
                        -- 播放ProneMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    else
                        self:PlayAnimByPoseState("Walk")
                    end
                else
                    if isAim then
                        -- 播放ProneMove动画，根据移动方向播放对应动画
                        self:PlayAnimByPoseState(self:GetFourDirectionAnim())
                    else
                        self:PlayAnimByPoseState("Run")
                    end
                end
            else
                if isAim then
                    self:PlayAnim("AimIdle")
                elseif isCrouch then
                    -- 蹲下时取消了趴下状态，但是由于状态还未同步到客户端，这里不播放CrouchIdle动画，由蹲下状态的动画覆盖
                    -- self:PlayAnim("CrouchIdle")
                else
                    self:PlayAnim("ProneBack")
                end
            end
        end
    elseif statName == "Walk" then -- 静步移动
        local isMoving = self.AvatarComponent:IsMoving()
        local isProne = self:IsProne()
        local isCrouch = self:IsCrouch() -- 蹲下状态
        local animName = ""
        if newValue == 1 then
            animName = "Walk"
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 0)
        else
            animName = "Run"
            MS.Events:emit(tostring(MS.EventID.KeyCodeW), 1)
        end

        if isMoving and not isProne and not isCrouch then
            self:PlayAnim(animName)
        end
    elseif statName == "Alert" then -- 戒备状态
        local isMoving = self.AvatarComponent:IsMoving()
        if newValue == 1 then
            
        else -- 取消戒备状态
            if isMoving then
                if self:IsAim() or self:IsWaistShoot() then
                    -- 瞄准状态下根据移动方向播放对应动画
                    local dirAnim = self:GetEightDirectionAnim()
                    self:PlayAnimByPoseState(dirAnim)
                else
                    self:PlayAnimByPoseState(self:GetDerivedMoveAnim())
                end
            else
                -- 此时已经没有Waist状态了，手动改成WaistIdle动画
                self:PlayAnimByPoseState("Idle")
            end
        end
    end
end

-- 获取上层layer索引
function CNpc:GetUpLayerIdx()
    return 2
end

-- 设置上层layer的权重
function CNpc:SetUpLayerWeight(weight)
    local upLayerIdx = self:GetUpLayerIdx()
    local upSyncLayerIdx = upLayerIdx + 1 -- 上层layer的外挂骨骼同步层索引
    self.AvatarComponent:SetAnimLayerWeight(upLayerIdx, weight)
    self.AvatarComponent:SetAnimLayerWeight(upSyncLayerIdx, weight)
end

-- 硬直状态
function CNpc:IsStiff()
end

-- 死亡溶解材质信息
function CNpc:GetDeadDissolveMaterials()
    -- local config = DataProviderManager:GetMonsterData(self:GetTid())
    -- if config ~= nil and config.materialContainer ~= nil and config.materialContainer.deadDissolveMaterials ~= nil then
    --     return config.materialContainer.deadDissolveMaterials
    -- end
    return nil
end

-- 材质统一动画排除的材质列表
function CNpc:GetExcludeMaterials()
    local config = DataProviderManager:GetMonsterData(self:GetTid())
    if config == nil or config.materialContainer == nil or config.materialContainer.excludeMaterials == nil then
        return {}
    end
    local materials = {}
    for i, info in pairs(config.materialContainer.excludeMaterials) do
        if info.li and info.ci then
            if materials[info.li] == nil then
                materials[info.li] = {}
            end
            materials[info.li][info.ci] = true
        end
    end
    return materials
end

-- 获取所有材质
function CNpc:GetModelMaterials()
    local lindex = 0
    local cindex = 0
    local tempMat = nil
    local mainMat = nil
    local materials = {}
    local excludes = self:GetExcludeMaterials()

    local storeMat = function(mats, li, ci)
        local mat = self.node:GetMaterialInstance({li}, ci)

        local isAdd = true
        local mapFilter = excludes[li]
        if mapFilter ~= nil and mapFilter[ci] then
            isAdd = false
        end

        if mat ~= nil and isAdd then
            table.insert(mats, mat)
        end
        return mat
    end

    repeat
        cindex = 0
        mainMat = storeMat(materials, lindex, cindex)

        if mainMat ~= nil then
            repeat
                cindex = cindex + 1
                tempMat = storeMat(materials, lindex, cindex)
            until(tempMat == nil)
        end
        lindex = lindex + 1
    until(mainMat == nil)

    return materials
end

-- 边缘光
function CNpc:UseRimColor(duration, intensity, width, color)
    local effect = {
        duration = duration,
        intensity = intensity or 15,
        width = width or 1.40,
        color = color or {1.0, 1.0, 1.0},
        startTime = os.clock(),
        timer = nil
    }
    table.insert(self.rimColorStack, effect)

    local materials = self:GetModelMaterials()
    if #materials == 0 then
        return
    end

    local currentEffect = self.rimColorStack[#self.rimColorStack]
    for _, mat in ipairs(materials) do
        mat:SetKey("USE_RIM_COLOR", true)
        mat:SetR32("_RimIntensity", currentEffect.intensity)
        mat:SetR32("_RimWidth", currentEffect.width)
        mat:SetRGB32("g_RimColor", Vector3.New(currentEffect.color[1], currentEffect.color[2], currentEffect.color[3]))
    end

    if duration > 0 then
        self.isRimColorForever = false
        effect.timer = TimerManager:AddTimer(function()
            for i, e in ipairs(self.rimColorStack) do
                if e == effect then
                    table.remove(self.rimColorStack, i)
                    break
                end
            end

            if #self.rimColorStack > 0 then
                local prevEffect = self.rimColorStack[#self.rimColorStack]
                for _, mat in ipairs(materials) do
                    mat:SetR32("_RimIntensity", prevEffect.intensity)
                    mat:SetR32("_RimWidth", prevEffect.width)
                    mat:SetRGB32("g_RimColor", Vector3.New(prevEffect.color[1], prevEffect.color[2], prevEffect.color[3]))
                end
            else
                for _, mat in ipairs(materials) do
                    mat:SetKey("USE_RIM_COLOR", false)
                end
            end
        end, duration, 1)
    else
        self.isRimColorForever = true
    end
end

-----------------------------------技能事件-----------------------------------
function CNpc:SkillEvent_PlayMontage(skill, params)
    if not Utils:IsNullOrEmpty(params.animation) then
        self:PlayAnim(params.animation)
    end
    self:SkillEvent_PlaySound(skill, {worldSpace = true, soundPath = params.sound, priority = params.soundPriority or 0})
end
-- 播放特效
function CNpc:SkillEvent_PlayEffect(skill, params, isBuff)
    local GetParent = function(params)
        if params.parent ~= nil then
            if self.node[params.parent] then
                return self.node[params.parent]
            else
                return self.node
            end
        end
    end
    local effectPath = params.effect
    local EffectMng = MS.EffectPoolManager
    local effectId, effectNode = EffectMng:GetFreeEffect(params.loop)
    -- 设置父节点
    EffectMng:SetParent(effectId, GetParent(params))
    EffectMng:SetPrefab(effectId, effectPath, function(success, error)
        if success then
            if params.distance ~= nil and params.distance ~= 0 then
                local dir = self:GetForward()
                dir:Normalize()
                effectNode.LocalPosition = effectNode.LocalPosition + Vector3.New(dir.x, dir.y, dir.z) * params.distance
            end
            -- 坐标
            if params.localPosition ~= nil then
                effectNode.LocalPosition = effectNode.LocalPosition + Vector3.New(params.localPosition.x, params.localPosition.y, params.localPosition.z)
            end
            -- 旋转
            if params.localEuler ~= nil then
                effectNode.LocalEuler = effectNode.LocalEuler + Vector3.New(params.localEuler.x, params.localEuler.y, params.localEuler.z)
            end
            -- 缩放
            if params.localScale ~= nil then
                effectNode.LocalScale = effectNode.LocalScale + Vector3.New(params.localScale.x, params.localScale.y, params.localScale.z)
            end
            -- 设置父节点
            if params.parent == 'WorkSpace' then
                effectNode.Parent = self:GetGameRoot()
            end

            -- 固定缩放
            if params.fixedScale ~= nil then
                -- 固定缩放
                effectNode.LocalScale = Vector3.New(params.fixedScale.x, params.fixedScale.y, params.fixedScale.z)
            end

            -- 播放
            EffectMng:ReStart(effectId, params.loop, params.loop)
        else
            ERR('特效[',effectPath,']加载失败:', error)
        end
    end)

    -- 特效回收
    if params.duration ~= nil and params.duration > 0 then
        TimerManager:AddTimer(function()
            self:RemoveEffect(skill.tid, effectId)
            -- EffectMng:Release(effectId)
        end,params.duration,1)
    end

    if not self.effects[skill.tid] then
        self.effects[skill.tid] = {}
    end
    table.insert(self.effects[skill.tid], effectId)

    -- 播放音效
    self:SkillEvent_PlaySound(skill, {worldSpace = true, soundPath = params.sound, priority = params.soundPriority or 0})    
end

-- 播放TimeLine
function CNpc:SkillEvent_Timeline(skill, params)
    local workspace = self.scene:GetWorkspace()
    local timeline = workspace.GameRoot.Timeline:Clone()
    timeline.Parent = workspace.GameRoot
    local pos = self:GetPosition()
    if timeline and params.timeline ~= nil and params.timelineNoCamera ~= nil then
        timeline.Position = Vector3.New(pos.x,pos.y,pos.z)
        timeline.Euler = self.node:GetRenderEuler()
        timeline.AssetID = params.timelineNoCamera--params.timeline
        timeline:PlayAsync(function(success)
            if success then
                self:SkillEvent_PlaySound(skill, {worldSpace = true, soundPath = params.sound, priority = params.soundPriority or 0})
            else
                Log:Error("PlayTimeline Failed::: UserID==".. self.player.UserId)
            end
        end)

        if self.timelineEvent then
            self.timelineEvent:Disconnect()
            self.timelineEvent = nil
        end

        self.timelineEvent = timeline.StopPlaying:Connect(function()
            if params.distance and params.distance ~=0 then
                -- 对齐位置
                local dir = self:GetForward()
                dir:Normalize()
                self:SetPosition(self:GetPosition() + dir * params.distance)
            end
            timeline.Parent = nil
        end)
    end
end

-- 伤害事件
function CNpc:TakeDamage(damageResult)
    -- 无敌
    if damageResult.damageType == CombatDefines.EDamageType.Invincible then
        return
    end
    -- 没有受到伤害
    if damageResult.damage <= 0 then
        return
    end
    local skillData = nil
    local buffData = nil
    if damageResult.source.type == CombatDefines.EDamageSourceType.Skill then
        skillData = SkillManager:GetSkillData(damageResult.source.tid)
    elseif damageResult.source.type == CombatDefines.EDamageSourceType.Buff then
        buffData = BuffManager:GetBuffData(damageResult.source.tid)
    end

    if damageResult.target.bindObj == self.bindObj then
        --伤害飘字
        -- MS.Events:Trigger(MS.EventID.ShowBMText, 
        --     {text = math.floor(damageResult.damage), target = damageResult.target:GetCharacter(), type = damageResult.damageType})
        -- MS.Events:Trigger(MS.EventID.ShowFloatText, {text = damageResult.damage, pos = damageResult.target:GetCharacter().Position})
        if damageResult.otherData then
            if damageResult.otherData.isPlayHit and self:CanPlayHitAnim() then
                self:PlayAnim("Hit")
            end
        end
    end

    -- 受击特效
    if damageResult.otherData then
        local params = damageResult.otherData.hitEffect
        if params and params.effect ~= "" then
            -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 检查受击特效配置")
            local offset = Vec3.New(0,150,0)
            local pos = damageResult.causer:GetPosition() + offset
            local targetPos = damageResult.target:GetPosition()
            targetPos.y = pos.y
            local dir = targetPos - pos
            dir:Normalize()
            self:EnableOverlap(true)
            local isHit, targetPos, rotation = Utils:RayObj(self.bindObj,pos,dir,5000,ActorDefines.AllCollideActorGroups)
            self:EnableOverlap(false)
            -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 检查命中  Utils:RayObj...")
            if isHit then
                -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 检查命中 isHit 命中了")
                local effectPath = params.effect
                local EffectMng = MS.EffectPoolManager
                local effectId, effectNode = EffectMng:GetFreeEffect(false)
                EffectMng:SetParent(effectId, self:GetGameRoot(), targetPos) --设置父节点
                -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 准备播放受击特效 SetParent中， 资源：",effectPath)
                EffectMng:SetPrefab(effectId, effectPath, function(success, error)
                    if success then
                        -- print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 准备播放受击特效 SetPrefab回调成功， 资源：",effectPath)
                        effectNode.Rotation = rotation
                        -- 坐标
                        if params.localPosition ~= nil then
                            effectNode.LocalPosition = effectNode.LocalPosition + Vector3.New(params.localPosition.x, params.localPosition.y, params.localPosition.z)
                        end
                        -- 旋转
                        if params.localEuler ~= nil then
                            effectNode.LocalEuler = effectNode.LocalEuler + Vector3.New(params.localEuler.x, params.localEuler.y, params.localEuler.z)
                        end
                        -- 缩放
                        if params.localScale ~= nil then
                            effectNode.LocalScale = effectNode.LocalScale + Vector3.New(params.localScale.x, params.localScale.y, params.localScale.z)
                        end
                        -- 播放
                        EffectMng:ReStart(effectId)
                    else
                        ERR('特效[',effectPath,']加载失败:', error)
                    end
                end)

                -- 特效回收
                if params.duration ~= nil and params.duration > 0 then
                    TimerManager:AddTimer(function()
                        EffectMng:Release(effectId)
                    end,params.duration,1)
                end
                -- Debugger:DrawBox(Vec3.New(targetPos.x, targetPos.y, targetPos.z),
                --     Quat.New(rotation.w,rotation.x,rotation.y,rotation.z),
                --     Vec3.New(20,20,20),
                --     nil,0.5)
            end
        end
    end

    -- self:UseRimColor(2)

    --受击受击反馈
    local player = ActorManager:GetLocalPlayer()
    if skillData then
        ActorHelper:PlayHitFeedback(player,damageResult, skillData.hitFeedback)
        -- 播放音效
        self:SkillEvent_PlaySound(skill, {worldSpace = true, soundPath = skillData.hitFeedback.sound, priority = skillData.hitFeedback.soundPriority or 0})
    end
end

-- 获得治疗
function CNpc:ReceiveHeal(healResult)
    -- 恢复血量
    if healResult.heal > 0 then
        -- MS.Events:Trigger(MS.EventID.ShowBMText, 
        --     {text = string.format("+%d", healResult.heal), target = self:GetCharacter(), type = CombatDefines.EOtherType.Health})
    end
end

--顿帧
function CNpc:SkillEvent_PauseTime(skill, params)
    --if self:IsLocalPlayer() then
        self.AvatarComponent:PauseResumeAnimDelay(params.pauseTime, params.speed)
    --end
end

--边缘光
function CNpc:SkillEvent_UseRimColor(skill, params)
    self:UseRimColor(params.duration, params.rimIntensity, params.rimWidth, {params.rimColor[1], params.rimColor[2], params.rimColor[3]})
end

--播放音效
function CNpc:SkillEvent_PlaySound(skill, params, isBuff)
    local isBuff = isBuff or false
    if Utils:IsNullOrEmpty(params.soundPath) then
       return 
    end
    local soundChannel = params.soundChannel
    if Utils:IsNullOrEmpty(soundChannel) then
        soundChannel = "Effect"  
    end

    local soundPath =  MS.Utils.Resources:GetSoundID(params.soundPath)
    if params.worldSpace then --3D音效        
        SoundManager:PlaySound(soundChannel, soundPath, {
            pos = self:GetPosition(), 
            rollOffMinDistance = params.RollOffMinDistance or 3000,
            rollOffMaxDistance = params.RollOffMinDistance or 6000,
            priority = params.soundPriority or 0
        })
    else
        SoundManager:PlaySound(soundChannel, soundPath, {priority = params.soundPriority or 0})
    end
end

--暂停音效
function CNpc:SkillEvent_StopSound(skill, params, isBuff)
    local isBuff = isBuff or false
    if Utils:IsNullOrEmpty(params.soundPath) then
       return 
    end
    local soundChannel = params.soundChannel
    if Utils:IsNullOrEmpty(soundChannel) then
        soundChannel = "Effect"  
    end
    local soundPath = MS.Utils.Resources:GetSoundID(params.soundPath)
    SoundManager:StopSoundById(soundChannel, soundPath)
end

--更新shader信息 enable-属性开关 nextpass-描边
function CNpc:SetShaderData(mat, enable, nextpass, info, value)
    if mat == nil then
        return
    end

    -- 打开开关
    if enable == true and info.hasControl then
        local controlName = info.controlName
        if controlName ~= nil and controlName ~= "" then
            mat:SetKey(controlName, true)
        end
    end

    if nextpass == true and info.hasNextPass then
        -- 从节点的其他槽读取材质的nextpass替换当前材质的nextpass
        local tMaterial = info.nextPass
        if tMaterial ~= nil and #tMaterial == 2 then
            local tMat = self.node:GetMaterialInstance({tMaterial[1]}, tMaterial[2])
            if tMat ~= nil then
                mat:SetNextPass(tMat:GetNextPass())
            end
        end

        -- 直接修改nextpass参数
        local nextPassKeys = info.nextPassKeys
        local nextPassValues = info.nextPassValues
        if nextPassKeys ~= nil and nextPassValues ~= nil then
            local lenKeys = #nextPassKeys
            local lenVaues = #nextPassValues
            local nMaterial = mat:GetNextPass()
            if lenKeys > 0 and lenKeys == lenVaues and nMaterial ~= nil then
                for i = 1, lenKeys, 1 do
                    nMaterial:SetR32(nextPassKeys[i], nextPassValues[i])
                end
            end
        end
    elseif nextpass == false then
        mat:SetNextPass(nil)
    end

    -- 设置主材质参数，做材质动画用
    local property = info.property
    if property ~= nil and property ~= "" then
        mat:SetR32(property, value)
    end
    
    -- 关闭开关
    if enable == false and info.hasControl then
        local controlName = info.controlName
        if controlName ~= nil and controlName ~= "" then
            mat:SetKey(controlName, false)
        end
    end
end

--设置材质
function CNpc:DoShaderModify(materials, enable, nextpass, value)
    if self.node == nil then
        return
    end
    for i, info in ipairs(materials) do
        local material = info.material
        if material ~= nil and #material == 2 then
            local mat = self.node:GetMaterialInstance({material[1]}, material[2])
            self:SetShaderData(mat, enable, nextpass, info, value)
        end
    end
end

function CNpc:DoShowShader(params, animFun, startValue, targetValue, nextPass)
    self:DoShaderModify(params.materials, true, nextPass, startValue)

    self.m_shaderShowTweenId = animFun(Tween, function(value)
        self:DoShaderModify(params.materials, nil, nextPass, value)
    end, startValue, targetValue, params.showTime, Tween.Easing.EaseInQuad)

    if self.m_shaderShowTweenId ~= nil then
        Tween:AddTweenComplete(self.m_shaderShowTweenId, function()
            self:DoShaderModify(params.materials, nil, true, targetValue)
            self.m_shaderShowTweenId = nil
        end)
    end
end

function CNpc:DoHideShader(params, animFun, startValue, targetValue)
    self.m_shaderHideTimerId = TimerManager:AddTimer(function()
        if self.m_shaderShowTweenId ~= nil then
            Tween:RemoveTween(self.m_shaderShowTweenId)
        end
        self.m_shaderShowTweenId = nil
        self.m_shaderHideTimerId = nil

        self:DoShaderModify(params.materials, nil, false, targetValue)

        self.m_shaderHideTweenId = animFun(Tween, function(value)
            self:DoShaderModify(params.materials, nil, nil, value)
        end, targetValue, startValue, params.hideTime, Tween.Easing.EaseInQuad)

        if self.m_shaderHideTweenId ~= nil then
            Tween:AddTweenComplete(self.m_shaderHideTweenId, function()
                if self.m_shaderModifyComplete ~= nil then
                    self.m_shaderModifyComplete()
                end
                self.m_shaderModifyComplete = nil
                self.m_shaderHideTweenId = nil
            end)
        end
    end, params.showTime + params.duration, 1)
end

function CNpc:ClearShaderModify()
    if self.m_shaderShowTweenId ~= nil then
        Tween:RemoveTween(self.m_shaderShowTweenId)
        self.m_shaderShowTweenId = nil
    end
    if self.m_shaderHideTweenId ~= nil then
        Tween:RemoveTween(self.m_shaderHideTweenId)
        self.m_shaderHideTweenId = nil
    end
    if self.m_shaderHideTimerId ~= nil then
        TimerManager:RemoveTimer(self.m_shaderHideTimerId)
        self.m_shaderHideTimerId = nil
    end
    if self.m_shaderModifyComplete ~= nil then
        self.m_shaderModifyComplete()
        self.m_shaderModifyComplete = nil
    end
end

--Shader修改
function CNpc:SkillEvent_ShaderModify(skill, params, isBuff)
    local isBuff = isBuff or false
    if params.materials == nil or #params.materials <= 0 then
        return
    end
    if params.showTime < 0 or params.duration < 0 or params.hideTime < 0 then
        return
    end
    if params.showTime == 0 and params.duration == 0 and params.hideTime == 0 then
        return
    end

    self:ClearShaderModify()

    local startValue = nil
    local targetValue = nil
    local animFun = Tween[params.animation]

    if animFun == nil then
        return
    end
    if "AlphaTo" == params.animation then
        startValue = params.startValue or 0
        targetValue = params.targetValue or 1
    end

    self.m_shaderModifyComplete = function()
        self:DoShaderModify(params.materials, false, nil, startValue)
    end

    local modifyType = params.modifyType or 0
    if modifyType == 1 then
        -- 主材质属性动画、动画期间不开启nextpass、动画结束后会检测开启nextpass
        self:DoShowShader(params, animFun, startValue, targetValue, nil)
    elseif modifyType == 2 then
        -- 主材质属性动画、动画开始前关闭nextpass、动画期间不开启nextpass
        self:DoHideShader(params, animFun, startValue, targetValue)
    elseif modifyType == 3 then
        -- 修改nextpass属性、动画期间开启nextpass
        self:DoShowShader(params, animFun, startValue, targetValue, true)
    else
        self:DoShowShader(params, animFun, startValue, targetValue, nil)
        self:DoHideShader(params, animFun, startValue, targetValue)
    end
end

--Shader替换
function CNpc:SkillEvent_ShaderSwitch(skill, params, isBuff)
    local isBuff = isBuff or false

    if self.node == nil then
        return
    end
    if params.meshName == "" then
        return
    end
    if params.materials == nil or #params.materials <= 0 then
        return
    end
    if params.indexs == nil or #params.indexs <= 0 then
        return
    end
    for i, mat in ipairs(params.materials) do
        local index = params.indexs[i]
        if index ~= nil then
            self.node:SetMaterial(params.meshName, mat, index)
        end
    end
end

--是否可以播放受击动作
function CNpc:CanPlayHitAnim()
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
function CNpc:SetReloading(isReloading)
    self.isReloading = isReloading
end

-- 获取换弹状态
function CNpc:IsReloading()
    return self.isReloading
end

-- 激活武器事件
function CNpc:OnActiveWeapon(item)
    if item then
        -- print("ttttttttttttttttttttt CNpc OnActiveWeapon  装备武器  newItem=="..item.data.name)
        
        -- 武器切换时，清理当前的瞄具模型
        self:ClearCurrentScopeModel()
        
        local oldWeaponAim = self:GetWeaponAnimByType(self.deactiveWeapon)
        local newWeaponAim = self:GetWeaponAnimByType(item)
        local animName = "Swap" .. oldWeaponAim .. "To" .. newWeaponAim
        self:PlayAnim(animName)   -- 播放换枪动画
        -- print("CNpc:OnActiveWeapon - 武器切换:", item.data.name)
        
        -- 延迟设置上层layer的权重为0
        self:DelayCall(function()
            local curAnimName = self.AvatarComponent:GetCurrentStateName(self:GetUpLayerIdx())
            if curAnimName then
                if string.find(curAnimName, "Swap") then
                    self:SetUpLayerWeight(0)
                end
            end
        end, 1)
    end
end

-- 卸下武器事件
function CNpc:OnDeactiveWeapon(item)
    if item then
        -- print("ttttttttttttttttttttt CNpc OnDeactiveWeapon  卸下武器  item=="..item.data.name)
        self.deactiveWeapon = item
        
        -- 卸下武器时也清理瞄具模型
        self:ClearCurrentScopeModel()
        -- print("CNpc:OnDeactiveWeapon - 卸下武器:", item.data.name)
    end
end

-- 根据武器类型获取武器动画名称
function CNpc:GetWeaponAnimByType(weapon)
    if not weapon then
        return "Gun"
    end
    if weapon.data.type == "Firearm" then -- 枪械
        return "Gun"
    else
        return "Knife"
    end
end

-- 跳跃
function CNpc:Jump()
    if self.bindObj then
        self.bindObj:Jump(true)
        self.bindObj:SetEnableContinueJump(false)
        -- TimerManager:DelayCall(function()
        --     self.bindObj:Jump(false)
        -- end, 0.05)
    end
end

-- 判断是否前进方向
function CNpc:IsFrontDirection(dirAnim)
    -- 获取移动方向对应的动画名称
    dirAnim = dirAnim or self:GetEightDirectionAnim()
    if dirAnim == "MoveFront" or dirAnim == "MoveFrontLeft" or dirAnim == "MoveFrontRight" then
        return true
    end
    return false
end

-- 移除特效
function CNpc:RemoveEffect(tid, eId)
    if self.effects and self.effects[tid] then
        local effects = self.effects[tid]

        local rEffects = {}
        for _, effectId in ipairs(effects) do
            if eId == nil or eId == effectId then
                MS.EffectPoolManager:Release(effectId)
            else
                table.insert(rEffects, effectId)
            end
        end
        if #rEffects > 0 then
            self.effects[tid] = rEffects
        else
            self.effects[tid] = nil
        end
    end
end
-- 移除所有特效
function CNpc:RemoveAllEffect()
    for tid, effects in pairs(self.effects) do
        self:RemoveEffect(tid)
    end
    self.effects = {}
end

--播放脚步声
-- isPet: 是否只播放宠物的e脚步声
function CNpc:PlayFootstepSound(isPet, isLeft)
    local tid = self:GetTid()   
    if isPet then
        if tid ~= "Monster_035010101" then
            return
        end
    end
    
    local soundPath = 'Footstep/'..tid..'_'
    ActorHelper:PlayFootstepSound(self:GetPosition(), soundPath, isLeft)
end


-----------------------------------Buff事件-----------------------------------

--顿帧
function CNpc:BuffEvent_PauseTime(buff, params)
    self:SkillEvent_PauseTime(buff, params)
end

--播放特效
function CNpc:BuffEvent_PlayEffect(buff, params)
    self:SkillEvent_PlayEffect(buff, params, true)
end

--边缘光
function CNpc:BuffEvent_UseRimColor(buff, params)
    self:SkillEvent_UseRimColor(buff, params)
end

--播放音效
function CNpc:BuffEvent_PlaySound(buff, params)
    self:SkillEvent_PlaySound(buff, params, true)
end

--暂停音效
function CNpc:BuffEvent_StopSound(buff, params)
    self:SkillEvent_StopSound(buff, params, true)
end

function CNpc:SetOutline(material, outlineInfo, enable)
    if material == nil or outlineInfo == nil then
        return
    end
    if enable then
        material:SetNextPass(outlineInfo.nextPass)
    else
        material:SetNextPass(nil)
    end
    -- local nextPass = material:GetNextPass()
    -- if nextPass ~= nil then
    --     nextPass:SetR32("_OutlineWidth", outlineInfo.width)
    --     nextPass:SetR32("_MaxOutlineWidth", outlineInfo.maxWidth)
    --     nextPass:SetRGB32("_OutlineColor", outlineInfo.color)
    --     material:SetNextPass(nextPass)
    -- end
end

function CNpc:GetOutline(material)
    if material == nil then
        return nil
    end
    local nextPass = material:GetNextPass()
    if nextPass == nil then
        return nil
    end
    local outlineInfo = {
        width = nextPass:GetR32("_OutlineWidth");
        maxWidth = nextPass:GetR32("_MaxOutlineWidth");
        color = nextPass:GetRGB32("_OutlineColor");
        nextPass = nextPass;
    }
    return outlineInfo
end

function CNpc:GetOutlineRefCount()
    if self.outlines == nil or self.outlines.refMap == nil then
        return 0
    end
    local count = 0
    for k, c in pairs(self.outlines.refMap) do
        if k ~= nil and c > 0 then
            count = count + c
        end
    end
    return count
end

function CNpc:EnableOutlines(materials, controlName)
    if self.outlines == nil then
        return
    end
    local curCount = self.outlines.refMap[controlName] or 0
    if curCount > 0 then
        self.outlines.refMap[controlName] = curCount - 1
    end
    local allCount = self:GetOutlineRefCount()
    for i, mat in ipairs(materials) do
        -- 关闭开关
        mat:SetKey(controlName, false)
        if allCount <= 0 then
            -- 恢复描边
            self:SetOutline(mat, self.outlines[i], true)
        end
    end
    if allCount <= 0 then
        self.outlines = nil
    end
end

function CNpc:DisableOutlines(materials, controlName)
    if self.outlines == nil then
        self.outlines = {}
        self.outlines.refMap = {}
    end

    local curCount = self.outlines.refMap[controlName] or 0
    self.outlines.refMap[controlName] = curCount + 1

    local allCount = self:GetOutlineRefCount()
    for i, mat in ipairs(materials) do
        if allCount == 1 then
            -- 记录描边参数
            table.insert(self.outlines, self:GetOutline(mat))
            -- 取消描边参数
            self:SetOutline(mat, {width = 0; maxWidth = 0; color = Vector3.New(0, 0, 0);}, false)
        end
        -- 打开开关
        mat:SetKey(controlName, true)
    end
end

function CNpc:SetCharacterAlpha(duration, minAlpha, maxAlpha)
    if duration == nil or duration <= 0 then
        return
    end
    if self.node == nil then
        return
    end
    -- 获取角色所有材质
    local materials = self:GetModelMaterials()
    if #materials <= 0 then
        return
    end

    -- 禁用描边
    self:DisableOutlines(materials, "DITHER") --透明开关

    local index = 0
    local step = 0.5
    local interval = 0.1
    self.loopCharacterAlpha = function(from, to)
        local time = math.min(duration - index * step, step)
        if time > interval then
            index = index + 1
            -- 设置溶解值
            for i, mat in ipairs(materials) do
                mat:SetR32("g_DitherThreshold", from)
            end

            local tweenId = Tween:AlphaTo(function(alpha)
                -- 设置溶解值
                for i, mat in ipairs(materials) do
                    mat:SetR32("g_DitherThreshold", alpha)
                end
            end, from, to, time, Tween.Easing.EaseInQuad)

            Tween:AddTweenComplete(tweenId, function()
                if to == maxAlpha then
                    self.loopCharacterAlpha(maxAlpha, minAlpha)
                else
                    self.loopCharacterAlpha(minAlpha, maxAlpha)
                end
            end)
        else
            -- for i, mat in ipairs(materials) do
            --     mat:SetR32("g_DitherThreshold", 1)
            -- end
            -- 恢复描边
            self:EnableOutlines(materials, "DITHER")
        end
    end
    self.loopCharacterAlpha(1, minAlpha)
end

--获取死亡的时间
function CNpc:GetDeathTime()
    local dissolveInfo = self:GetDeadDissolveMaterials()
    if dissolveInfo ~= nil and dissolveInfo.animDelay ~= nil then
        return dissolveInfo.animDelay
    end
    --否者返回默认配置
    return CNpc.super.GetDeathTime(self)
end

--残留时间已到
function CNpc:OnDeathTimeEnd()
    --客户端开始做残留动画
    self:SetDissolve(true, function()
        -- if self:IsLocalPlayer() then
        -- else
        --     -- 暂不打开
        --     -- self:SetDissolve(false)
        -- end
        self:RemoveAllEffect()
    end)
end

--死亡溶解
function CNpc:SetDissolve(enable, callback)
    self.dissolveEnable = enable

    local dissolveInfo = self:GetDeadDissolveMaterials()
    if dissolveInfo == nil then
        return
    end
    -- 获取角色所有材质
    local materials = self:GetModelMaterials()
    if #materials == 0 then
        return
    end

    if enable then
        -- 禁用描边
        self:DisableOutlines(materials, dissolveInfo.controlName or "DISSOLVE") --溶解开关

        local tweenId = Tween:AlphaTo(function(alpha)
            -- 设置溶解值
            for _, mat in ipairs(materials) do
                for i, key in ipairs(dissolveInfo.materialKeys) do
                    local start = dissolveInfo.materialStartValues[i]
                    local target = dissolveInfo.materialTargetValues[i]
                    if start ~= nil and target ~= nil then
                        mat:SetR32(key, start + (target - start) * alpha)
                    end
                end
            end
        end, 0, 1, dissolveInfo.animTime or self:GetDissolveTime(), Tween.Easing.EaseInQuad)

        Tween:AddTweenComplete(tweenId, function()
            if callback ~= nil then
                callback()
            end
        end)
    else
        -- 恢复描边
        self:EnableOutlines(materials, dissolveInfo.controlName or "DISSOLVE")
    end
end

--模型alpha
function CNpc:BuffEvent_TargetAlpha(buff, params)
    if self.node == nil then
        return
    end

    self.startTargetAlpha = function()
        self:SetCharacterAlpha(params.duration, params.minAlpha, params.maxAlpha)
    end

    -- 延迟
    if params.delay ~= nil and params.delay > 0 then
        self:DelayCall(self.startTargetAlpha, params.delay)
    else
        self.startTargetAlpha()
    end
end

--材质修改
function CNpc:BuffEvent_ShaderModify(buff, params)
    self:SkillEvent_ShaderModify(buff, params, true)
end

--材质切换
function CNpc:BuffEvent_ShaderSwitch(buff, params)
    self:SkillEvent_ShaderSwitch(buff, params, true)
end

function CNpc:initTitleText(bmFont, bmPng, defaultText, bMText)
    
end

--头顶飘字
function CNpc:BuffEvent_ShowTitle(buff, params)
    if self.node == nil then
        return
    end

    self.startShowTitle = function()
        if params.duration == nil or params.duration <= 0 then
            return
        end
        local titleText = self:initTitleText(params.bmFont, params.bmPng, params.defaultText, params.bMText)
        if titleText ~= nil then
            titleText.Visible = true
            local boundBox = self.node.Size
            if params.hasPositionOffset then
                local position = params.localPosition
                titleText.Offset = Vector3.New(position.x, boundBox.y + position.y, position.z)
            else
                titleText.Offset = Vector3.New(0, boundBox.y, 0)
            end
            titleText:FollowTarget(self.node)
        end

        TimerManager:AddTimer(function()
            if titleText ~= nil then
                titleText.Visible = false
                titleText:FollowTarget(nil)
            end
        end,params.duration,1)
    end

    -- 延迟
    if params.delay ~= nil and params.delay > 0 then
        self:DelayCall(self.startShowTitle, params.delay)
    else
        self.startShowTitle()
    end
end

function CNpc:CheckShowOff()
    
end

return CNpc