--[[
    EventID.lua - RPG Game Event ID Definition
    事件ID定义

    按照SGF标准化开发框架规范开发

    功能：
    1. 定义所有游戏事件的ID（字符串形式）
    2. 用于EventBus事件系统

    使用方式:
    ```lua
    -- 注册事件
    sgf.events:on(EventID.PlayerDataUpdated, function(data)
        -- 处理玩家数据更新事件
    end)

    -- 触发事件
    sgf.events:emit(EventID.PlayerDataUpdated, {playerData = data})
    ```

    Version: 1.0.0
]]

local EventID = {
    -- ========================================
    -- 游戏生命周期事件
    -- ========================================
    GameInitialized = "GameInitialized",
    GameStarted = "GameStarted",
    GamePaused = "GamePaused",
    GameResumed = "GameResumed",
    GameEnded = "GameEnded",

    -- ========================================
    -- 玩家事件
    -- ========================================
    PlayerJoined = "PlayerJoined",
    PlayerLeft = "PlayerLeft",
    PlayerDataUpdated = "PlayerDataUpdated",
    PlayerStatsUpdated = "PlayerStatsUpdated",
    PlayerExpUpdated = "PlayerExpUpdated",
    PlayerLevelUp = "PlayerLevelUp",
    PlayerHealthUpdated = "PlayerHealthUpdated",
    PlayerManaUpdated = "PlayerManaUpdated",
    PlayerGoldUpdated = "PlayerGoldUpdated",
    PlayerSkillPointsUpdated = "PlayerSkillPointsUpdated",
    PlayerDied = "PlayerDied",
    PlayerRespawned = "PlayerRespawned",
    PlayerPositionUpdated = "PlayerPositionUpdated",

    -- ========================================
    -- 战斗事件
    -- ========================================
    CombatStarted = "CombatStarted",
    CombatEnded = "CombatEnded",
    CombatTurnChanged = "CombatTurnChanged",
    CombatActionExecuted = "CombatActionExecuted",
    CombatDamageDealt = "CombatDamageDealt",
    CombatHealReceived = "CombatHealReceived",
    CombatBuffApplied = "CombatBuffApplied",
    CombatBuffRemoved = "CombatBuffRemoved",
    CombatEnemyDied = "CombatEnemyDied",
    CombatVictory = "CombatVictory",
    CombatDefeat = "CombatDefeat",
    CombatFled = "CombatFled",

    -- ========================================
    -- 技能事件
    -- ========================================
    SkillLearned = "SkillLearned",
    SkillUpgraded = "SkillUpgraded",
    SkillCasted = "SkillCasted",
    SkillCooldownStarted = "SkillCooldownStarted",
    SkillCooldownEnded = "SkillCooldownEnded",
    SkillShortcutChanged = "SkillShortcutChanged",
    
    -- ========================================
    -- 快捷栏事件
    -- ========================================
    HotbarDataUpdated = "HotbarDataUpdated",
    HotbarSlotUsed = "HotbarSlotUsed",

    -- ========================================
    -- 背包事件
    -- ========================================
    InventoryUpdated = "InventoryUpdated",
    ItemObtained = "ItemObtained",
    ItemUsed = "ItemUsed",
    ItemDropped = "ItemDropped",
    ItemSorted = "ItemSorted",
    InventoryExpanded = "InventoryExpanded",
    InventoryFull = "InventoryFull",

    -- ========================================
    -- 装备事件
    -- ========================================
    EquipmentEquipped = "EquipmentEquipped",
    EquipmentUnequipped = "EquipmentUnequipped",
    EquipmentUpdated = "EquipmentUpdated",
    EquipmentUpgraded = "EquipmentUpgraded",

    -- ========================================
    -- 任务事件
    -- ========================================
    QuestAccepted = "QuestAccepted",
    QuestUpdated = "QuestUpdated",
    QuestCompleted = "QuestCompleted",
    QuestTrackingChanged = "QuestTrackingChanged",
    QuestSubmitted = "QuestSubmitted",
    QuestAbandoned = "QuestAbandoned",
    QuestObjectiveUpdated = "QuestObjectiveUpdated",
    QuestNewAvailable = "QuestNewAvailable",

    -- ========================================
    -- 商店事件
    -- ========================================
    ShopOpened = "ShopOpened",
    ShopClosed = "ShopClosed",
    ItemBought = "ItemBought",
    ItemSold = "ItemSold",
    ShopRefreshed = "ShopRefreshed",

    -- ========================================
    -- UI事件
    -- ========================================
    OpenCharacterPanel = "OpenCharacterPanel",
    CloseCharacterPanel = "CloseCharacterPanel",
    OpenInventoryPanel = "OpenInventoryPanel",
    CloseInventoryPanel = "CloseInventoryPanel",
    OpenSkillPanel = "OpenSkillPanel",
    CloseSkillPanel = "CloseSkillPanel",
    OpenQuestPanel = "OpenQuestPanel",
    CloseQuestPanel = "CloseQuestPanel",
    OpenShopPanel = "OpenShopPanel",
    CloseShopPanel = "CloseShopPanel",
    OpenCombatPanel = "OpenCombatPanel",
    CloseCombatPanel = "CloseCombatPanel",
    ShowMessage = "ShowMessage",
    ShowDamageNumber = "ShowDamageNumber",
    ShowFloatingText = "ShowFloatingText",

    -- ========================================
    -- 场景事件
    -- ========================================
    SceneLoaded = "SceneLoaded",
    SceneUnloaded = "SceneUnloaded",
    SceneChanged = "SceneChanged",
    SceneChangedClient = "SceneChangedClient",
    PlayerTeleported = "PlayerTeleported",
    ShowSceneName = "ShowSceneName",

    -- ========================================
    -- 敌人生成事件
    -- ========================================
    EnemySpawned = "EnemySpawned",
    EnemyKilled = "EnemyKilled",
    EnemyDespawned = "EnemyDespawned",
    EnemyDrops = "EnemyDrops",
    SpawnPointActivated = "SpawnPointActivated",
    SpawnPointDeactivated = "SpawnPointDeactivated",

    -- ========================================
    -- 小地图事件
    -- ========================================
    MinimapMarkerAdded = "MinimapMarkerAdded",
    MinimapMarkerRemoved = "MinimapMarkerRemoved",

    -- ========================================
    -- 3D交互事件
    -- ========================================
    ObjectClicked = "ObjectClicked",
    ObjectHovered = "ObjectHovered",
    NPCInteracted = "NPCInteracted",
    DoorOpened = "DoorOpened",
    ChestOpened = "ChestOpened",
    TeleportUsed = "TeleportUsed",
    ShowInteractionHint = "ShowInteractionHint",
    HideInteractionHint = "HideInteractionHint",

    -- ========================================
    -- 系统事件
    -- ========================================
    SystemError = "SystemError",
    SystemWarning = "SystemWarning",
    SystemInfo = "SystemInfo",
    NetworkConnected = "NetworkConnected",
    NetworkDisconnected = "NetworkDisconnected",
    DataSaved = "DataSaved",
    DataLoaded = "DataLoaded",
}

return EventID
