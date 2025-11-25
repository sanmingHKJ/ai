return {
    bb = {
        RT_EnterCombatLocation = {0,0,0},
        CombatRadius = 2000,
        RandomMove_Radius = 1000,
        RandomMove_Interval = 5,
        Follow_Radius = 1000,
        Follow_Interval = 2,
        RT_Target = nil,
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
        DefaultBehavior = "Follow",
        RT_TargetLocation = {0,0,0},
        LocationErr = 100,
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
                masterBBKey = "RT_Master",
                enterCombatLocationBBKey = "RT_EnterCombatLocation",
                combatRadius = 10,
                combatRadiusBBKey = "CombatRadius",
                attackRadius = 10,
                attackRadiusBBKey = "Attack_Radius",
                disableApproach = true,
                disableAttack = false,
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
                name = "Selector",
                decorators = {
                    {
                        name = "IsBehavior",
                        args = {
                            behavior = "Hit",
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
                            behavior = "Follow",
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
                        name = "MoveToTarget",
                        decorators = {
                            {
                                name = "InRangeToTarget",
                                args = {
                                    range = {0,2000},
                                    rangeBBKey = "",
                                    targetBBKey = "RT_Target",
                                    invert = true,
                                    note = "",
                                },
                            },
                        },
                        args = {
                            targetBBKey = "RT_Master",
                            maxDistance = 10000,
                            maxDistanceBBKey = "",
                            err = 300,
                            errBBKey = "",
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
                                            cooldown = 15,
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
                                            range = {0,3000},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "HasBuff",
                                        args = {
                                            buff = "Buff.Hero.034011101.Buff_Freeze_Wukong",
                                            buffBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = true,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "HasBuff",
                                        args = {
                                            buff = "Buff.Hero.034011101.Buff_Freeze_Wukong_Protect",
                                            buffBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = true,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "定身",
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
                                            skillIndex = 20,
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
                                            cooldown = 2,
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
                                            range = {700,2000},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "向前闪避",
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
                                            skillIndex = 19,
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
                                            range = {0,500},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "HasStatValue",
                                        args = {
                                            stat = "KnockDown",
                                            targetBBKey = "RT_Target",
                                            invert = true,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "普攻12段",
                                },
                                children = {
                                    {
                                        name = "ComboAttack",
                                        decorators = {
                                        },
                                        args = {
                                            skills = {1,2},
                                            skillsBBKey = "",
                                            faceToTarget = true,
                                            comboChance = 100,
                                            comboChanceBBKey = "",
                                            targetBBKey = "RT_Target",
                                            canInterrupt = false,
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
                                            chance = 100,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {0,500},
                                            rangeBBKey = "",
                                            targetBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "HasStatValue",
                                        args = {
                                            stat = "KnockDown",
                                            targetBBKey = "RT_Target",
                                            invert = true,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "普攻12345段",
                                },
                                children = {
                                    {
                                        name = "ComboAttack",
                                        decorators = {
                                        },
                                        args = {
                                            skills = {1,2,3,4,5},
                                            skillsBBKey = "",
                                            faceToTarget = true,
                                            comboChance = 100,
                                            comboChanceBBKey = "",
                                            targetBBKey = "RT_Target",
                                            canInterrupt = false,
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
                                            cooldown = 4,
                                            cooldownBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "InRangeToTarget",
                                        args = {
                                            range = {0,1500},
                                            rangeBBKey = "",
                                            targetBBKey = "RT_Target",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                    {
                                        name = "Chance",
                                        args = {
                                            chance = 20,
                                            chanceBBKey = "",
                                            invert = false,
                                            note = "",
                                        },
                                    },
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "后撤闪避",
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
                                            skillIndex = 18,
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
                        name = "Selector",
                        decorators = {
                            {
                                name = "InRangeToTarget",
                                args = {
                                    range = {0,1500},
                                    rangeBBKey = "",
                                    targetBBKey = "RT_Target",
                                    invert = false,
                                    note = "",
                                },
                            },
                            {
                                name = "Cooldown",
                                args = {
                                    cooldown = 2,
                                    cooldownBBKey = "",
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
                                    invert = false,
                                    note = "",
                                },
                            },
                        },
                        args = {
                            canInterrupt = true,
                            note = "调整身位",
                        },
                        children = {
                            {
                                name = "Sequence",
                                decorators = {
                                },
                                args = {
                                    canInterrupt = true,
                                    note = "后撤闪避",
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
                                            skillIndex = 18,
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
                                            logContent = "后撤2",
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
            {
                name = "Selector",
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
                    note = "归位",
                },
                children = {
                    {
                        name = "MoveToLocation",
                        decorators = {
                        },
                        args = {
                            location = {0,0},
                            locationBBKey = "RT_EnterCombatLocation",
                            locationErr = 200,
                            locationErrBBKey = "",
                            canInterrupt = true,
                            note = "",
                        },
                    },
                },
            },
        },
    },
}
