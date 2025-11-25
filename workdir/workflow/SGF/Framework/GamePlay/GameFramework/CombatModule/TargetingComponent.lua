local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local TargetUtils = GFScript("CombatModule.TargetUtils")
local Utils = GFScript("CoreModule.Utils")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local TargetingComponent = Class.New("TargetingComponent", ActorComponent)

--构造函数
function TargetingComponent:Constructor(actor)
    self.updateEnabled = true
    self.height = 2000 --视野高度
    self.distance = 3000--视野范围
    self.lostDistance = 4000 --丢失目标距离
    self.targetType = 0--目标类型
    self.angle = 360--视野角度
    self.autoSelect = false
    --距离区间
    self.distanceRanges = {
        {minDis = 0, maxDis = 300, value = 30 },
        {minDis = 300, maxDis = 600, value = 20 },
        {minDis = 600, maxDis = 1000, value = 10 },
        {minDis = 600, maxDis = 3000, value = 5 },
    }

    self.previousInfo = { target = nil, remainTick = 300 }
end

--初始化
function TargetingComponent:Init()
    TargetingComponent.super.Init(self)
end

--更新客户端
function TargetingComponent:UpdateClient(dt)
    TargetingComponent.super.UpdateClient(self, dt)

    if self:HasAuthority() then
        if self.autoSelect then
            -- 自动锁敌
            self:SelectEnemy()
        else
            -- 更新锁定目标
            self:UpdateTargetSelected(self.actor:GetTarget())
        end
        
        local target = self.actor:GetTarget()
        if target ~= nil then
            -- 朝向目标
            if self.actor.SkillComponent:IsNeedLookAtTarget() then
                self.actor:LookAt(target)
            end
        elseif self.previousInfo.target ~= nil then
            -- 追踪先前选中目标
            local remainTick = self.previousInfo.remainTick - 1
            if remainTick > 0 then
                self.previousInfo.remainTick = remainTick
                
                if remainTick % 50 == 0 then
                    self:SelectPrevious(self.previousInfo.target, false)
                end
            else
                self:SelectPrevious(self.previousInfo.target, true)
            end
        end
    end
end

function TargetingComponent:UpdatePrevious(target)
    self.previousInfo.target = target
    self.previousInfo.remainTick = 300
end    

function TargetingComponent:SetAutoSelect(status)
    self.autoSelect = status
    self.actor:FireClient("AutoSelectStatusChanged", self.autoSelect)
end

function TargetingComponent:IsAutoSelect()
    return self.autoSelect
end

-- 取消索敌状态
function TargetingComponent:CancelAutoSelect()
    if self.autoSelect then
        self.actor:SetTarget(nil)
        self:SetAutoSelect(false)
    end
    self:UpdatePrevious(nil)
end

-- 检查对象是否可用
function TargetingComponent:CheckTargetAvailable(target)
    if target == nil or target.__delete__ then
        -- 对象不存在或已销毁
        return false
    end
    if target:IsDead() or target.StatComponent:HasValue("BanHit") 
        or target:IsShadow() or target.StatComponent:HasValue("BanSelect") 
        or self.actor.AvatarComponent:Distance(target.AvatarComponent) > self.lostDistance then
        -- 对象死亡、替身、禁止攻击、禁止被选、丢失目标
        return false
    end
    if target.AvatarComponent ~= nil and not target.AvatarComponent:GetVisible() then
        -- 对象隐身
        return false
    end
    return true
end

-- 更新对象
function TargetingComponent:UpdateTargetSelected(target)
    if target == nil then
        return
    end
    if target:IsShadow() or target.__delete__ then
        -- 传递下一个可用对象
        local curTarget = nil
        local enemies = self:FindEnemies()

        for k, enemy in ipairs(enemies) do
            if enemy == target or (target:GetPlayerId() ~= 0 and enemy:GetPlayerId() == target:GetPlayerId()) then
                curTarget = enemy
                break
            end
        end
        self.actor:SetTarget(curTarget)
        return
    end
    if not self:CheckTargetAvailable(target) then
        --目标丢失
        self.actor:SetTarget(nil)
    end
end

-- 切换索敌状态
function TargetingComponent:SwitchAutoSelect()
    if self.autoSelect then
        self.actor:SetTarget(nil)
        self:SetAutoSelect(false)
        self:UpdatePrevious(nil)
    else
        local enemies = self:FindEnemies()
        if #enemies > 0 then
            self:SetAutoSelect(true)
            local oldTarget = self.actor:GetTarget()
            local newTarget = enemies[1]

            if oldTarget ~= newTarget then
                self.actor:SetTarget(newTarget)
            else
                self.actor:FireClient("TargetChanged", oldTarget, newTarget)
            end
            --触发锁敌事件
            self.actor:FireClient("TargetLocked", newTarget)
            self:UpdatePrevious(newTarget)
        end
    end
end

