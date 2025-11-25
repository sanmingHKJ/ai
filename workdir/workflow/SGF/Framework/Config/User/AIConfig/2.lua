--AI配置范例
local AIConfig = {
    bb = {
        --behavior类型: Stand RandomMove Patrol Follow Attack Approach Homing
        --基础信息
        bornPosition = {0,0,0},--出生点
        behavior = "Stand",
        defaultBehavior = "Stand",--默认行为
        enterCombatLocation = {0,0,0},--战斗位置
        targetLocation = {0,0,0},--移动目标位置
        combatRadius = 3000,--战斗半径
        locationErr = 50,--位置误差
        --站立信息

        --RandomMove信息
        RandomMove_Radius = 1000,--随机移动半径
        RandomMove_Interval = 5,--随机移动间隔
        --巡逻信息
        Patrol_Points = {{0,0,500},{500,0,500},{0,0,-500}},--巡逻点
        Patrol_Interval = 1,--巡逻间隔，每个点的停留时间
        --跟随信息
        Follow_Radius = 1000,--跟随半径
        Follow_Interval = 5,--跟随间隔

        --近战信息
        Attack_Target = nil,--攻击目标
        Attack_Radius = 200,--攻击半径
        Attack_Gaze_Angle = 90,--攻击时的凝视角度，超出这个角度会转向凝视目标
        --技能1
        Attack_Skill1_Range = {0,500}, --攻击范围
        Attack_Skill1_Chance = 100, --攻击概率
        Attack_Skill1_Cooldown = 4, --攻击冷却
        --技能2
        Attack_Skill2_Range = {0,500}, --攻击范围
        Attack_Skill2_Chance = 0, --攻击概率
        Attack_Skill2_Cooldown = 3, --攻击冷却
        --技能3
        Attack_Skill3_Range = {0,500}, --攻击范围
        Attack_Skill3_Chance = 0, --攻击概率
        Attack_Skill3_Cooldown = 5, --攻击冷却
        --技能4
        Attack_Skill4_Range = {0,500}, --攻击范围
        Attack_Skill4_Chance = 0, --攻击概率
        Attack_Skill4_Cooldown = 10, --攻击冷却
        
        --追击信息
        Approach_Accpetance = 200,--追击距离

        --归位信息
    },
    behavior =
    {
        id = "Root",
        name = "Selector",
        service =
        {
            name = "WarriorService",
            args = {
                behaviorBBKey = "behavior", 
                defaultBehaviorBBKey = "defaultBehavior", 
                targetBBKey = "Attack_Target",
                enterCombatLocationBBKey = "enterCombatLocation",
                combatRadiusBBKey = "combatRadius", 
                attackRadiusBBKey = "Attack_Radius",
                bornBBKey = "bornPosition",
            }
        },
        children = {
            --挂逼
            {
                id = "Dead",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Dead" },
                    }
                },
            },
            --无法移动
            {
                id = "Hit",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Hit" },
                    }
                },
            },
            --站立 Stand
            {
                id = "Stand",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Stand" },
                    }
                },
            },
            --随机移动 RandomMove
            {
                id = "RandomMove",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "RandomMove" },
                    }
                },
                children = {
                    {
                        name = "FindRandomLocation",
                        args = {orginBBKey = "bornPosition", radiusBBKey = "RandomMove_Radius", targetLocationBBKey = "targetLocation" },
                    },
                    {
                        name = "MoveToLocation",
                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                    },
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = { BBKey = "RandomMove_Interval" },
                    },
                }
            },
            --巡逻 Patrol
            {
                id = "Patrol",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Patrol" },
                    }
                },
                children = {
                    {
                        name = "FindNextPatrolLocation",
                        args = {pointsBBKey = "Patrol_Points", targetLocationBBKey = "targetLocation" },
                    },
                    {
                        name = "MoveToLocation",
                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                    },
                    {
                        name = "Wait",
                        args = { BBKey = "Patrol_Interval" },
                    },
                }
            },
            --跟随 Follow
            {
                id = "Follow",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Follow" },
                    }
                },
            },
            --攻击 Attack
            {
                id = "Attack",
                name = "Selector",
                decorators = {
                    {
                        name = "Check",
                        args = { BBKey = "Attack_Target" },
                    },
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Attack" },
                    }
                },
                children = {
                    --攻击4
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Attack_Skill4_Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Attack_Skill4_Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Attack_Skill4_Range" },
                            },
                        },
                        children = {
                            {
                                name = "RotateToTarget",
                                args = { targetBBKey = "Attack_Target" },
                            },
                            {
                                name = "Attack",
                                args = {skillIndex = 4},
                            },
                        }
                    },
                    --攻击3
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Attack_Skill3_Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Attack_Skill3_Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Attack_Skill3_Range" },
                            },
                        },
                        children = {
                            {
                                name = "RotateToTarget",
                                args = { targetBBKey = "Attack_Target" },
                            },
                            {
                                name = "Attack",
                                args = {skillIndex = 3},
                            },

                        }
                    },
                    --攻击2
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Attack_Skill2_Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Attack_Skill2_Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Attack_Skill2_Range" },
                            },
                        },
                        children = {
                            {
                                name = "RotateToTarget",
                                args = { targetBBKey = "Attack_Target" },
                            },
                            {
                                name = "Attack",
                                args = {skillIndex = 2},
                            },

                        }
                    },
                    --攻击1
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Attack_Skill1_Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Attack_Skill1_Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Attack_Skill1_Range" },
                            },
                        },
                        children = {
                            {
                                name = "RotateToTarget",
                                args = { targetBBKey = "Attack_Target" },
                            },
                            {
                                name = "Attack",
                                args = {skillIndex = 1},
                            },

                        }
                    },
                    --傻愣站立
                    {
                        name = "Sequence",
                        decorators = {
                            {
                                name = "InAngleToTarget",
                                args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                            },
                        },
                        children = {
                            {
                                name = "RotateToTarget",
                                args = { targetBBKey = "Attack_Target" },
                            },

                        }
                    },
                }
            },
            --追击 Approach
            {
                id = "Approach",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Approach" },
                    }
                },
                children = {
                    {
                        name = "MoveToTarget",
                        args = {targetBBKey = "Attack_Target", errBBKey = "Approach_Accpetance" }
                    },
                }
            },

            --归位 Homing
            {
                id = "Homing",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Homing" },
                    }
                },
                children = {
                    {
                        name = "MoveToLocation",
                        args = { targetLocationBBKey = "enterCombatLocation", errBBKey = "locationErr" },
                    },
                }
            },

        }
    }
}
return AIConfig