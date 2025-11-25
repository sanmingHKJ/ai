local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local StateMachine = GFScript("CoreModule.StateMachine")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Color = GFScript("CoreModule.Math.Color")
local Math = GFScript("CoreModule.Math")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local AvatarNetProto = GFScript("AvatarModule.AvatarNetProto")
local AvatarDefines = GFScript("AvatarModule.AvatarDefines")
local TargetUtils = GFScript("CombatModule.TargetUtils")
local ShakeController = GFScript("AvatarModule.ShakeController")
local AnimSpeedSet = GFScript("ActorModule.Action.AnimSpeedSet")
local RotateTo = GFScript("ActorModule.Action.RotateTo")
local WorldService = game:GetService("WorldService")
local GameSetting = game:GetService("GameSetting")
local AnimationController = GFScript("AvatarModule.AnimationController")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local Debugger = GFScript("CoreModule.Debugger")

local AvatarComponent = AnimationController.Extend("AvatarComponent")
--版本号
AvatarComponent.version = 1

--实例化
function AvatarComponent:Constructor()
    self.updateEnabled = true
    self.fixedUpdateInterval = 0.1
    self.preInputDir = Vec3.New(0,0,1)
    self.inputDir = Vec3.New(0,0,1)

    self.locomotionState = AvatarDefines.ELocomotionState.Idle
    
    self.shakeCtrl = ShakeController.New()

    self.moveSpeed = 300
    self.overrideMoveSpeed = 0
    self.rotateSpeed = 180 --旋转速度
    self.height = 180 --高度
    self.radius = 50 --半径

    self.velocity = Vec3.zero()
    self.lastPos = Vec3.zero()

    self.onGround = false
    self.onGroundDirty = false
	self.miniSkinId = 0
    self.miniAnimUrl = ""
    self.miniModelId = ""

    self.autoRotateSmooth = true
    self.autoRotate = true
    self.autoRotateDuration = 0.1

    self.safeMove = 0

    self.moveType = AvatarDefines.EMoveType.Run

    --默认看不见
    self.visibleInAOI = false
    self.visible = true
    self.visibleDirty = true
    --原始缩放大小
    self.orginScale = Vec3.one()
    self.scale = Vec3.one()

    self.hoverCount = 0
    self.isGravityFreeze = false

    --是否使用镜头Yaw
    self.useCameraYaw = false

    --瞄准方向
    self.aimDirection = Vec3.zero()
    self.aimPosition = Vec3.zero()

    self.spreadAngle = 0

end
function AvatarComponent:Destructor()
end

function AvatarComponent:CopyFrom(other)
    AvatarComponent.super.CopyFrom(self,other)
    self.moveSpeed = other.moveSpeed
    self.overrideMoveSpeed = other.overrideMoveSpeed
    self.rotateSpeed = other.rotateSpeed
    self.height = other.height
    self.radius = other.radius
    self.onGround = other.onGround
    self.avatarPartGroup = other.avatarPartGroup
    self.miniSkinId = other.miniSkinId
    self.miniModelId = other.miniModelId
    self.miniAnimUrl = other.miniAnimUrl
    self.moveType = other.moveType

    -- self.visibleInAOI = other.visibleInAOI
    -- self.visible = other.visible
    -- self.visibleDirty = true

    self.orginScale = other.orginScale:Clone()
    self.scale = other.scale:Clone()
    
    if other.backupGravity then
        local character = self.actor:GetCharacter()
        character.Gravity = other.backupGravity
    end
end

--震动
function AvatarComponent:StartShake(name)
    self.shakeCtrl:Start(name)
end
--开始持续震动
function AvatarComponent:StartShakeLoop(name)
    self.shakeCtrl:StartLoop(name)
end
--停止持续震动
function AvatarComponent:StopShakeLoop(name)
    self.shakeCtrl:StopLoop(name)
end
--淡出震动
function AvatarComponent:StopShakeFade(name)
    self.shakeCtrl:StopFade(name)
end

--停止震动
function AvatarComponent:StopShake(name)
    self.shakeCtrl:Stop(name)
end

--停止全部
function AvatarComponent:StopAllShake()
    self.shakeCtrl:StopAll()
end

function AvatarComponent:ShakeUpdate(dt)
    if not self.shakeCtrl:HasAnyShake() then
        return
    end
    local shakeRotData = self.shakeCtrl:GetRotDelta()
    local shakePosData = self.shakeCtrl:GetPosDelta()
    local rot = self:GetRotation()
    local pos = self:GetPosition()

    local euler = rot:ToEuler()
    euler.x = euler.x - shakeRotData.x
    euler.y = euler.y - shakeRotData.y

    pos = pos - shakePosData

    self.shakeCtrl:Update(dt)

    if self.shakeCtrl:IsShaking() then
        shakeRotData = self.shakeCtrl:GetRotDelta()
        shakePosData = self.shakeCtrl:GetPosDelta()
        euler.x = euler.x + shakeRotData.x
        euler.y = euler.y + shakeRotData.y
        local rot = Quat.New()
        rot:FromEuler(euler)
        self:SetRotation(rot)

        pos = pos + shakePosData
        self:ForceSetPosition(pos)
    end
end
--是否正在震动
function AvatarComponent:IsShaking()
    return self.shakeCtrl:IsShaking()
end

--设置所属节点
function AvatarComponent:SetActor(actor)
    AvatarComponent.super.SetActor(self,actor)
    if not actor then
        return
    end
    local character = self.actor:GetCharacter()
    self.moveSpeed = character.Movespeed
    self.overrideMoveSpeed = 0

    self.autoRotateSmooth = false --actor:IsPlayer()
    if self.autoRotateSmooth then
        character.AutoRotate = false
    end
