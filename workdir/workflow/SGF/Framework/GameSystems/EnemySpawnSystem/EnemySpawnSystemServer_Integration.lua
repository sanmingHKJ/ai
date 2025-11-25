--[[
    EnemySpawnSystemServer_Integration.lua - 敌人生成系统集成扩展

    功能：
    1. 扩展EnemySpawnSystemServer，添加3D节点创建功能
    2. 添加点击检测和战斗触发
    3. 不修改原系统代码，通过扩展方式集成

    使用方法：
    在ServerMain.lua中，在系统启动后调用此集成模块

    Version: 1.0.0
]]

local EnemyNodeHelper = require(script.Parent.EnemyNodeHelper)

local Integration = {}

--[[
    为EnemySpawnSystemServer注入节点创建功能
]]
function Integration.injectNodeCreation(enemySpawnSystem)
    if not enemySpawnSystem then
        print("[EnemySpawnIntegration] ERROR: enemySpawnSystem is nil")
        return false
    end

    print("[EnemySpawnIntegration] Injecting node creation functionality...")

    -- 保存原始的spawnEnemyAtPoint方法
    local originalSpawnEnemyAtPoint = enemySpawnSystem.spawnEnemyAtPoint

    -- 覆盖spawnEnemyAtPoint方法，添加节点创建
    enemySpawnSystem.spawnEnemyAtPoint = function(self, sceneName, spawnConfig)
        -- 调用原始方法创建数据
        local enemyId = originalSpawnEnemyAtPoint(self, sceneName, spawnConfig)

        if not enemyId then
            return nil
        end

        -- 获取敌人数据
        local enemyData = self.data.spawnedEnemies[enemyId]
        if not enemyData then
            print("[EnemySpawnIntegration] ERROR: enemyData not found for " .. enemyId)
            return enemyId
        end

        -- 创建3D节点
        local enemyNode = EnemyNodeHelper.createEnemyNode(
            enemyId,
            enemyData.type,
            enemyData.level,
            enemyData.position,
            nil  -- 父节点可以设置为场景中的EnemySpawns容器
        )

        if enemyNode then
            -- 保存节点引用到敌人数据
            enemyData.node = enemyNode
            print("[EnemySpawnIntegration] Created 3D node for enemy:", enemyId)
        else
            print("[EnemySpawnIntegration] ERROR: Failed to create node for enemy:", enemyId)
        end

        return enemyId
    end

    -- 注入despawnEnemy方法扩展，销毁节点
    local originalDespawnEnemy = enemySpawnSystem.despawnEnemy

    if originalDespawnEnemy then
        enemySpawnSystem.despawnEnemy = function(self, enemyId)
            -- 获取敌人数据
            local enemyData = self.data.spawnedEnemies[enemyId]
            if enemyData and enemyData.node then
                -- 销毁3D节点
                EnemyNodeHelper.destroyEnemyNode(enemyData.node)
                print("[EnemySpawnIntegration] Destroyed node for enemy:", enemyId)
            end

            -- 调用原始方法
            return originalDespawnEnemy(self, enemyId)
        end
    end

    -- 注入onEnemyKilled方法扩展
    local originalOnEnemyKilled = enemySpawnSystem.onEnemyKilled

    if originalOnEnemyKilled then
        enemySpawnSystem.onEnemyKilled = function(self, enemyId)
            -- 获取敌人数据
            local enemyData = self.data.spawnedEnemies[enemyId]
            if enemyData and enemyData.node then
                -- 销毁3D节点
                EnemyNodeHelper.destroyEnemyNode(enemyData.node)
                print("[EnemySpawnIntegration] Destroyed node for killed enemy:", enemyId)
            end

            -- 调用原始方法
            return originalOnEnemyKilled(self, enemyId)
        end
    end

    print("[EnemySpawnIntegration] Integration complete!")
    return true
end

--[[
    应用集成到系统管理器
]]
function Integration.apply(sgf)
    if not sgf or not sgf.businessSystemManager then
        print("[EnemySpawnIntegration] ERROR: SGF or businessSystemManager not found")
        return false
    end

    -- 获取EnemySpawnSystemServer实例
    local enemySpawnSystem = sgf.businessSystemManager:getSystem("EnemySpawnSystemServer")
    if not enemySpawnSystem then
        print("[EnemySpawnIntegration] ERROR: EnemySpawnSystemServer not found")
        return false
    end

    -- 注入功能
    return Integration.injectNodeCreation(enemySpawnSystem)
end

return Integration
