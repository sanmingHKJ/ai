--[[
    EnemyNodeHelper.lua - 敌人节点创建和交互辅助模块

    功能：
    1. 创建敌人3D节点
    2. 添加点击检测
    3. 触发战斗

    Version: 1.0.0
]]

local EnemyNodeHelper = {}

local Protocol = require(script.Parent.Parent.Parent.Runtime.Protocol)

--[[
    创建敌人3D节点
    @param enemyId string 敌人ID
    @param enemyType string 敌人类型 (Slime, Wolf, Bear)
    @param enemyLevel number 敌人等级
    @param position Vector3 出生位置
    @param parentNode Node 父节点 (通常是EnemySpawns容器)
    @return Node 创建的敌人节点
]]
function EnemyNodeHelper.createEnemyNode(enemyId, enemyType, enemyLevel, position, parentNode)
    -- 创建敌人根节点 (Transform)
    local enemyRoot = game:CreateNode("Transform")
    if not enemyRoot then
        print("[EnemyNodeHelper] ERROR: Failed to create Transform node")
        return nil
    end

    enemyRoot.Name = "Enemy_" .. enemyId
    enemyRoot.Position = position

    if parentNode then
        enemyRoot.Parent = parentNode
    end

    -- 创建敌人模型 (使用GeoSolid作为占位符)
    local enemyModel = game:CreateNode("GeoSolid")
    if not enemyModel then
        print("[EnemyNodeHelper] ERROR: Failed to create GeoSolid node")
        enemyRoot:Destroy()
        return nil
    end

    enemyModel.Name = "EnemyModel"
    enemyModel.Parent = enemyRoot

    -- 根据敌人类型设置大小和颜色
    local modelConfig = EnemyNodeHelper.getEnemyModelConfig(enemyType)
    enemyModel.Size = modelConfig.size
    enemyModel.Color = modelConfig.color
    enemyModel.MaterialType = 6  -- 半透明材质

    -- 设置物理属性
    enemyModel.Anchored = true
    enemyModel.CanCollide = true
    enemyModel.CanTouch = false  -- 不使用碰撞，使用点击

    -- 添加点击检测
    EnemyNodeHelper.setupClickDetection(enemyModel, enemyId, enemyType, enemyLevel)

    -- 创建名称标签 (可选，用于显示敌人信息)
    -- TODO: 使用UI节点显示敌人名称和血条

    print("[EnemyNodeHelper] Created enemy node:", enemyId, "Type:", enemyType, "Lv:", enemyLevel)

    return enemyRoot
end

--[[
    获取敌人模型配置
]]
function EnemyNodeHelper.getEnemyModelConfig(enemyType)
    local configs = {
        Slime = {
            size = Vector3.new(100, 80, 100),  -- 史莱姆：矮胖
            color = Color.new(0, 255, 100),    -- 绿色
        },
        Wolf = {
            size = Vector3.new(120, 100, 150), -- 野狼：中等
            color = Color.new(150, 150, 150),  -- 灰色
        },
        Bear = {
            size = Vector3.new(180, 180, 180), -- 熊：大型
            color = Color.new(139, 69, 19),    -- 棕色
        },
    }

    return configs[enemyType] or configs.Slime
end

--[[
    设置点击检测
]]
function EnemyNodeHelper.setupClickDetection(enemyModel, enemyId, enemyType, enemyLevel)
    -- 设置为可点击
    enemyModel:SetClickable(true)

    -- 监听点击事件
    enemyModel:OnClick(function(clickingPlayer)
        if not clickingPlayer then
            print("[EnemyNodeHelper] ERROR: clickingPlayer is nil")
            return
        end

        local playerId = clickingPlayer:GetOwnerPlayerUid()
        print("[EnemyNodeHelper] Player clicked enemy:", playerId, "->", enemyId)

        -- 检查距离（必须在攻击范围内）
        local playerPos = clickingPlayer.Position
        local enemyPos = enemyModel.Parent.Position
        local distance = Vector3.Distance(playerPos, enemyPos)

        local ATTACK_RANGE = 500  -- 5米攻击范围 (500厘米)

        print("[EnemyNodeHelper] Distance:", distance, "/ Range:", ATTACK_RANGE)

        if distance > ATTACK_RANGE then
            -- 距离太远，记录日志但不发送网络消息
            -- 网络消息应该由CombatSystem负责发送
            print("[EnemyNodeHelper] Player too far away, distance:", distance)
            return
        end

        -- 触发战斗事件，由CombatSystem监听处理
        print("[EnemyNodeHelper] Triggering combat event...")

        -- 使用事件系统触发战斗，而不是直接调用CombatSystem
        -- 这样可以解耦，让CombatSystem决定如何处理
        local EventID = require(script.Parent.Parent.Parent.Runtime.EventID)
        if sgf and sgf.events then
            sgf.events:emit(EventID.CombatRequested, {
                playerId = playerId,
                enemyId = enemyId,
                playerPos = playerPos,
                enemyPos = enemyPos,
            })
            print("[EnemyNodeHelper] Combat event emitted")
        else
            print("[EnemyNodeHelper] ERROR: SGF events system not found!")
        end
    end)

    print("[EnemyNodeHelper] Click detection setup for:", enemyId)
end

--[[
    销毁敌人节点
]]
function EnemyNodeHelper.destroyEnemyNode(enemyNode)
    if enemyNode then
        enemyNode:Destroy()
        print("[EnemyNodeHelper] Enemy node destroyed")
    end
end

--[[
    更新敌人血量显示 (可选)
]]
function EnemyNodeHelper.updateEnemyHealth(enemyNode, currentHp, maxHp)
    -- TODO: 更新敌人头顶的血条UI
    -- 这需要在客户端使用UI节点来显示
    print("[EnemyNodeHelper] Update health:", currentHp, "/", maxHp)
end

return EnemyNodeHelper