end
--当绑定对象设置的时候
function AvatarComponent:OnBindObjChanged(oldBindObj, newBindObj)
    AvatarComponent.super.OnBindObjChanged(self, oldBindObj, newBindObj)
    if self:IsServer() then
        if newBindObj then
            local state = AvatarDefines.NormalLocomotionState(newBindObj)
            self.locomotionState = state
        end
    else
        if newBindObj and self:IsOwned() then
            local state = AvatarDefines.NormalLocomotionState(newBindObj)
            local body = {
                state = AvatarDefines.EncodeLocomotionState(state),
            }
            self:SendToServer(AvatarNetProto.RequestLocomotionState, body)
            self.locomotionState = state
        end
        
    end

    if newBindObj then
        local scale = newBindObj.LocalScale
        self.orginScale = Vec3.New(scale.x,scale.y,scale.z)
    end

    self.visibleDirty = true

end
--启动服务端
function AvatarComponent:OnStartServer()
    --监听网络事件
    self:ServerNetCallback(AvatarNetProto.RequestInputDir, self.OnRequestInputDir, self)
    self:ServerNetCallback(AvatarNetProto.RequestLocomotionState, self.OnRequestLocomotionState, self)
    self:ServerNetCallback(AvatarNetProto.RequestPoseState, self.OnRequestPoseState, self)
    self:ServerNetCallback(AvatarNetProto.RequestMoveType, self.OnRequestMoveType, self)
    self:ServerNetCallback(AvatarNetProto.RequestMoveSpeed, self.OnRequestMoveSpeed, self)
end
--启动客户端
function AvatarComponent:OnStartClient()
    --监听网络事件
    self:ClientNetCallback(AvatarNetProto.ResponseLocomotionState, self.OnResponseLocomotionState, self)
    self:ClientNetCallback(AvatarNetProto.ResponsePoseState, self.OnResponsePoseState, self)
    self:ClientNetCallback(AvatarNetProto.ResponseVelocity, self.OnResponseVelocity, self)
    self:ClientNetCallback(AvatarNetProto.ResponsePlayAnim, self.OnResponsePlayAnim, self)
    self:ClientNetCallback(AvatarNetProto.ResponseStopAnim, self.OnResponseStopAnim, self)
    self:ClientNetCallback(AvatarNetProto.ResponseMoveType, self.OnResponseMoveType, self)
    self:ClientNetCallback(AvatarNetProto.ResponseMoveSpeed, self.OnResponseMoveSpeed, self)
    self:ClientNetCallback(AvatarNetProto.ResponseVisible, self.OnResponseVisible, self)

    self.actor:OnClientEvent("CameraUpdated", function(CameraController)
        --更新瞄准方向
        if self.actor:IsLocalPlayer() and self.actor.CameraController then
            local aimDir, aimPosition = self.actor.CameraController:GetAimDirection()
            if not aimPosition:Equals(self.aimPosition, 5) then
                self:SetAimDirection(aimDir)
                self:SetAimPosition(aimPosition)
            end
        end

        if self.useCameraYaw then
            local camera = self.actor.CameraController
            local cameraForward = camera:GetForward()
            -- 获取摄像机位置
            local cameraPos = camera:GetPosition()
            local characterPos = self:GetPosition()
            -- 计算摄像机到角色的方向
            local cameraToChar = characterPos - cameraPos
            cameraToChar.y = 0 -- 忽略高度差
            cameraToChar:Normalize()
            
            -- 计算准心方向（摄像机前方）
            local aimDir = cameraForward
            aimDir.y = 0 -- 忽略高度差
            aimDir:Normalize()
            
            -- 计算角色应该朝向的方向
            local targetDir = aimDir
            -- 如果摄像机在侧面，调整目标方向
            local dot = cameraToChar:Dot(aimDir)
            if dot < 0.7 then -- 当摄像机在侧面时（夹角大于45度）
                -- 根据摄像机位置调整目标方向
                local right = cameraToChar:Cross(Vec3.New(0, 1, 0))
                if right:Dot(aimDir) > 0 then
                    targetDir = right
                else
                    targetDir = -right
                end
            end
            
            -- 设置角色朝向
            self:LookAtPos(self:GetPosition() + targetDir * 100)
        end
    end)
end
--更新
function AvatarComponent:Update(dt)
    AvatarComponent.super.Update(self,dt)
    if not self:IsServer() then 
        if self.visibleDirty then
            self:UpdateVisible()
        end
    end

    if self.moveTargetActor then
        if Class.IsExpired(self.moveTargetActor) then
            self:StopMove()
        else
            self:MoveToTarget(self.moveTargetActor, self.moveCallback, self.moveErrorDistance)
        end
    end

    if self.moveTargetPos and self.moveCallback then
        if self.moveTargetPos:Distance(self:GetPosition()) <= (self.moveErrorDistance or 10) then
            self.moveCallback()
            self.moveTargetPos = nil
            self.moveErrorDistance = nil
            self.moveCallback = nil
        end
    end
end
--更新服务端
function AvatarComponent:UpdateServer(dt)
    AvatarComponent.super.UpdateServer(self,dt)
    if not self:IsPlayer() then
        local character = self.actor:GetCharacter()
        local state = AvatarDefines.NormalLocomotionState(character)
        if state ~= self.locomotionState then
            self:OnLocomotionStateChanged(state)
            self.locomotionState = state
        end
    end
    if self.locomotionState ~= AvatarDefines.ELocomotionState.Idle then
        local curPos = self:GetPosition()
        if self.lastPos ~= curPos then
            local posDelta = curPos - self.lastPos
            self.lastPos = curPos
            self:SetVelocity(posDelta / dt)
        end
    end
    
    if self.onGroundDirty then
        self:UpdateOnGround()
    end
    
