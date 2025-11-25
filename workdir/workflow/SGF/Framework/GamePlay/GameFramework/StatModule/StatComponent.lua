local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Stat = GFScript("StatModule.Stat")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local StatComponent = Class.New("StatComponent", ActorComponent)

-- --自定义属性集合
-- StatComponent.statAffacters = {
--     -- {
--     --     name = "customStatSet1",--属性集合名称
--     --     priority = 1,--优先级
--     --     calcStatsFunc = nil, --计算属性的函数: @param playerId return stats
--     --     stats = {},--计算出来的属性，将会合并到玩家的属性中
--     --     dirty = false,--是否需要重新计算
--     -- }
-- }

function StatComponent:Constructor()
    self.updateEnabled = true
end


function StatComponent:Destructor()
    if self.customAttrChangedEvent then
        self.customAttrChangedEvent:Disconnect()
        self.customAttrChangedEvent = nil
    end
    if self.attributeChangedEvent then
        self.attributeChangedEvent:Disconnect()
        self.attributeChangedEvent = nil
    end

    self.statAffacters = {}
end
--初始化
function StatComponent:Awake()
    StatComponent.super.Awake(self)
    self._baseStats = {}
    self._namedStats = {}
    self._finalStats = {}
    
    --自定义属性影响器
    self.statAffacters = {}
    --属性是否脏了
    self._statDirty = true
end
-- --重置
-- function StatComponent:Reset()
--     self._baseStats = {}
--     self._finalStats = {}
--     self:NotifyStatDirty()
-- end
--重置属性
function StatComponent:Reset()
    self._baseStats = {}
    self:NotifyStatDirty()
end
--复制
function StatComponent:CopyFrom(other)
    self._baseStats = {}
    self._finalStats = {}
    self:MergeStats(other._baseStats, self._baseStats)
    self:MergeStats(other._finalStats, self._finalStats)
    --属性是否脏了
    self._statDirty = true
end

--启动服务端
function StatComponent:OnStartServer()
end
--启动客户端
function StatComponent:OnStartClient()
    local character = self.actor:GetCharacter()
    --监听自定义属性改变
    self.customAttrChangedEvent =  character.CustomAttrChanged:Connect(function(attrName)
        if Utils:StartWith(attrName, "Stat_") then
            --将attrName开头的Stat_截取掉
            local statName = string.sub(attrName, 6)
            --触发属性变化通知
            local oldValue = self:GetBaseValue(statName)
            local newValue = self.actor:GetAttribute(attrName)
            self:SetBaseValue(statName, newValue)
            self.actor:FireClient("StatChanged", statName, oldValue, newValue)
            
            if self.actor:IsLocalPlayer() then
                if self.actor.CameraController then
                    local actorCameraZoom = self:GetValue("ActorCameraZoom")
                    local actorCameraYScale = self:GetValue("ActorCameraYScale")
                    self.actor.CameraController:SetZoomFactor(1 + actorCameraZoom)

                    local pivotScale = self.actor.CameraController:GetPivotScale()
                    pivotScale.y = 1 + actorCameraYScale
                    self.actor.CameraController:SetPivotScale(pivotScale)
                    local actorCameraFixed = self:HasValue("ActorCameraFixed")
                    if actorCameraFixed then

                        local actorRotation = self.actor:GetRotation()
                        local euler = actorRotation:ToEuler()
                        -- self.actor.CameraController._mouseX = 0
                        -- self.actor.CameraController._mouseXSmooth = 0
                        -- self.actor.CameraController._mouseXCurrentVelocity = 0

                        self.actor.CameraController._mouseY = euler.y + 180
                        self.actor.CameraController._mouseYSmooth = euler.y + 180
                        self.actor.CameraController._mouseYCurrentVelocity = 0
                        self.actor.CameraController.lockMouseY = true
                        
                    else
                        self.actor.CameraController.lockMouseY = false
                    end

                    -- local useCameraYaw = self:HasValue("ActorUseCameraYaw")
                    -- if useCameraYaw then
                    --     self.actor.AvatarComponent:SetUseCameraYaw(true)
                    -- else
                    --     self.actor.AvatarComponent:SetUseCameraYaw(false)
                    -- end
                end
            end
        end
    end)
    --监听生命变化
    self.attributeChangedEvent = character.AttributeChanged:Connect(function(attrName)
        if attrName == "Health" then
            --将attrName开头的Stat_截取掉
            local statName = attrName
            --触发属性变化通知
            local oldValue = self:GetBaseValue(statName)
            local character = self.actor:GetCharacter()
            local newValue = character.Health
            self.actor:FireClient("StatChanged", statName, oldValue, newValue)
            self:SetBaseValue(statName, newValue)
        end
    end) 
