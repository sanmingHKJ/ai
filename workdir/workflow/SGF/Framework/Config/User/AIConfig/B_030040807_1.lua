return {
    bb = {
        RT_EnterCombatLocation = {0,0,0},
        CombatRadius = 5000,
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
        DefaultBehavior = "Idle",
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
                name = "Sequence",
                decorators = {
                    {
                        name = "InRangeToTarget",
                        args = {
                            range = {0,500},
                            rangeBBKey = "",
                            targetBBKey = "RT_Master",
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
                    {
                        name = "Log",
                        decorators = {
                        },
                        args = {
                            logContent = "回血",
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
                            range = {400,100000},
                            rangeBBKey = "",
                            targetBBKey = "RT_Master",
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
                        },
                        args = {
                            targetBBKey = "RT_Master",
                            maxDistance = 0,
                            maxDistanceBBKey = "",
                            err = 100,
                            errBBKey = "",
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