end
--更新客户端
function AvatarComponent:UpdateClient(dt)
    AvatarComponent.super.UpdateClient(self,dt)
    --震动更新
    self:ShakeUpdate(dt)
    
    if self:IsOwned() then
        local character = self.actor:GetCharacter()
        local state = AvatarDefines.NormalLocomotionState(character)
        if state ~= self.locomotionState then
            local body = {
                state = AvatarDefines.EncodeLocomotionState(state),
            }
            self:SendToServer(AvatarNetProto.RequestLocomotionState, body)
            self.locomotionState = state
        end

        
    end

    -- if self:IsLocalPlayer() then
    --     local euler = self.actor.CameraController:GetRotation():ToEuler()
    --     local cQuat = Quat.identity()
    --     cQuat:FromEuler({x = euler.x, y = euler.y + 180, z = euler.z })
    --     Debugger:DrawBox(self:ComputeOffsetPosition(cQuat, Vec3.New(500,100,0)), self:GetRotation(), Vec3.New(100, 100, 100), Color.New(1, 0, 0, 1), 1)
    -- end
end
--更新服务端
function AvatarComponent:FixedUpdateServer(dt)
    
end
--运动状态改变
function AvatarComponent:OnLocomotionStateChanged(state)
    if self:IsServer() then
        if state == AvatarDefines.ELocomotionState.Idle then
            self:SetVelocity(Vec3.zero())
        end
    end
end
--开始安全移动
function AvatarComponent:StartSafeMove()
    self.safeMove = self.safeMove + 1
    if self.safeMove == 1 then
        --记录安全位置
        self.safePos = self:GetPosition()
    end
end
--结束安全移动
function AvatarComponent:EndSafeMove()
    self.safeMove = self.safeMove - 1
    if self.safeMove == 0 then
        --恢复安全位置
        self:TeleportTo(self.safePos)
    end
end
--强行设置位置
function AvatarComponent:ForceSetPosition(x,y,z)
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end
    local character = self.actor:GetCharacter()
    character.Position = Vector3.New(x,y,z)
end
--设置位置
function AvatarComponent:SetPosition(x,y,z, checkCollision)
    if self.safeMove == 0 then
        -- Log:Warn("Position change is not safe!")
    end
    checkCollision = checkCollision or false
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end
    local newPos = Vec3.New(x,y,z)
    if self.safeMove > 0 then
        local safePos, isSafe = Utils:GetValidHorizontalPosition(self:GetPosition(), newPos)
        if not isSafe then
            newPos = safePos
        else
            self.safePos = safePos
        end
    end
    local character = self.actor:GetCharacter()
    if checkCollision then
        --滑墙运动
        local finalPos = Utils:CalcSlidePosition(self:GetPosition(), newPos, self:GetCharacterRadius())
        character.Position = Vector3.New(finalPos.x,finalPos.y,finalPos.z)
    else
        character.Position = Vector3.New(newPos.x,newPos.y,newPos.z)
    end
    self.onGroundDirty = true
end

--获取位置
function AvatarComponent:GetPosition()
    local character = self.actor:GetCharacter()
    local position = character.Position
    return Vec3.New(position.x,position.y,position.z)
end

--变换
function AvatarComponent:Translate(x,y,z)
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end
    local pos = self:GetPosition()
    pos.x = pos.x + x
    pos.y = pos.y + y
    pos.z = pos.z + z
    self:ForceSetPosition(pos)
end
--传送
function AvatarComponent:TeleportTo(pos, rot)
    Utils:TeleportTo(self.actor:GetCharacter(), pos)
    if rot then
        self:SetRotation(rot)
    end
    
    if self.actor.PetComponent and self.actor.PetComponent.showPet then
        local showPet = self.actor.PetComponent.showPet
        Utils:TeleportTo(showPet:GetCharacter(), pos)
        if rot then
            showPet:SetRotation(rot)
        end
    end

    self.onGroundDirty = true
end

-- 传送到地面
function AvatarComponent:TeleportToGround(pos)
    local groundPos = self:GetGroundPosition(pos)
    self:TeleportTo(groundPos)
end

--获取前方向
function AvatarComponent:GetForward()
    local character = self.actor:GetCharacter()
    -- local forward = character.Rotation * Vector3.New(0,0,1)
    local forward = character.Rotation:LookDir()
    return Vec3.New(forward.x,forward.y,forward.z) * -1
end
--获取右方向
function AvatarComponent:GetRight()
    local character = self.actor:GetCharacter()
    local right = character.Rotation * Vector3.New(1,0,0)
    return Vec3.New(right.x,right.y,right.z)
end

--获取移动速率
function AvatarComponent:GetVelocity()
    return self.velocity
end

--设置速率
function AvatarComponent:SetVelocity(vel)
    self.velocity = vel
    if self:IsServer() then
        local body = {
            velocity = vel:ToTable()
        }
        self:SendToObservers(AvatarNetProto.ResponseVelocity,body)
    end
end

--获取缩放
function AvatarComponent:GetScale()
    return self.scale
end
--设置缩放
function AvatarComponent:SetScale(x,y,z)
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end

    if self.scale:Equals(Vec3.New(x,y,z)) then
        return
    end
    self.scale = Vec3.New(x,y,z)
    self:UpdateCharacterScale()
end

function AvatarComponent:UpdateCharacterScale()
    local character = self.actor:GetCharacter()
    local finalScale = self:GetEffectiveScale()
    character.LocalScale = Vector3.New(finalScale.x,finalScale.y,finalScale.z)
end

--获取有效缩放
function AvatarComponent:GetEffectiveScale()
    return self.orginScale * self.scale
end

--获取模型的包围盒大小
function AvatarComponent:GetSize()
    local character = self.actor:GetCharacter()
    local size = character.Size
    return Vec3.New(size.x,size.y,size.z)
end
--设置模型的包围盒大小
function AvatarComponent:SetSize(x,y,z)
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end
    local character = self.actor:GetCharacter()
    character.Size = Vector3.New(x,y,z)
end

--获取模型的中心点所在世界坐标
function AvatarComponent:GetCenter()
    local character = self.actor:GetCharacter()
    local center = character.Center
    return Vec3.New(center.x,center.y,center.z)
end
--设置模型的中心点所在世界坐标
function AvatarComponent:SetCenter(x,y,z)
    if type(x) ~= "number" then
        y = x.y
        z = x.z
        x = x.x
    end
    local character = self.actor:GetCharacter()
    character.Center = Vector3.New(x,y,z)
