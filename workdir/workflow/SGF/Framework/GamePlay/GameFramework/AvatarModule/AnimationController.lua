local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local AnimSpeedSet = GFScript("ActorModule.Action.AnimSpeedSet")
local AvatarNetProto = GFScript("AvatarModule.AvatarNetProto")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")

local AnimationController = Class.New("AnimationController", ActorComponent)

--运动状态
local ELocomotionType = {
    Ground = "Ground",
    Fly = "Fly",
    Swim = "Swim",
}

--运动状态枚举

local EMovementState = {
    Idle = "Idle    ",      -- 空闲
    Walk = "Walk",      -- 行走
    Trot = "Trot",      -- 小跑
    Run = "Run",        -- 跑步
    Sprint = "Sprint",  -- 冲刺
    Jump = "Jump",      -- 跳跃
    Fall = "Fall",      -- 下落
    Stun = "Stun",      -- 眩晕
    Die = "Die",        -- 死亡
    Sleep = "Sleep",     -- 睡眠
}

--构造函数
function AnimationController:Constructor()
    self.updateEnabled = true
    self.animator = nil
    self.currentStateName = ""
    self.currentVelocity = Vec3.zero()

    self.currentSpeed = 1.0

    --速度缩放
    self.speedScale = nil
    self.speedScaleDuration = 0.0
    
    self.locomotionType = ELocomotionType.Ground           -- 当前运动状态

    self.locomotionName = "Idle"

    --移动动作的移动距离
    self.moveDistances = 
    {
        Ground = {
            Walk = 450,
            Trot = 450,
            Run = 450,
            Sprint = 450,
        }
    }

    self.useSystemLogic = false
end
function AnimationController:Destructor()
    if self._UpdateAssetNotifyEvent then
        self._UpdateAssetNotifyEvent:Disconnect()
        self._UpdateAssetNotifyEvent = nil
    end
    if self._EventNotifyEvent then
        self._EventNotifyEvent:Disconnect()
        self._EventNotifyEvent = nil
    end
end

--当绑定对象设置的时候
function AnimationController:OnBindObjChanged(oldBindObj, newBindObj)
    if newBindObj then
        self.animator = newBindObj:GetAnimator()
    end

    if self.animator then
        --关闭animator的动画同步
        -- self.animator.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        -- self.animator.LocalSyncFlag = Enum.NodeSyncLocalFlag.ENABLE
    end
    
    if self:IsServer() then
        
    else
        if self._UpdateAssetNotifyEvent then
            self._UpdateAssetNotifyEvent:Disconnect()
            self._UpdateAssetNotifyEvent = nil
        end
        if self._EventNotifyEvent then
            self._EventNotifyEvent:Disconnect()
            self._EventNotifyEvent = nil
        end
        if newBindObj then
            if self.animator then
                self._UpdateAssetNotifyEvent = self.animator.UpdateAssetNotify:Connect(function(url, state)
                    if state then
                        --动作初始化完毕
                        self.actor:FireClient("AnimationLoadFinished")
                        self._EventNotifyEvent = self.animator.EventNotify:Connect(function(node, stateName, layerIndex, state)
                            if state == Enum.StateMachineMessage.kOnStateEnter then
                                self.currentStateName = stateName
                            end
                        end)
                    end
                end)
            end
        end
    end
end

function AnimationController:SetUseSystemLogic(use)
    self.useSystemLogic = use
    if self:IsServer() then
        self:RpcUseSystemLogic(use)
    end
    if not self.useSystemLogic then
        self.animator.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    else
        self.animator.LocalSyncFlag = Enum.NodeSyncLocalFlag.ENABLE
    end
end

function AnimationController:IsUseSystemLogic()
    return self.useSystemLogic
end

--启动服务端
function AnimationController:OnStartServer()
    
end

--启动客户端
function AnimationController:OnStartClient()

end