end

--添加属性到目标
function StatComponent:MergeStat(stat, targetStats)
    for i = 1, #targetStats do
        if targetStats[i].name == stat.name then
            local oldValue = targetStats[i].value
            local newValue = oldValue + stat.value
            targetStats[i].value = newValue
            return
        end
    end
    -- 添加属性
    local newStat = Stat.New(stat.name, stat.value)
    table.insert(targetStats, newStat)
end
--添加属性
function StatComponent:MergeStats(stats, targetStats)
    for i = 1, #stats do
        self:MergeStat(stats[i], targetStats)
    end
end
--获取属性值
local function _GetStatValue(stats,name)
    for i = 1, #stats do
        if stats[i].name == name then
            return stats[i].value
        end
    end
    return 0
end
--设置属性值
local function _SetStatValue(stats,name,value)
    for i = 1, #stats do
        if stats[i].name == name then
            stats[i].value = value
            return
        end
    end
end

--更新最终属性值
function StatComponent:UpdateStats()
    --只有服务端才会更新属性
    if self:IsServer() then
        --更新自定义属性
        for i = 1, #self.statAffacters do
            if self.statAffacters[i].dirty then
                self.statAffacters[i].stats = self.statAffacters[i].calcStatsFunc()
                self.statAffacters[i].dirty = false
            end
        end

        local cacheFinalStats = {}
        self:MergeStats(self._finalStats, cacheFinalStats)
        --将所有最终属性清0
        for i = 1, #self._finalStats do
            self._finalStats[i].value = 0
        end
        self:MergeStats(self._baseStats, self._finalStats)
        --将自定义属性加入最终属性
        for i = 1, #self.statAffacters do
            self:MergeStats(self.statAffacters[i].stats, self._finalStats)
        end

        --加入命名属性
        local namedStats = {}
        for name, stats in pairs(self._namedStats) do
            for statName, value in pairs(stats) do
                local stat = Stat.New(statName, value)
                table.insert(namedStats, stat)
            end
        end
        if #namedStats > 0 then
            self:MergeStats(namedStats, self._finalStats)
        end

        --换算百分比属性
        for i = 1, #self._finalStats do
            local stat = self._finalStats[i]
            if stat.isPercent then
                local percent = stat.value
                for k = 1, #self._finalStats do
                    if self._finalStats[k].name == stat.addToStatName then
                        self._finalStats[k].value = self._finalStats[k].value * (1 + percent / 100)
                    end
                end
            end
        end

        --判断有没有哪个属性是小写开头的，如果有，打印错误
        for i = 1, #self._finalStats do
            local stat = self._finalStats[i]
            if string.find(stat.name, "^%l") then
                Log:Error("@@@@@@@@@@@@@@@@@@@@@@ 属性名不能以小写字母开头："..stat.name)
            end
        end

        self._statDirty = false

        --脏标记设置完毕方可调用，否者会发生循环调用问题
        self:OnFinalStatsChanged()
        --判断那些属性已经改变
        for i = 1, #self._finalStats do
            local find = false
            for j = 1, #cacheFinalStats do
                if self._finalStats[i].name == cacheFinalStats[j].name then
                    find = true
                    if self._finalStats[i].value ~= cacheFinalStats[j].value then
                        --2024-12-10 21:08 TODO : 没有向客户端发送更新。final与缓存一致 
                        self:NotifyStatChanged(self._finalStats[i].name, cacheFinalStats[j].value, self._finalStats[i].value)
                        break
                    end
                end
            end
            if not find then
                self:NotifyStatChanged(self._finalStats[i].name, 0, self._finalStats[i].value)
            end
        end
    end