end

--设置玩家可以攀越的高度
function AvatarComponent:SetStepOffset(stepOffset)
    stepOffset = stepOffset or 10
    local character = self.actor:GetCharacter()
    character.StepOffset = stepOffset
end

--获取半径
function AvatarComponent:GetCharacterRadius()
    local character = self.actor:GetCharacter()
    if character.Size.y <= character.Size.x then
        return (character.Size.y - 0.1) / 2
    end
    return character.Size.x / 2
end
--获取高度
function AvatarComponent:GetCharacterHeight()
    local character = self.actor:GetCharacter()
    return character.Size.y
end
--获取输入方向
function AvatarComponent:GetInputDir()
    return self.inputDir
end

--计算偏移位置
function AvatarComponent:ComputeOffsetPosition(rotation, offset)
    local pos = self:GetPosition()
    if offset then
        local quat180 = Quat.New()
        quat180:FromDirection(Vec3.New(0,0,-1))
        local orientOffset = quat180 * offset
        return pos + rotation * orientOffset
    end
    return pos
end

--根据offset获取位置, 前方的话offset的z为正1
function AvatarComponent:GetOffsetPosition(offset)
    return self:ComputeOffsetPosition(self:GetRotation(), offset)
end
--获取偏移旋转
function AvatarComponent:GetOffsetRotation(angleY)
    local rot = self:GetRotation()
    local quat180 = Quat.New()
    quat180:FromEuler({x = 0, y = angleY, z = 0})
    return rot * quat180
end

--获取落点位置
function AvatarComponent:GetGroundPosition(worldPos)
    local pos = worldPos or self:GetPosition()
    self.actor:EnableOverlap(true)
    local groundPos = Utils:GetGroundPosition(pos)
    self.actor:EnableOverlap(false)
    return groundPos
end
--获取合法的位移位置
function AvatarComponent:GetValidPosition(worldPos)
    local orginPos = self:GetPosition()
    worldPos.y = orginPos.y
    self.actor:EnableOverlap(true)
    local groundPos = Utils:GetValidPosition(orginPos,worldPos)
    self.actor:EnableOverlap(false)
    return groundPos
end

--是否正在地面上
function AvatarComponent:IsOnGround()
    if self.onGroundDirty then
        self:UpdateOnGround()
    end
    return self.onGround
end

function AvatarComponent:UpdateOnGround()
    local oldOnGround = self.onGround
    local groundPos = self:GetGroundPosition()
    local curPos = self:GetPosition()
    local isOnGround = curPos.y - groundPos.y < 5
    if oldOnGround ~= isOnGround then
        if isOnGround then
            --修正位置
            self:TeleportTo(Vec3.New(curPos.x, groundPos.y, curPos.z))
        end
        self.onGround = isOnGround
        self.actor:OnGroundChanged(isOnGround)
    else
    end
    self.onGroundDirty = false
end

--获取旋转四元数
function AvatarComponent:GetRotation()
    local character = self.actor:GetCharacter()
    local rot = character.Rotation
    return Quat.New(rot.w,rot.x,rot.y,rot.z)
end

--设置旋转四元数
function AvatarComponent:SetRotation(quat)
    local character = self.actor:GetCharacter()
    character.Rotation = Quaternion.New(quat.x,quat.y,quat.z,quat.w)
end

--设置方向
function AvatarComponent:SetDirection(dir)
    local orient = Quat.New()
    orient:FromDirection(dir)
    self:SetRotation(orient)
end

--计算距离
function AvatarComponent:Distance(otherAvatar)
    local selfPos = self:GetPosition()
    local targetPos = otherAvatar:GetPosition()
    return selfPos:Distance(targetPos)
end

--判断是否在左边
function AvatarComponent:IsAtLeft(targetPos)
    local dir = self:CalcDirection(targetPos)
    return dir:Dot(self:GetRight()) < 0
end
--是否在右边
function AvatarComponent:IsAtRight(targetPos)
    local dir = self:CalcDirection(targetPos)
    return dir:Dot(self:GetRight()) >= 0
end

--设置重力启用
function AvatarComponent:SetGravityEnable(enable)
    -- if self.isGravityFreeze then
    --     -- 冻结重力
    --     return
    -- end
    -- local character = self.actor:GetCharacter()
    -- local enableGravity = self.hoverCount <= 0 and enable

    -- if enableGravity then
    --     if self.backupGravity then
    --         character.Gravity = self.backupGravity
    --     end
    -- else
    --     if not self.backupGravity then
    --         self.backupGravity = character.Gravity
    --     end
    --     character.Gravity = 0
    -- end
end

--获取重力启用
function AvatarComponent:GetGravityEnable()
    local character = self.actor:GetCharacter()
    return character.Gravity ~= 0
end

--增加悬浮计数
function AvatarComponent:AddHoverCount()
    self.hoverCount = self.hoverCount or 0
    self.hoverCount = self.hoverCount + 1
end
--减少悬浮计数
function AvatarComponent:ReduceHoverCount()
    self.hoverCount = self.hoverCount or 0
    self.hoverCount = self.hoverCount - 1
end
--恢复重力
function AvatarComponent:ResumeGravity()
    self.hoverCount = 0
    local character = self.actor:GetCharacter()
    if character ~= nil and self.backupGravity then
        character.Gravity = self.backupGravity
    end
end
--冻结重力不允许操作
function AvatarComponent:FreezeGravity()
    self.isGravityFreeze = true
    self:ResumeGravity()
end
--设置移动速度
function AvatarComponent:SetMoveSpeed(speed)
    self.moveSpeed = speed
    self:UpdateMoveSpeed()
end

--获取移动速度
function AvatarComponent:GetMoveSpeed()
    return self.moveSpeed
end