--选择之前目标
function TargetingComponent:SelectPrevious(preTarget, isStop)
    if preTarget == nil then
        return
    end
    if isStop then
        self:UpdatePrevious(nil)
    end
    local enemies = self:FindEnemies()
    local eLen = #enemies
    if eLen <= 0 then
        return
    end

    for i = 1, eLen, 1 do
        local target = enemies[i]
        if target == preTarget or (target:GetPlayerId() ~= 0 and target:GetPlayerId() == preTarget:GetPlayerId()) then
            self:SetAutoSelect(true)
            self.actor:SetTarget(target)
            --触发锁敌事件
            self.actor:FireClient("TargetLocked", target)
            self:UpdatePrevious(target)
            break
        end
    end    
end

--选择敌方目标
function TargetingComponent:SelectEnemy()
    if not self.actor:CanAutoSelectUpdate() then
        return
    end
    local isCancel = true
    local enemies = self:FindEnemies()
    local eLen = #enemies
    if eLen > 0 then
        local curTarget = self.actor:GetTarget()
        if curTarget ~= nil then
            -- 当前已有选中对象
            for i = 1, eLen, 1 do
                local target = enemies[i]
                if target == curTarget or (target:GetPlayerId() ~= 0 and target:GetPlayerId() == curTarget:GetPlayerId()) then
                    isCancel = false
                    if curTarget:CheckId(target:GetActorId()) then
                        -- 未变化不更新
                    else
                        self.actor:FireClient("TargetLocked", target)
                        self.actor:SetTarget(target)
                    end
                    break
                end
            end
        else
            isCancel = false
            local newTarget = enemies[1]
            self.actor:FireClient("TargetLocked", newTarget)
            self.actor:SetTarget(newTarget)
        end
    end

    if isCancel then
        self:SetAutoSelect(false)
        self.actor:SetTarget(nil)
    end
end

-- 填充任意目标
function TargetingComponent:FillAnyTarget()
    local enemies = self:FindEnemies()
    if #enemies > 0 then
        self.actor:SetTarget(enemies[1])
    end
end

function TargetingComponent:GoOnTarget(targeting)
    if not targeting:IsAutoSelect() then
        return
    end
    local target = targeting.actor:GetTarget()
    targeting:CancelAutoSelect()
    if target == nil then
        return
    end
    self:SetAutoSelect(true)
    self.actor:SetTarget(target)
    if not self:IsServer() then
        --触发锁敌事件
        self.actor.CameraController:SetLockedOnTarget(true)
        self.actor.CameraController:SetAlignWhenMoving(true)
    end
end

--查找目标列表，权重高的靠前
function TargetingComponent:FindEnemies(calcWeightFunc)
    local function DefaultFilter(target)
        if target == self.actor or 
            target.StatComponent:HasValue("BanHit") or
            target.StatComponent:HasValue("BanSelect") or
            target:IsDead() or
            not self.actor.CombatComponent:IsEnemy(target) then
            return false
        end
        return true
    end
    self.actor:EnableOverlap(true)
    local targets = TargetUtils:SelectFanTargets(
        self.actor:IsServer(),  
        self.actor.AvatarComponent:GetPosition(),
        self.actor.AvatarComponent:GetForward(),
        self.distance,
        self.height,
        self.angle,
        DefaultFilter
    )
    self.actor:EnableOverlap(false)
    local forward = nil
    if self:IsServer() then
        forward = self.actor.AvatarComponent:GetForward()
    else
        local pitch = self.actor.CameraController:GetPitch()
        local orient = Quat.New()
        orient:FromEuler(Vec3.New(0, pitch, 0))
        forward = orient * Vec3.New(0, 0, 1)
    end
    local selfPos = self.actor.AvatarComponent:GetPosition()

    local function DefaultWeightCalc(target)
        local targetPos = target.AvatarComponent:GetPosition()
        local targetDir = targetPos - selfPos
        targetDir.y = 0
        targetDir:Normalize()
        local dot = forward:Dot(targetDir)
        local distance = targetPos:Distance(selfPos)
        local weight = target.StatComponent:GetValue("LockWeight")
        local weightMul = target.StatComponent:GetValue("LockWeightMul")

        local distanceValue = self:GetDistanceValue(distance)
        local ret = weight * (1 + weightMul) * (distanceValue + (dot + 1) * 50)

        return ret
    end

    calcWeightFunc = calcWeightFunc or DefaultWeightCalc

    local results = {}
    for i, target in ipairs(targets) do
        if self:CheckTargetAvailable(target) then
            target.__weight = calcWeightFunc(target)
            table.insert(results, target)
        end
    end

    --根据权重排序
    table.sort(results, function(a,b)
        return a.__weight > b.__weight
    end)

    return results
end

--根据距离，计算所在距离区间的值
function TargetingComponent:GetDistanceValue(distance)
    for i, range in ipairs(self.distanceRanges) do
        if distance >= range.minDis and distance < range.maxDis then
            return range.value
        end
    end
    return 0
end

--应用游戏设置
function TargetingComponent:ApplyServerGameSettings(settings)
    local config = settings.Targeting
    self.height = config.height --视野高度
    self.distance = config.distance--视野范围
    self.lostDistance = config.lostDistance --丢失目标距离
    self.targetType = config.targetType--目标类型
    self.autoSelect = config.autoSelect --自动选择
    self.angle = config.angle--视野角度
    self.distanceRanges = config.distanceRanges
end

return TargetingComponent