end

--服务端更新
function StatComponent:UpdateServer(dt)
    if self._statDirty then
        self:UpdateStats()
    end
end

--获取最终属性值
function StatComponent:GetValue(name)
    if self.actor:IsServer() then
        if self._statDirty then
            self:UpdateStats()
        end
        for i = 1, #self._finalStats do
            if self._finalStats[i].name == name then
                return self._finalStats[i].value
            end
        end
        return 0
    else 
        --客户端直接获取actor的属性
        return self.actor:GetAttribute(self:GetAttributeName(name)) or 0
    end
end

--是否存在某个属性值，既大于0
function StatComponent:HasValue(name)
    if self.actor:IsServer() then
        if self._statDirty then
            self:UpdateStats()
        end
        for i = 1, #self._finalStats do
            if self._finalStats[i].name == name then
                return self._finalStats[i].value > 0
            end
        end
        return false
    else 
        --客户端直接获取actor的属性
        local value = self.actor:GetAttribute(self:GetAttributeName(name))
        return value and value > 0
    end
end

--设置命名属性
function StatComponent:SetNamedValue(name, statName, value)
    isPercent = (isPercent == nil and false or isPercent)
    if not self._namedStats[name] then
        self._namedStats[name] = {}
    end
    self._namedStats[name][statName] = value
    self:NotifyStatDirty()
end

--获取命名属性
function StatComponent:GetNamedValue(name, statName)
    if not self._namedStats[name] then
        return 0
    end
    return self._namedStats[name][statName] or 0
end

--移除命名属性
function StatComponent:RemoveNamedValue(name, statName)
    if not self._namedStats[name] then
        return
    end
    self._namedStats[name][statName] = nil
    self:NotifyStatDirty()
end

--移除命名属性
function StatComponent:RemoveNamedStat(name)
    if not self._namedStats[name] then
        return
    end
    self._namedStats[name] = nil
    self:NotifyStatDirty()
end

-----------------------存档相关-----------------------
--加载数据
function StatComponent:LoadBaseData(data)
    for k, v in pairs(data) do
        if type(v) == "number" then
            self:SetBaseValue(k,v)
        end
    end
end
--读取属性
function StatComponent:ReadBaseData()
    local data = {}
    for i = 1, #self._baseStats do
        data[self._baseStats[i].name] = self._baseStats[i].value
    end
    return data
end

--设置基础属性
function StatComponent:SetBaseValue(name, value)
    for i = 1, #self._baseStats do
        if self._baseStats[i].name == name then
            self._baseStats[i].value = value
            self:NotifyStatDirty()
            return
        end
    end
    local stat = Stat.New(name, value)
    table.insert(self._baseStats, stat)
    self:NotifyStatDirty()
end

--设置简单属性值
function StatComponent:SetSimpleValue(name, value)
    for i = 1, #self._baseStats do
        if self._baseStats[i].name == name then
            local oldValue = self._baseStats[i].value
            self._baseStats[i].value = value
            self:_SetSimpleFinalValue(name, value)
            self:OnFinalStatsChanged()
            self:NotifyStatChanged(name, oldValue, value)
            return
        end
    end
    local stat = Stat.New(name, value)
    table.insert(self._baseStats, stat)
    self:_SetSimpleFinalValue(name, value)
    self:OnFinalStatsChanged()
    self:NotifyStatChanged(name, 0, value)
end

function StatComponent:_SetSimpleFinalValue(name, value)
    for i = 1, #self._finalStats do
        if self._finalStats[i].name == name then
            self._finalStats[i].value = value
            return
        end
    end
    local stat = Stat.New(name, value)
    table.insert(self._finalStats, stat)
end


--获取基础属性值
function StatComponent:GetBaseValue(name)
    for i = 1, #self._baseStats do
        if self._baseStats[i].name == name then
            return self._baseStats[i].value
        end
    end
    return 0
end