--设置重写的移动速度
function AvatarComponent:SetOverrideMoveSpeed(speed, isSync)
    local isSync = isSync ~= false
    self.overrideMoveSpeed = speed or 0

    -- 是否同步或速度不一致
    if isSync then
        local body = {
            overrideMoveSpeed = self.overrideMoveSpeed
        }
        if self:IsServer() then
            -- self.actor:Say("SetOverrideMoveSpeed server:" .. tostring(self.overrideMoveSpeed))
            self:SendToObservers(AvatarNetProto.ResponseMoveSpeed, body)
        else
            -- print("SetOverrideMoveSpeed client:" .. tostring(self.overrideMoveSpeed))
            self:SendToServer(AvatarNetProto.RequestMoveSpeed, body)
        end
    end
    self:UpdateMoveSpeed()
end

--获取重写的移动速度
function AvatarComponent:GetOverrideMoveSpeed()
    return self.overrideMoveSpeed
end

--设置跳跃速度
function AvatarComponent:SetJumpSpeed(speed)
    self.jumpSpeed = speed
    self:UpdateJumpSpeed()
end

--获取跳跃速度
function AvatarComponent:GetJumpSpeed()
    return self.jumpSpeed
end

--更新跳跃速度
function AvatarComponent:UpdateJumpSpeed()
    local character = self.actor:GetCharacter()
    character.JumpBaseSpeed = self.jumpSpeed
end

--获取最终跳跃速度

--设置移动类型
function AvatarComponent:SetMoveType(moveType)
    self.moveType = moveType
    if self:IsServer() then
        self:UpdateMoveSpeed()
        local body = {
            moveType = moveType
        }
        self:SendToObservers(AvatarNetProto.ResponseMoveType, body)
    else
        local body = {
            moveType = moveType
        }
        self:SendToServer(AvatarNetProto.RequestMoveType, body)
    end
end

--获取移动类型
function AvatarComponent:GetMoveType()
    return self.moveType
end

--设置旋转速度
function AvatarComponent:SetRotateSpeed(speed)
    self.rotateSpeed = speed
end
function AvatarComponent:GetRotateSpeed()
    return self.rotateSpeed
end

--设置高度
function AvatarComponent:SetHeight(height)
    self.height = height
end
function AvatarComponent:GetHeight()
    return self.height
end
--设置半径
function AvatarComponent:SetRadius(radius)
    self.radius = radius
end
function AvatarComponent:GetRadius()
    return self.radius
end
function AvatarComponent:GetDerivedRadius()
    return self.scale.x * self.radius
end
--设置半透明
function AvatarComponent:SetAlpha(alpha)
    self.alpha = alpha
    local character = self.actor:GetCharacter()
    
end
--获取透明
function AvatarComponent:GetAlpha()
    return self.alpha or 1
end
--设置显示
function AvatarComponent:SetVisible(visible)
    if self.visible == visible then
        return
    end
    self.visible = visible
    self.visibleDirty = true

    if self:IsServer() then
        --通知客户端
        local body = {
            visible = visible
        }
        self:SendToAllClients(AvatarNetProto.ResponseVisible, body)
    end
end
--获取显示
function AvatarComponent:GetVisible()
    return self.visible or true
end

function AvatarComponent:SetVisibleInAOI(visible)
    if self:IsServer() then
        Log:Error("AvatarComponent:SetVisibleInAOI: Can not set visible in AOI on server")
        return
    end
    if self.visibleInAOI == visible then
        return
    end
    self.visibleInAOI = visible
    self.visibleDirty = true

    self.actor:NotifyAOIVisibleChanged(visible)
end
function AvatarComponent:GetVisibleInAOI()
    return self.visibleInAOI
end
--是否有效可见
function AvatarComponent:IsEffectiveVisible()
    if self:IsServer() then
        return self.visible
    end
    return self.visibleInAOI and self.visible
    -- return self.visible
end

function AvatarComponent:UpdateVisible()
    local visible = self:IsEffectiveVisible()
    local character = self.actor:GetCharacter()
    if character.Visible ~= visible then
        character.Visible = visible
        local name = character.playerInfo3d
        if name then
            name.Visible = visible
        end
        self.actor:NotifyCharacterVisibleChanged(visible)
    end
    self.visibleDirty = false
end



-- todo: 主机和客机都不记录，因为数据只在客机产生，且异步产生，需要一定时间才能获取到皮肤数据
--保存迷你皮肤部件ModelId
-- function AvatarComponent:RecordMiniAvatarMode()
--     local character = self.actor:GetCharacter()
--     if character == nil or character.AvatarPartGroup == nil then
--         return false
--     end
--     self.miniModelId = character.ModelId
--     self.miniSkinId = character.SkinId
--     self.miniAnimUrl = self:GetAnimControllerAssetName()

--     self.avatarPartGroup = {}
--     for _, v in ipairs(character.AvatarPartGroup.Children) do
--         self.avatarPartGroup[v.Name] = v.ModelId
--     end
--     return true
-- end

function AvatarComponent:RenderMiniAvatar(character)
    -- character.StandardSkeleton = Enum.StandardSkeleton.Offical_Player12
    -- character.SkinId = self.miniSkinId
    -- character.ModelId = self.miniModelId

    -- if character.AvatarPartGroup then
    --     for _, v in ipairs(character.AvatarPartGroup.Children) do
    --         if v.Name ~= "FACE" and v.Name ~= "SKIN" then
    --             v.ModelId = self.avatarPartGroup and self.avatarPartGroup[v.Name] or -1
    --         end
    --     end
    -- end
    -- todo: 
    -- 如果没有数据，则这里不会展示任何内容
    character.StandardSkeleton = Enum.StandardSkeleton.Offical_Player12
    character.SkinId = -1
    character.ModelId = ""
    character:BindCustomPlayerSkin(Utils:GetLocalPlayer())
end

function AvatarComponent:RenderOtherAvatar(character, modelId)
    if modelId == nil then
        -- 没有模型id使用迷你皮肤
        self:RenderMiniAvatar(character)
    else
        character.StandardSkeleton = Enum.StandardSkeleton.None
        character.SkinId = -1
        character.ModelId = modelId
        self:ClearAvatarPart(character)
    end
end

