return {
    bb = {
        RT_EnterCombatLocation = {0,0,0},
        CombatRadius = 3000,
        WaitDuration = 0,
        RandomMove_Radius = 1000,
        RandomMove_Interval = 5,
        Follow_Radius = 1000,
        Follow_Interval = 5,
        RT_Target = nil,
        RT_LastTarget = nil,
        Attack_Radius = 1200,
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
        Approach_Acceptance = 1500,
        RT_Self = nil,
        RT_Master = nil,
        RT_BornPosition = {0,0,0},
        RT_Behavior = "behavior",
        RT_PrevBehavior = "prevBehavior",
        DefaultBehavior = "RandomMove",
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
                lastTargetBBKey = "RT_LastTarget",
                masterBBKey = "RT_Master",
                enterCombatLocationBBKey = "RT_EnterCombatLocation",
                combatRadius = 10,
                combatRadiusBBKey = "CombatRadius",
                attackRadius = 10,
                attackRadiusBBKey = "Attack_Radius",
                disableApproach = false,
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
                    note = "死亡",
                },
            },
            {
                name = "Selector",
                decorators = {
                    {
                        name = "Compare",
                        args = {
                            objectBBKey = "RT_Behavior",
                            op = "==",
                            value = "Hit",
                            invert = false,
                            note = "",
                        },
                    },
                },
                args = {
                    canInterrupt = true,
                    note = "受击",
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
                            locationErr = 1,
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
                        name = "Compare",
                        args = {
                            objectBBKey = "RT_Behavior",
                            op = "==",
                            value = "Attack",
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
                        },
                        args = {
                            canInterrupt = true,
                            note = "",
                        },
                        children = {
                            {
                                name = "AimToTarget",
                                decorators = {
                                },
                                args = {
                                    turnLeft = "",
                                    turnLeftBBKey = "",
                                    turnRight = "",
                                    turnRightBBKey = "",
                                    targetBBKey = "RT_Target",
                                    canInterrupt = true,
                                    note = "",
                                },
                            },
                            {
                                name = "Shot",
                                decorators = {
                                },
                                args = {
                                    duration = 2,
                                    durationBBKey = "",
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
                            behavior = "Approach",
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
                            maxDistance = 0,
                            maxDistanceBBKey = "",
                            err = 1,
                            errBBKey = "LocationErr",
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
                        name = "GoHome",
                        decorators = {
                        },
                        args = {
                            location = {0,0},
                            locationBBKey = "",
                            locationErr = 1,
                            locationErrBBKey = "",
                            buff = "",
                            buffBBKey = "",
                            canInterrupt = true,
                            note = "",
                        },
                    },
                },
            },
        },
    },
}