--添加基础属性
function StatComponent:IncreaseBaseValue(name, value)
    for i = 1, #self._baseStats do
        if self._baseStats[i].name == name then
            self._baseStats[i].value = self._baseStats[i].value + value
            self:NotifyStatDirty()
            return
        end
    end
    self:SetBaseValue(name, value)
end

--减少基础属性
function StatComponent:DecreaseBaseValue(name, value)
    for i = 1, #self._baseStats do
        if self._baseStats[i].name == name then
            self._baseStats[i].value = self._baseStats[i].value - value
            self:NotifyStatDirty()
            return
        end
    end
end
    
--最终属性改变时
function StatComponent:OnFinalStatsChanged()
    --将属性影响到Actor身上
    local actor = self:GetActor()
    if actor then

        for i = 1, #self._finalStats do
            local stat = self._finalStats[i]
            actor:SetAttribute(self:GetAttributeName(stat:GetName()), stat:GetValue())
        end
        -- local health = self:GetValue("Health")
        -- local maxHealth = self:GetValue("MaxHealth")
        -- actor.HealthComponent:InitValue(health, maxHealth)
        --半透明
        local alpha = self:GetValue("Alpha")
        if alpha ~= 0 then
            actor.AvatarComponent:SetAlpha(alpha)
        else
            actor.AvatarComponent:SetAlpha(1)
        end
        --隐藏
        if self:HasValue("Hide") then
            actor.AvatarComponent:SetVisible(false)
        else
            actor.AvatarComponent:SetVisible(true)
        end
        --同步忽视障碍属性
        if self:HasValue("IgnoreObstacle") then
            actor:SetIgnoreObstacle(true)
        else
            actor:SetIgnoreObstacle(false)
        end

        local actorScale = 1
        if self:HasValue("ActorScale") then
            actorScale = self:GetValue("ActorScale")
        end
        actor:SetScale(Vec3.New(actorScale,actorScale,actorScale))
        --同步某些属性到角色
        local moveSpeed = self:GetValue("MoveSpeed")
        local jumpSpeed = self:GetValue("JumpSpeed")

        if self:HasValue("MoveSpeedMul") then
            moveSpeed = moveSpeed * (1 + self:GetValue("MoveSpeedMul") / 100)    
        end
        if self:HasValue("JumpSpeedMul") then
            jumpSpeed = jumpSpeed * (1 + self:GetValue("JumpSpeedMul") / 100)
        end

        actor.AvatarComponent:SetMoveSpeed(moveSpeed)
        actor.AvatarComponent:SetJumpSpeed(jumpSpeed)
        

    end
    --触发事件
    self.actor:FireServer("StatsChanged")
end
--属性改变时
function StatComponent:NotifyStatChanged(name, oldValue, newValue)
    self.actor:FireServer("StatChanged", name, oldValue, newValue)
end

--通知stat脏标记
function StatComponent:NotifyStatDirty()
    self._statDirty = true
end

--通过类型获取属性的名字
function StatComponent:GetAttributeName(typeName)
    return "Stat_"..typeName
end

---------------------------------------自定义属性集合---------------------------------------

--定义属性集
function StatComponent:AddStatAffecter(name, priority, calcStatsFunc)
    --移除属性集
    self:RemoveStatAffecter(name)
    --添加新的属性集
    local statSet = {
        name = name,
        priority = priority,
        calcStatsFunc = calcStatsFunc,
        stats = {},
        dirty = false,
    }
    table.insert(self.statAffacters, statSet)
    --升序排序
    table.sort(self.statAffacters, function(a, b)
        return a.priority < b.priority
    end)

    -- self:NotifyStatDirty()
end
--移除属性集
function StatComponent:RemoveStatAffecter(name)
    for i = #self.statAffacters, 1, -1 do
        if self.statAffacters[i].name == name then
            table.remove(self.statAffacters, i)
        end
    end
end
--设置属性集脏标记
function StatComponent:SetStatAffecterDirty(name)
    for i = 1, #self.statAffacters do
        if self.statAffacters[i].name == name then
            self.statAffacters[i].dirty = true
            break
        end
    end

    self:NotifyStatDirty()
end

return StatComponent