function AvatarComponent:ClearAvatarPart(character)
    local group = character.AvatarPartGroup
    if group == nil then
        return
    end
    for i,part in ipairs(group.Children) do
        local name = part.Name
        if name ~= "SKIN" and name ~= "FACE" then
            part.ModelResId = ""
            part.DiffuseTexResId = ""
            part.EmissiveTexResId = ""
            part.ModelId = -1
        end
    end
end

--获取miniModelId
function AvatarComponent:GetMiniModelId()
    return self.miniModelId
end
--获取MiniSkinId
function AvatarComponent:GetMiniSkinId()
    return self.miniSkinId
end
--获取Mini动作url
function AvatarComponent:GetMiniAnimUrl()
    return self.miniAnimUrl
end

-- 播放动画
function AvatarComponent:SetAnimalName(name)
    self.animalName = name
end

-- 设置模型
function AvatarComponent:SetAvatarPart(isMiniSkin, modelId, animUrl, params)
    local character = self.actor:GetCharacter()
    if character == nil then
        return
    end
    
    if isMiniSkin then
        self:RenderMiniAvatar(character)
    else
        self:RenderOtherAvatar(character, modelId)
    end

    if not Utils:IsNullOrEmpty(animUrl) then
        self:SetAnimControllerAssetName(animUrl)
    end

    local function loadComplete()
        if isMiniSkin then
            self:SetAnimLayerWeight(1, 0)
        else
            self:SetAnimLayerWeight(1, 1)
        end
        -- end
        if not Utils:IsNullOrEmpty(self.animalName) then
            self:PlayAnim(self.animalName)
            if self:IsMoving() then
                self:PlayAnim("Run")
            end
            self.animalName = nil
        end
        if params then
            --物理类型：PhysicsRoleType：1：BOX、 2：CAPSULE
            if not Utils:IsNullOrZero(params.physXRoleType) and params.physXRoleType ~= character.PhysXRoleType then
                character.PhysXRoleType = (params.physXRoleType == 1) and Enum.PhysicsRoleType.BOX or Enum.PhysicsRoleType.CAPSULE
            end
            --玩家可以攀越的高度
            if not Utils:IsNullOrZero(params.stepOffset) and params.stepOffset ~= character.StepOffset then
                character.StepOffset = params.stepOffset
            end
            --修改包围盒
            if params.setBoundbox then
                self:SetSize(params.boundboxSize)
                self:SetCenter(params.boundboxCenter)
            end
        end
        self.actor:FireClient("AvatarLoadFinished")
    end

    if character:IsLoadFinish() then
        loadComplete()
    else
        local listener = nil
        listener = character.LoadFinish:connect(function(suc)
            listener:disconnect()
            listener = nil

            loadComplete()
        end)
    end
end

--更新角色实际移动速度
function AvatarComponent:UpdateMoveSpeed()
    local character = self.actor:GetCharacter()
    local speed = 0
    if self.overrideMoveSpeed > 0 then
        speed = self.overrideMoveSpeed
    else
        speed = self.moveSpeed

        if speed > 1000 then
            Log:Error("AvatarComponent:UpdateMoveSpeed 设置过大")
        end
    end
    character.Movespeed = speed
end

--获取最终角色移动速度
function AvatarComponent:GetFinalMoveSpeed()
    local character = self.actor:GetCharacter()
    return character.Movespeed
end

--是否正在跳跃
function AvatarComponent:IsJump()
    return self.locomotionState == AvatarDefines.ELocomotionState.Jump
end

--是否正在飞行
function AvatarComponent:IsFly()
    return self.locomotionState == AvatarDefines.ELocomotionState.Fly
end

--是否正在移动
function AvatarComponent:IsMoving()
    -- local vel = self:GetVelocity()
    -- if vel:Magnitude() > 1 then
    --     return true
    -- end
    -- return false
    -- local character = self.actor:GetCharacter()
    -- if not character.GetCurLocomotionState then
    --     Log:Error("AvatarComponent:GetCurLocomotionState is nil ActorName: %s", self.actor:GetName())
    --     return false
    -- end
    -- local state = character:GetCurLocomotionState()
    -- return state ~= Enum.BehaviorState.Stand and state ~= Enum.BehaviorState.Zero
    return self.locomotionState ~= AvatarDefines.ELocomotionState.Idle
end

--是否可以移动
function AvatarComponent:CanMove()
    return not self.actor:IsDisallowMove()
end
--是否可以输入
function AvatarComponent:CanInput()
    return not self.actor:IsDisallowInput()
end
--移动输入
function AvatarComponent:InputMovement(dir, isLocal)
    
    if not self:CanInput() then
        return
    end
    if self:CanMove() then
        -- 主动触发时重置速度
        if self.overrideMoveSpeed > 0 then
            self:SetOverrideMoveSpeed(0, true)
        end
        self:MoveBy(dir, isLocal)
    else
        self:MoveBy(Vec3.zero(), isLocal)
    end

    if isLocal then
        local pitch = self.actor.CameraController:GetPitch()
        local orient = Quat.New()
        orient:FromEuler(Vec3.New(0, pitch, 0))
        self.inputDir = orient * dir
    else
        self.inputDir = dir:Clone()
    end

    if not self.inputDir:Equals(self.preInputDir) then
        self.preInputDir = self.inputDir:Clone()
        --同步到服务端
        if not self:IsServer() and self:IsOwned() then
            local body = {
                inputDir = {x = self.inputDir.x, y = self.inputDir.y, z = self.inputDir.z}
            }
            self:SendToServer(AvatarNetProto.RequestInputDir, body)
        end
    end
end

--移动
function AvatarComponent:MoveBy(dir, isLocal)
    if not dir:IsZero() and self.autoRotate and self.autoRotateSmooth then
        local targetPos = self:GetPosition() + dir
        if isLocal then
            targetPos = self:GetPosition() + self.actor.CameraController:GetRotation() * dir
        end
        if self.actor.StatComponent:HasValue("ActorCameraFixed") or self.actor.StatComponent:HasValue("ActorUseCameraYaw") then
            -- self:RotateTo(targetPos, self.autoRotateDuration)
        else
            self:RotateTo(targetPos, self.autoRotateDuration)
        end
    end
    isLocal = isLocal or false
    local character = self.actor:GetCharacter()
    character:Move(Vector3.New(dir.x,dir.y,dir.z), isLocal)
    self.onGroundDirty = true