function AnimationController:UpdateClient(dt)
    local actor = self.actor
    if actor then
        local pos = actor:GetPosition()
        if self.prevPos then
            local velocity = (pos - self.prevPos) / dt
            self.currentVelocity = velocity
        end
        self.prevPos = pos
    end


    if self.speedScale then
        self.speedScaleDuration = self.speedScaleDuration - dt
        if self.speedScaleDuration <= 0.0 then
            self.speedScale = nil
        end
    end

    self:UpdateAnimSpeed()

    if self.montageName then
        self:UpdateMontage(dt)
    end
end

function AnimationController:UpdateServer(dt)
    -- if self:HasServerAnimAuthority() then
    --     if self.montageName then
    --         self:UpdateMontage(dt)
    --     end
    -- end
end


function AnimationController:GetLocomotionType()
    return self.locomotionType
end

--设置运动状态
function AnimationController:SetLocomotionType(state)
    self.locomotionType = state
    if self:IsServer() then
        self:RpcSetLocomotionType(state)
    else
        self:CheckLocomotionToPlay()
    end
end

function AnimationController:IsLocomotionType(state)
    return self.locomotionType == state
end

function AnimationController:PlayLocomotion(name, serverCall)
    if self:IsServer() then
        if not self:IsUseSystemLogic() then
            self:RpcPlayLocomotion(name)
            return
        end
    end

    self.locomotionName = name
    self:CheckLocomotionToPlay()

    if not self:IsUseSystemLogic() then
        if not serverCall and self:HasClientAnimAuthority() then       
            self:CmdOtherPlayLocomotion(name)
        end
    end
end

function AnimationController:StopLocomotion(serverCall)
    if self:IsServer() then
        if not self:IsUseSystemLogic() then
            self:RpcStopLocomotion()
            return
        end
    end
    self.locomotionName = "Idle"
    self:CheckLocomotionToPlay()
    
    if not self:IsUseSystemLogic() then
        if not serverCall and self:HasClientAnimAuthority() then
            self:CmdOtherStopLocomotion()
        end
    end
end

function AnimationController:PlayMontage(name, force, finishedCallback, serverCall)
    if self:IsServer() then
        if not self:IsUseSystemLogic() then
            self:RpcPlayMontage(name)
            return
        end
    end

    if not force and self.montageName == name then
        if self.montageFinishedCallback then
            self.montageFinishedCallback()
        end
        return
    end

    self.montageName = name
    self.montageFinishedCallback = finishedCallback
    self.lastFrameTime = 0
    self.currentTime = 0
    self.montageLength = self:GetMontageLength(name)

    self:PlayAnimImpl(self.montageName, 0, 0, true)
    
    
    if not self:IsUseSystemLogic() then
        if not serverCall and self:HasClientAnimAuthority() then
            self:CmdOtherPlayMontage(name)
        end
    end
end

function AnimationController:StopMontage(serverCall)
    if self:IsServer() then
        if not self:IsUseSystemLogic() then
            self:RpcStopMontage()
            return
        end
    end
    self.montageName = nil
    self.montageFinishedCallback = nil
    self.lastFrameTime = 0
    self.currentTime = 0
    self.montageLength = 0
    self:CheckLocomotionToPlay()
    
    if not self:IsUseSystemLogic() then
        if not serverCall and self:HasClientAnimAuthority() then
            self:CmdOtherStopMontage()
        end
    end
end

