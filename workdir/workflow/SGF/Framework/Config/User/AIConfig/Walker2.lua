--AI配置范例
local AIConfig = {
    bb = {
        --behavior类型: Stand RandomMove Patrol Follow Attack Approach Homing
        --基础信息
        bornPosition = {0,0,0},--出生点
        behavior = "Patrol",
        defaultBehavior = "Patrol",--默认行为
        targetLocation = {0,0,0},--目标点
        locationErr = 50,--位置误差

        walkPathName = "Path1",--路径名称
        walkPath = nil,--路径
        targetWaypoint = nil,--当前路径点

        --Idle动画
        idleAnim = "100117",
        idleDuration = 3,
        --表情动画
        emotionAnim = "100140",
        emotionDuration = 1,
    },
    behavior =
    {
        id = "Root",
        name = "Selector",
        service =
        {
            name = "WalkerService",
            args = {
                behaviorBBKey = "behavior", 
                defaultBehaviorBBKey = "defaultBehavior", 
                bornBBKey = "bornPosition",
                walkPathNameBBKey = "walkPathName",
                walkPathBBKey = "walkPath",
            }
        },
        children = {
            --巡逻 Patrol
            {
                id = "Patrol",
                name = "Sequence",
                decorators = {
                    {
                        name = "Check",
                        args = { BBKey = "walkPath" },
                    },
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Patrol" },
                    }
                },
                children = {
                    {
                        name = "PlayMontage",
                        args = { animBBKey = "emotionAnim", durationBBKey = "idleDuration" },
                    },
                    {
                        name = "PlayMontage",
                        args = { animBBKey = "emotionAnim", durationBBKey = "emotionDuration" },
                    },
                }
            },
        }
    }
}
return AIConfig