end

function AvatarComponent:MoveToTarget(target, callback, errorDistance)  
    if not target or Class.IsExpired(target) then
        return
    end
    local targetPos = target:GetPosition()

    self:MoveTo(targetPos, callback, errorDistance)
    self.moveTargetActor = target
end

function AvatarComponent:MoveTo(pos, callback, errorDistance)
    if self.lastMoveToPos and self.lastMoveToPos:Equals(pos) then
        return
    end
    if self.autoRotate and self.autoRotateSmooth then
        self:RotateTo(pos, self.autoRotateDuration)
    end
    local character = self.actor:GetCharacter()

    character:MoveTo(Vector3.New(pos.x,pos.y,pos.z))

    self.lastMoveToPos = pos:Clone()

    self.moveTargetPos = pos:Clone()
    self.moveTargetActor = nil
    self.moveErrorDistance = errorDistance or 10
    self.moveCallback = callback

    self.onGroundDirty = true
end
--导航移动到某个位置
function AvatarComponent:NavigateTo(pos, callback, errorDistance)
    if self.lastMoveToPos and self.lastMoveToPos:Equals(pos) then
        return
    end
    if self.autoRotate and self.autoRotateSmooth then
        self:RotateTo(pos, self.autoRotateDuration)
    end
    local character = self.actor:GetCharacter()

    character:NavigateTo(Vector3.New(pos.x,pos.y,pos.z))

    self.lastMoveToPos = pos:Clone()

    self.moveTargetPos = pos:Clone()
    self.moveTargetActor = nil
    self.moveErrorDistance = errorDistance or 10
    self.moveCallback = callback

    self.onGroundDirty = true
end
function AvatarComponent:MoveStep(offset)
    local targetPos = self:GetPosition() + offset
    if self.autoRotate and self.autoRotateSmooth then
        self:RotateTo(targetPos, self.autoRotateDuration)
    end

    local character = self.actor:GetCharacter()
    if character.EnablePhysics then
        if character.MoveStep then
            character:MoveStep(Vector3.New(offset.x,offset.y,offset.z))
        else
            self:MoveTo(targetPos)
        end
    else
        self:Translate(offset)
    end

    self.onGroundDirty = true
end
function AvatarComponent:StopMove()
    local character = self.actor:GetCharacter()
    -- character:StopNavigate()
    character:StopMove()
    self.moveTargetPos = nil
    self.moveErrorDistance = nil
    self.moveCallback = nil
    self.moveTargetActor = nil
end
function AvatarComponent:AddForce(force)
    local character = self.actor:GetCharacter()
    character:AddForce(Vector3.New(force.x,force.y,force.z))
end
--朝向目标
function AvatarComponent:LookAt(target)
    if target == nil then
        return
    end
    local targetPos = target:GetPosition()
    self:LookAtPos(targetPos)
end
function AvatarComponent:LookAtPos(targetPos)
    local lookRotation = self:CalcLookRotation(targetPos)
    self:SetRotation(lookRotation)
end
--计算方向
function AvatarComponent:CalcDirection(targetPos)
    local selfPos = self:GetPosition()
    selfPos.y = targetPos.y
    local dir = selfPos - targetPos
    dir:Normalize()
    return dir
end
function AvatarComponent:CalcLookRotation(targetPos)
    local dir = self:CalcDirection(targetPos)
    local lookRotation = Quat.New()
    lookRotation:FromLookRotation(dir, Vec3.New(0,1,0))
    return lookRotation
end
--设置是否自动旋转
function AvatarComponent:SetAutoRotate(autoRotate)
    if self.autoRotateSmooth then
        self.autoRotate = autoRotate
    else
        local character = self.actor:GetCharacter()
        character.AutoRotate = autoRotate
    end
end
--旋转到目标
function AvatarComponent:RotateTo(targetPos, duration, callback)
    local orient = self:CalcLookRotation(targetPos)
    local targetDir = orient * Vec3.New(0,0,1)
    local angle = targetDir:AngleBetween(self.actor:GetForward())
    duration = duration or angle / self:GetRotateSpeed()
    if Math:IsNaN(angle) or Math:IsInfinity(angle) then
        return
    end
    
    self.actor:StopActionByTag("AutoRotateTo")
    local rotateTo = RotateTo.New()
    rotateTo:Init(duration,orient)
    rotateTo:SetTag("AutoRotateTo")
    rotateTo.stopCallback = function(a)
        self.actor.rotating = false
        if callback then
            callback(self.actor)
        end
    end
    self.actor.rotating = true
    self.actor:RunAction(rotateTo)
end
--停止旋转
function AvatarComponent:StopRotate()
    self.actor:StopActionByTag("AutoRotateTo")
end

--是否开启此物体的物理状态
function AvatarComponent:EnablePhysics(enable)
    local character = self.actor:GetCharacter()
    character.EnablePhysics = enable
end

--设置是否使用镜头Yaw
function AvatarComponent:SetUseCameraYaw(useCameraYaw)
    self.useCameraYaw = useCameraYaw
end

--获取是否使用镜头Yaw
function AvatarComponent:IsUseCameraYaw()
    return self.useCameraYaw
end

----------------------------------Server-----------------------------------------
function AvatarComponent:OnRequestInputDir(body)
    self.inputDir.x = body.inputDir.x
    self.inputDir.y = body.inputDir.y
    self.inputDir.z = body.inputDir.z
end
function AvatarComponent:OnRequestLocomotionState(body)
    local state = AvatarDefines.DecodeLocomotionState(body.state)
    self.locomotionState = state
    self:OnLocomotionStateChanged(state)
