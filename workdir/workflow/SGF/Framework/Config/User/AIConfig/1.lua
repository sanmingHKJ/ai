--AI配置范例
local AIConfig = {
    id = 1,
    --idle类型
    idleType = "RandomMove",
    --随机移动间隔
    randomMoveInterval = 50,
    --随机移动半径
    randomMoveRadius = 1000,
    --感知半径
    perceptionRadius = 1000,
    --追击半径，超过此距离脱战
    pursuitRadius = 2000,
    --重生时间
    reviveTime = 10,
    
}
return AIConfig