function AnimationController:UpdateMontage(dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.montageLength * 0.95 then

        if self.montageFinishedCallback then
            self.montageFinishedCallback()
        end

        self.montageName = nil
        self.montageFinishedCallback = nil
        self.lastFrameTime = 0
        self.currentTime = 0
        self.montageLength = 0
        
        self:CheckLocomotionToPlay()
    end
end

function AnimationController:GetMontageLength(name)
    if self:IsServer() then
        return 0
    end
    return self:GetAnimLength(name)
end

function AnimationController:NormalLocomotionName(name)
    if self.locomotionType == ELocomotionType.Ground then
        return name
    end
    return self.locomotionType..name
end

function AnimationController:CheckLocomotionToPlay()
    if Utils:IsNullOrEmpty(self.montageName) then    
        self:PlayAnimImpl(self:NormalLocomotionName(self.locomotionName), 0, 0, true)
    end
end

-----------------------------Animator--------------------------------
--是否有动画权限
function AnimationController:HasAnimAuthority()
    if self:IsServer() then
        return self:HasServerAnimAuthority()
    end
	return self:HasClientAnimAuthority()
end

--是否有服务器动画权限
function AnimationController:HasServerAnimAuthority()
    if self:IsServer() then
        return false
    end
	return false
end

--是否有客户端动画权限
function AnimationController:HasClientAnimAuthority()
    if self:IsClient() then
        return self.actor:IsOwnerLocalPlayer()
    end
	return false
end

--获取动画状态机
function AnimationController:GetAnimator()
    if not self.animator then
        Log:Error("AnimationController::animator is nil...")
    end
    return self.animator
end

--播放动画
function AnimationController:PlayAnim(name, layer, normalized, force)
    self:PlayLocomotion(name)
end


--播放主机动画
function AnimationController:PlayOwnerAnim(name, layer, normalized, force)
    if self.actor:IsOwnerLocalPlayer() then   
        self:PlayAnim(name, layer, normalized, force)
    end
end

function AnimationController:PlayAnimImpl(name, layer, normalized, force)
    if self:IsServer() then
        Log:Error("AnimationController::PlayAnim is server...")
        return
    end
    if name == nil then
        return
    end
    self.currentStateName = name
    layer = layer or 0
    normalized = normalized or 0
    transitionTotal = transitionTotal or 0.1
    transitionOffset = transitionOffset or 0
    self:CrossFadeAnim(name, layer, transitionTotal, transitionOffset)
end

--混合播放动画
function AnimationController:CrossFadeAnim(stateName, layer, transitionTotal, transitionOffset)
    if self.animator then
        self.currentStateName = stateName
        layer = layer or 0
        transitionTotal = transitionTotal or 0.1
        transitionOffset = transitionOffset or 0
        self.animator:CrossFade(stateName, layer, transitionTotal, transitionOffset)
    end
end

--停止动画
function AnimationController:StopAnim(name, layer)
    if name == nil then
        return
    end
    layer = layer or 0
    self:PlayAnimImpl("Idle", layer)
end

--是否正在播放某个动画
function AnimationController:IsPlayingAnim(name)
    if name == nil then
        return
    end
    if self.animator then
        return self.currentStateName == name
    end
    return false
end

--获取播放的时间点
function AnimationController:GetCurrentAnimTimePos(layer)
    layer = layer or 0
    if self.animator then
        return self.animator:GetCurrentStatePlayedTime(layer)
    end
    return 0
end

--获取当前动画名称
function AnimationController:GetCurrentStateName()
    return self.currentStateName
end

--获取动画控制器
function AnimationController:GetAnimControllerAssetName()
    if self.animator then
        return self.animator.ControllerAsset
    end
    return ""
end

--设置动画控制器
function AnimationController:SetAnimControllerUrl(url)
    if self.animator then
        self.animator.ControllerAsset = url
    end
end

--设置动画控制器
function AnimationController:SetAnimControllerAssetName(name)
    if self.animator then
        self.animator:UpdateControllerAsset(Enum.AssetResType.AnimController, name)
    end
end

--设置动画控制器资源
function AnimationController:SetAnimAsset(node)
    if self.animator then
        self.animator:SetControllerAsset(node)
    end
end

--更新动画控制器资源
function AnimationController:UpdateAnimAsset(assetResType, url)
    if self.animator then
        self.animator:UpdateControllerAsset(assetResType, url)
    end
end

--获取动画层级权重
function AnimationController:GetAnimLayerWeight(layer)
    if self.animator then
        return self.animator:GetLayerWeight(layer)
    end
end

--设置动画层级权重
function AnimationController:SetAnimLayerWeight(layer, weight)
    if self.animator then
        self.animator:SetLayerWeight(layer, weight)
    end
end

function AnimationController:GetState(stateName, layerIdx, layerName)
    if self.animator then
        local layer = self.animator.controller:GetStateMachine(layerIdx)
        local state = layer:GetState(layerName.. '.' .. stateName)
        return state
    end
    return nil
end

--设置动画速度
function AnimationController:SetAnimSpeed(speed)
    speed = speed or 1.0
    if self.animator then
        self.animator.Speed = speed
    end
end

--获取动画速度
function AnimationController:GetAnimSpeed()
    if self.animator then
        return self.animator.Speed
    end
    return 1.0
end

function AnimationController:UpdateAnimSpeed()
    if self.actor.AvatarComponent:IsMoving() then
        local moveSpeed = self.actor.AvatarComponent:GetFinalMoveSpeed()
        local scale = self.actor:GetScale().x
        local moveDistance = 450
        if self.moveDistances[self.locomotionType] then
            moveDistance = self.moveDistances[self.locomotionType]
            if moveDistance[self.locomotionName] then
                moveDistance = moveDistance[self.locomotionName]
            else
                moveDistance = 450
            end
        end
        self:SetAnimSpeed(moveSpeed / scale / moveDistance)
    else
        self:SetAnimSpeed(1.0)
    end
end

--顿帧后恢复
function AnimationController:PauseResumeAnimDelay(delayTime, speed)
    if self.animator and self.currentStateName then
        local animSpeedSet = AnimSpeedSet.New()
        animSpeedSet:Init(delayTime, speed or 0.1)
        animSpeedSet:SetTag("AnimSpeedSet")
        self.actor:RunAction(animSpeedSet)
    end
end

--获取当前播放的动画时间
function AnimationController:GetAnimTime(name)
    if self.animator and name then
        return self.animator:GetStatePlayedTime(self:NormalStateName(name))
    end
end

--获取动画长度
function AnimationController:GetAnimLength(name)
    if self.animator and name then
        return self.animator:GetClipLength(self:NormalStateName(name))
    end
    return 0
end

function AnimationController:NormalStateName(name)
    if Utils:StartWith(name,"Base Layer.") then
        return name
    end
    return "Base Layer."..name
end

-----------------------------------------------------------------------

--序列化
function AnimationController:Serialize(data, purpose)
    AnimationController.super.Serialize(self, data, purpose)
    data.useSystemLogic = self.useSystemLogic
end

--反序列化
function AnimationController:Deserialize(data)
    AnimationController.super.Deserialize(self, data)
    self.useSystemLogic = data.useSystemLogic
end

-------------------------------------Cmd-------------------------------------
function AnimationController:CmdOtherPlayMontage(name)
    self:ORpcPlayMontage(name)
end

function AnimationController:CmdOtherPlayLocomotion(name)
    self:ORpcPlayLocomotion(name)
end

function AnimationController:CmdOtherStopMontage()
    self:ORpcStopMontage()
end

function AnimationController:CmdOtherStopLocomotion()
    self:ORpcStopLocomotion()
end

function AnimationController:CmdPlayMontage(name)
    self:PlayMontage(name, true)
end

function AnimationController:CmdPlayLocomotion(name)
    self:PlayLocomotion(name)
end
-------------------------------------Rpc-------------------------------------
function AnimationController:RpcPlayMontage(name)
    self:PlayMontage(name, true, nil, true)
end
function AnimationController:RpcPlayLocomotion(name)
    self:PlayLocomotion(name, true)
end
function AnimationController:ORpcPlayMontage(name)
    self:PlayMontage(name, true, nil, true)
end
function AnimationController:ORpcPlayLocomotion(name)
    self:PlayLocomotion(name, true)
end

function AnimationController:RpcStopMontage()
    self:StopMontage(true)  
end
function AnimationController:RpcStopLocomotion()
    self:StopLocomotion(true)
end
function AnimationController:ORpcStopMontage()
    self:StopMontage(true)
end
function AnimationController:ORpcStopLocomotion()
    self:StopLocomotion(true)
end

function AnimationController:RpcSetLocomotionType(state)       
    self:SetLocomotionType(state)
end

function AnimationController:RpcUseSystemLogic(use)
    self:SetUseSystemLogic(use)
end

return AnimationController