end
function AvatarComponent:OnRequestPoseState(body)
end
function AvatarComponent:OnRequestMoveType(body)
    self:SetMoveType(body.moveType)
end
function AvatarComponent:OnRequestMoveSpeed(body)
    self:SetOverrideMoveSpeed(body.overrideMoveSpeed, false)
end
----------------------------------Client-----------------------------------------
function AvatarComponent:OnResponseLocomotionState(body)

end
function AvatarComponent:OnResponsePoseState(body)

end
function AvatarComponent:OnResponseVelocity(body)
    self:SetVelocity(Vec3.New(body.velocity[1], body.velocity[2], body.velocity[3]))
end
function AvatarComponent:OnResponsePlayAnim(body)
    self:PlayAnim(body.name,body.layer,body.normalized)
end
function AvatarComponent:OnResponseStopAnim(body)
    self:StopAnim(body.name,body.layer)
end
function AvatarComponent:OnResponseMoveType(body)
    self.moveType = body.moveType
end
function AvatarComponent:OnResponseMoveSpeed(body)
    self:SetOverrideMoveSpeed(body.overrideMoveSpeed, false)
end

function AvatarComponent:OnResponseVisible(body)
    self:SetVisible(body.visible)
end

--设置瞄准方向
function AvatarComponent:SetAimDirection(direction)
    if not direction:Equals(self.aimDirection) then
        self.aimDirection = direction
        if self.actor:IsLocalPlayer() then
            self:CmdSetAimDirection(direction.x, direction.y, direction.z)
        end
        if self:IsServer() then
            self:ORpcSetAimDirection(direction.x, direction.y, direction.z)
        end

        self.actor:Fire(self:IsServer(), "AimDirectionChanged", direction)
    end
end

--获取瞄准方向
function AvatarComponent:GetAimDirection()
    return self.aimDirection
end

--设置瞄准位置
function AvatarComponent:SetAimPosition(position)
    if not position:Equals(self.aimPosition) then
        self.aimPosition = position
        if self.actor:IsLocalPlayer() then
            self:CmdSetAimPosition(position.x, position.y, position.z)
        end
        if self:IsServer() then
            self:ORpcSetAimPosition(position.x, position.y, position.z)
        end

        self.actor:Fire(self:IsServer(), "AimPositionChanged", position)
    end
end

--获取瞄准位置
function AvatarComponent:GetAimPosition()
    return self.aimPosition
end

function AvatarComponent:SetSpreadAngle(angle)
    if angle == self.spreadAngle then
        return
    end
    self.spreadAngle = angle
    if self.actor:IsLocalPlayer() then
        self:CmdSetSpreadAngle(angle)
    end
end

function AvatarComponent:GetSpreadAngle()
    return self.spreadAngle
end


--设置枪口位置
function AvatarComponent:SetMuzzlePosition(position)
    if not position:Equals(self.muzzlePosition) then
        self.muzzlePosition = position
        if self.actor:IsLocalPlayer() then
            self:CmdSetMuzzlePosition(position.x, position.y, position.z)
        end

        self.actor:Fire(self:IsServer(), "MuzzlePositionChanged", position)
    end
end

--获取枪口位置
function AvatarComponent:GetMuzzlePosition()
    if self.muzzlePosition then
        return self.muzzlePosition
    end
    return Vec3.New(0, 100, 0)
end 

----------------------------------------Audio----------------------------------
--播放音效
function AvatarComponent:PlayVoice(audioName, volume, is3D)
    is3D = is3D ~= false
    volume = volume or 1
    local rollOffMinDistance = 100
    local rollOffMaxDistance = 2000
    SoundManager:PlaySound("Voice", audioName, {
        volume = volume, 
        loopCount = 1, 
        pos = is3D and self:GetPosition() or nil, 
        bindObj = is3D and self.actor.bindObj or nil,
        rollOffMinDistance = rollOffMinDistance,
        rollOffMaxDistance = rollOffMaxDistance
    })
end

----------------------------------------Cmd----------------------------------
function AvatarComponent:CmdSetAimDirection(x,y,z)
    self:SetAimDirection(Vec3.New(x,y,z))
end

function AvatarComponent:CmdSetAimPosition(x,y,z)
    self:SetAimPosition(Vec3.New(x,y,z))
end

function AvatarComponent:CmdSetMuzzlePosition(x,y,z)
    self:SetMuzzlePosition(Vec3.New(x,y,z))
end

function AvatarComponent:CmdSetSpreadAngle(angle)
    self:SetSpreadAngle(angle)
end
----------------------------------------Rpc----------------------------------
function AvatarComponent:ORpcSetAimDirection(x,y,z)
    self:SetAimDirection(Vec3.New(x,y,z))
end

function AvatarComponent:ORpcSetAimPosition(x,y,z)
    self:SetAimPosition(Vec3.New(x,y,z))
end

-----------------------------------------------------------------------

--序列化
function AvatarComponent:Serialize(data, purpose)
    data.version = self.version
    AvatarComponent.super.Serialize(self, data, purpose)
    data.locomotionState = AvatarDefines.EncodeLocomotionState(self.locomotionState)
    data.avatarPartGroup = self.avatarPartGroup
    -- data.miniSkinId = self.miniSkinId or -1
    -- data.miniModelId = self.miniModelId
    -- data.miniAnimUrl = self.miniAnimUrl
    data.moveType = self.moveType
end

--反序列化
function AvatarComponent:Deserialize(data)
    if data.version == nil then
        return
    end
    self.version = data.version
    AvatarComponent.super.Deserialize(self, data)
    
    self.locomotionState = AvatarDefines.DecodeLocomotionState(data.locomotionState)
    self.avatarPartGroup = data.avatarPartGroup
    -- self.miniSkinId = data.miniSkinId or -1
    -- self.miniModelId = data.miniModelId or ""
    -- self.miniAnimUrl = data.miniAnimUrl or ""
    self.moveType = data.moveType or AvatarDefines.EMoveType.Run
end

return AvatarComponent