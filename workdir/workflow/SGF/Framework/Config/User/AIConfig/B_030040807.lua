return {
    bb = {
        RT_EnterCombatLocation = {0,0,0},
        CombatRadius = 1000,
        WaitDuration = 10,
        RandomMove_Radius = 0,
        RandomMove_Interval = 5,
        Follow_Radius = 1000,
        Follow_Interval = 2,
        RT_Target = nil,
        RT_LastTarget = nil,
        Attack_Radius = 1500,
        Attack_GazeAngle = 90,
        Attack_Skill1_Range = {0,500},
        Attack_Skill1_Chance = 100,
        Attack_Skill1_Cooldown = 4,
        Attack_Skill2_Range = {0,500},
        Attack_Skill2_Chance = 0,
        Attack_Skill2_Cooldown = 3,
        Attack_Skill3_Range = {0,500},
        Attack_Skill3_Chance = 0,
        Attack_Skill3_Cooldown = 5,
        Attack_Skill4_Range = {0,500},
        Attack_Skill4_Chance = 0,
        Attack_Skill4_Cooldown = 10,
        Approach_Acceptance = 200,
        RT_Self = nil,
        RT_Master = nil,
        RT_BornPosition = {0,0,0},
        RT_Behavior = "behavior",
        RT_PrevBehavior = "prevBehavior",
        DefaultBehavior = "Idle",
        RT_TargetLocation = {0,0,0},
        LocationErr = 0,
        note = "",
    },
    behavior = {
        name = "Selector",
        decorators = {
        },
        service = {
            name = "WarriorService",
            args = {
                targetBBKey = "RT_Target",
                lastTargetBBKey = "RT_LastTarget",
                masterBBKey = "RT_Master",
                enterCombatLocationBBKey = "RT_EnterCombatLocation",
                combatRadius = 10,
                combatRadiusBBKey = "CombatRadius",
                attackRadius = 10,
                attackRadiusBBKey = "Attack_Radius",
                disableApproach = true,
                disableAttack = false,
                waitDuration = 0,
                waitDurationBBKey = "WaitDuration",
                selfBBKey = "RT_Self",
                behaviorBBKey = "RT_Behavior",
                defaultBehaviorBBKey = "DefaultBehavior",
                bornBBKey = "RT_BornPosition",
                note = "",
            },
        },
        children = {
            {
                name = "Selector",
                decorators = {
                    {
                        name = "Compare",
                        args = {
                            objectBBKey = "RT_Behavior",
                            op = "==",
                            value = "Dead",
                            invert = false,
                            note = "",
                        },
                    },
                },
                args = {
                    canInterrupt = true,
                    note = "",
                },
            },
            {
                name = "Sequence",
                decorators = {
                    {
                        name = "IsBehavior",
                        args = {
                            behavior = "RandomMove",
                            invert = false,
                            note = "",
                        },
                    },
                },
                args = {
                    canInterrupt = true,
                    note = "",
                },
                children = {
                    {
                        name = "FindRandomLocation",
                        decorators = {
                        },
                        args = {
                            orgin = {0,0,0},
                            orginBBKey = "RT_BornPosition",
                            radius = 10,
                            radiusBBKey = "RandomMove_Radius",
                            targetLocationBBKey = "RT_TargetLocation",
                            note = "",
                        },
                    },
                    {
                        name = "MoveToLocation",
                        decorators = {
                        },
                        args = {
                            location = {0,0},
                            locationBBKey = "RT_TargetLocation",
                            locationErr = 200,
                            locationErrBBKey = "",
                            canInterrupt = true,
                            note = "",
                        },
                    },
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = {
                            waitTime = 0,
                            waitTimeBBKey = "RandomMove_Interval",
                            canInterrupt = true,
                            note = "",
                        },
                    },
                },
            },
            {
                name = "Sequence",
                decorators = {
                    {
                        name = "IsBehavior",
                        args = {
                            behavior = "Homing",
                            invert = false,
                            note = "",
                        },
                    },
                },
                args = {
                    canInterrupt = true,
                    note = "",
                },
                children = {
                    {
                        name = "GoHome",
                        decorators = {
                        },
                        args = {
                            location = {0,0},
                            locationBBKey = "RT_BornPosition",
                            locationErr = 100,
                            locationErrBBKey = "",
                            buff = "Buff.Boss.Buff_GoHome",
                            buffBBKey = "",
                            canInterrupt = false,
                            note = "",
                        },
                    },
                    {
                        name = "ChangeBehavior",
                        decorators = {
                        },
                        args = {
                            behavior = "Idle",
                            behaviorBBKey = "DefaultBehavior",
                            canInterrupt = true,
                            note = "",
                        },
                    },
                },
            },
            {
                name = "Selector",
                decorators = {
                    {
                        name = "IsBehavior",
                        args = {
                            behavior = "Attack",
                            invert = false,
                            note = "",
                        },
                    },
                },
                args = {
                    canInterrupt = true,
                    note = "攻击",
                },
                children = {
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "InRangeHealth",
                                args = {
                                    minHealth = 0,
                                    minHealthBBKey = "",
                                    maxHealth = 99,
                                    maxHealthBBKey = "",
                                    targetBBKey = "RT_Self",
                                    invert = false,
                                    note = "",
                                },
                            },
                            {
                                name = "Once",
                                args = {
                                    invert = false,
                                    note = "",
                                },
                            },
                        },
                        args = {
                            canInterrupt = false,
                            note = "切换第二形态",
                        },
                        children = {
                            {
                                name = "Attack",
                                decorators = {
                                },
                                args = {
                                    skillIndex = 7,
                                    skillIndexBBKey = "",
                                    canInterrupt = true,
                                    note = "",
                                },
                            },
                            {
                                name = "Log",
                                decorators = {
                                },
                                args = {
                                    logContent = "@@@@@@@@@@@ 二阶段",
                                    canInterrupt = true,
                                    note = "",
                                },
                            },
                        },
                    },
                    {
                        name = "Selector",
                        decorators = {
                            {
                                name = "InRangeHealth",
                                args = {
                                    minHealth = 0,
                                    minHealthBBKey = "",
                                    maxHealth = 100,
                                    maxHealthBBKey = "",
                                    targetBBKey = "RT_Self",
                                    invert = false,
                                    note = "",
                                },
                            },
                            {
                                name = "HasBuff",
                                args = {
                                    buff = "Buff.Common.Buff_BanDamage",
                                    buffBBKey = "",
                                    targetBBKey = "RT_Target",
                                    invert = true,
                                    note = "",
                                },
                            },
                        },
                        args = {
                            canInterrupt = true,
                            note = "普通形态",
                        },
                        children = {
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 7,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Chance",
                                        args = {
                                            chance = 50,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {600,1500},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "冲刺合掌",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 1,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 7,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Chance",
                                        args = {
                                            chance = 50,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {0,900},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "三连转",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 2,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 7,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Chance",
                                        args = {
                                            chance = 50,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {0,600},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "原地拍地板",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 3,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = {
                                            chance = 50,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {500,1200},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 7,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "3连踩地板",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 4,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {0,600},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 5,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "磕头",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 5,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                            {
                                name = "Sequence",
                                decorators = {
                                    {
                                        name = "Cooldown",
                                        args = {
                                            cooldown = 5,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {600,5000},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "佛光掌",
                                },
                                children = {
                                    {
                                        name = "FaceToTarget",
                                        decorators = {
                                        },
                                        args = {
                                            targetBBKey = "RT_Target",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Attack",
                                        decorators = {
                                        },
                                        args = {
                                            skillIndex = 6,
                                            skillIndexBBKey = "",
                                            canInterrupt = true,
                                            note = "",
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "InRangeToTarget",
                                args = {
                                    range = {400,5000},
                                    rangeBBKey = "",
                                    targetBBKey = "RT_Target",
                                    invert = false,
                                    note = "",
                                },
                            },
                        },
                        args = {
                            canInterrupt = true,
                            note = "追击",
                        },
                        children = {
                            {
                                name = "MoveToTarget",
                                decorators = {
                                },
                                args = {
                                    targetBBKey = "RT_Target",
                                    maxDistance = 500,
                                    maxDistanceBBKey = "",
                                    err = 100,
                                    errBBKey = "",
                                    canInterrupt = true,
                                    note = "",
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
