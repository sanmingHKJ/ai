--[[
    ReportData.lua - SGF框架数据埋点工具
    位置: framework/utils/ReportData.lua
    
    功能：
    1. 定义游戏数据埋点的事件类型
    2. 提供统一的数据上报接口
    3. 集成到SGF框架的分析服务
    
    Version: 4.0.0 (SGF框架)
    原始版本: xplants/ServiceNodes/MainStorage/Scripts/ReportData.lua
    
    参考文档:
    - 埋点数据字段定义: https://mini1.feishu.cn/wiki/HLJgwrLNtikjTbkdXDHcmmQpnXd?sheet=EH2RkE&range=NDo0
    - 参考文档: https://mini1.feishu.cn/docx/JS6wdG2FeoQufyxZJNocIFXJnrb
    - 埋点查询地址: https://panther.minicreata.com/oaett/overseas/EventTracking/Search
    
    变更：
    - 移动到framework/utils目录
    - 添加SGF框架集成
]]

local ReportData = {}

-- 场景ID(scene_id), 不可修改value
ReportData.SceneID = {
    Default = "1003"
}

-- 栏目ID(card_id), 不可修改value
ReportData.CardID = {
    Default = 'GAME_MODE_INFO'
}

-- 上报类型定义
ReportData.EventDefine = {
    SwitchZone = 1001,          -- 进入区域时上报
    LeaveZone = 1002,           -- 离开区域时上报
    BossKill = 1003,            -- 击杀怪物（精英怪或boss）后上报
    LevelUp = 1004,             -- 等级提升时上报
    GetProp = 1005,             -- 获得物品时上报
    RemoveProp = 1006,          -- 失去物品时上报
    NPCEvent = 1007,            -- 点击NPC交互时
    MapUI = 1008,               -- 点击地图UI时上报
    SwitchRole = 1009,          -- 更换角色
    UnlockRole = 1010,          -- 解锁角色
    ReqSwitchMap = 1011,        -- 请求跳转地图时上报
    SwitchMap = 1012,           -- 跳转地图成功时上报
    LeaveMap = 1013,            -- 离开地图时上报
    Trade = 1014,               -- 交易行
    WareHouse = 1015            -- 仓库
}

-- 组件ID(comp_id), 对应EventDefine, 不可修改value
ReportData.CompID = {
    [1001] = 'SwitchZone',
    [1002] = 'LeaveZone',
    [1003] = 'BossKill',
    [1004] = 'LevelUp',
    [1005] = 'GetProp',
    [1006] = 'RemoveProp',
    [1007] = 'NPCEvent',
    [1008] = 'MapUI',
    [1009] = 'SwitchRole',
    [1010] = 'UnlockRole',
    [1011] = 'SwitchMap',
    [1012] = 'SwitchMap',
    [1013] = 'LeaveMap',
    [1014] = 'Trade',
    [1015] = 'WareHouse'
}

-- 事件ID(event_code), 对应EventDefine, 不可修改value
ReportData.EventCode = {
    [1001] = 'active',
    [1002] = 'active',
    [1003] = 'active',
    [1004] = 'active',
    [1005] = 'active',
    [1006] = 'active',
    [1007] = 'active',
    [1008] = 'click',
    [1009] = 'active',
    [1010] = 'active',
    [1011] = 'request',
    [1012] = 'active',
    [1013] = 'active',
    [1014] = 'active',
    [1015] = 'active'
}

-- 游戏行为
ReportData.GameEvent = {
    Die = 1,                 -- 死亡
    Kill = 2,                -- 击杀
    Manslaughter = 3,        -- 误杀
    ExitGame = 4,            -- 游戏退出死亡
}

--[[
    上报事件
    @param sgf SGF框架实例
    @param eventId 事件ID（ReportData.EventDefine中的值）
    @param data 事件数据
]]
function ReportData:Report(sgf, eventId, data)
    if not sgf or not sgf.gameServices then
        print("❌ ReportData: SGF框架未初始化")
        return
    end
    
    local analyticsService = sgf.gameServices.AnalyticsService
    if not analyticsService then
        sgf.log:warning("ReportData: AnalyticsService not available")
        return
    end

    local compId = self.CompID[eventId]
    local eventCode = self.EventCode[eventId]
    
    if not compId or not eventCode then
        sgf.log:error("ReportData: Invalid eventId: " .. tostring(eventId))
        return
    end
    
    -- 构建上报数据
    local reportData = {
        scene_id = data.scene_id or self.SceneID.Default,
        card_id = data.card_id or self.CardID.Default,
        comp_id = compId,
        event_code = eventCode,
    }
    
    -- 添加自定义数据
    if data.standby1 then reportData.standby1 = data.standby1 end
    if data.standby2 then reportData.standby2 = data.standby2 end
    if data.standby3 then reportData.standby3 = data.standby3 end
    if data.standby4 then reportData.standby4 = data.standby4 end
    if data.standby5 then reportData.standby5 = data.standby5 end
    
    -- 执行上报
    local success, err = pcall(function()
        analyticsService:ReportEvent(reportData)
    end)
    
    if not success then
        sgf.log:error("ReportData: Failed to report event: " .. tostring(err))
    else
        sgf.log:debug("ReportData: Event reported: " .. compId)
    end
end

return ReportData

