--AI配置范例

--配置说明
--类似StartMove_Location这种有4种配置方式
--随机位置，配置为{类型，位置，半径},例如：{"Random",{0,0,100},1000}，会在{0,0,100}位置以1000半径随机一个位置
--目标随机位置，配置为{类型，半径},例如：{"RandomOfTarget",1000}，会在目标位置以1000半径随机一个位置
--世界位置，配置为{类型，位置},例如：{"World",{0,0,100}}，以{0,0,100}为位置
--相对位置，配置为{类型，位置},例如：{"Local",{0,0,100}}，以自己位置空间{0,0,100}为位置，也就是自己前方1米处


local AIConfig = {
    bb = {
        --behavior类型: Stand RandomMove Patrol Follow Attack Approach Homing
        --基础信息
        bornPosition = {0,0,0},--出生点
        behavior = "Stand",
        defaultBehavior = "Stand",--默认行为
        enterCombatLocation = {0,0,0},--战斗位置
        targetLocation = {0,0,0},--移动目标位置
        combatRadius = 25000,--战斗半径
        locationErr = 500,--位置误差
        --站立信息

        --出场行为
        Enter_Anim = "Idle2",
        Enter_Duration = 5,
        Enter_Wait = 2,
        --唤醒行为
        WakeUp_Anim = "Skill2",
        WakeUp_Duration = 5,
        WakeUp_Wait = 1,
        WakeUp_MoveLocation = {300,0,1500},
        WakeUp_MoveLocation_Wait = 2,

        --狂暴表现
        Fury_Health = {0,0.6},--血量范围
        Fury_Anim = "LargeHit",--狂暴动作
        Fury_Duration = 8,--动作持续时间

        --RandomMove信息
        RandomMove_Radius = 1000,--随机移动半径
        RandomMove_Interval = 5,--随机移动间隔
        --巡逻信息
        Patrol_Points = {{0,0,500},{500,0,500},{0,0,-500}},--巡逻点
        Patrol_Interval = 1,--巡逻间隔，每个点的停留时间
        --跟随信息
        Follow_Radius = 1000,--跟随半径
        Follow_Interval = 5,--跟随间隔

        --Locomotion
        Locomotion_Anim_TurnL = "TurnLittleL",
        Locomotion_Anim_TurnR = "TurnLittleR",
        --近战信息
        Attack_Target = nil,--攻击目标
        Attack_Radius = 25000,--攻击半径
        Attack_Gaze_Angle = 30,--攻击时的凝视角度，超出这个角度会转向凝视目标
        --技能1
        Skill1 = {
            SkillIndex = 1,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 100, --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 50,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"RandomOfTarget",50},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle2","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 100,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能2
        Skill2 = {
            SkillIndex = 2,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 50, --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 50,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"RandomOfTarget",50},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle2","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 100,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能3
        Skill3 = {
            SkillIndex = 3,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 50, --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 50,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"RandomOfTarget",50},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle2","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 100,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能4
        Skill4 = {
            SkillIndex = 4,--技能索引
            Range = {0,25000}, --攻击范围
            Chance =50 , --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 100,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{3000,530,2100}},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle2","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 50,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能5
        Skill5 = {
            SkillIndex = 5,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 50, --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 100,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{3000,530,2100},1000},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle2","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 100,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能6
        Skill6 = {
            SkillIndex = 6,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 0, --攻击概率
            Cooldown = 7, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 50,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{1185,513,766},1000},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 50,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle3","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 50,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 50,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle3","Idle"},--移动结束后播放动画
        },
        --技能7
        Skill7 = {
            SkillIndex = 7,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 0,--攻击概率
            Cooldown = 7, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 50,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{1185,513,766},1000},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 50,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle3","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 50,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 50,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle3","Idle"},--移动结束后播放动画
        },
        --技能8
        Skill8 = {
            SkillIndex = 8,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 50, --攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 0,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{1185,513,766},1000},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle3","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 100,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },
        --技能9
        Skill9 = {
            SkillIndex = 9,--技能索引
            Range = {0,25000}, --攻击范围
            Chance = 50,--攻击概率
            Cooldown = 20, --攻击冷却
            
            --攻击前调整位置配置
            StartMove_Chance = 0,--攻击前有概率移动
            StartMove_Delay = {0.5,1.5},--技能前多久执行移动动作
            StartMove_Location = {"World",{1185,513,766},1000},--技能前移动到这个位置
            --移动结束后动画配置
            StartAnim_Chance = 0,
            StartAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            StartAnim = {"Idle3","Idle"},--移动结束后播放动画

            --攻击后调整位置配置
            EndMove_Chance = 0,--攻击结束后有概率移动
            EndMove_Delay = {0.5,1.5},--技能结束后多久执行移动动作
            EndMove_Location = {"World",{1185,513,766},1000},--技能结束后移动到这个位置
            --移动结束后动画配置
            EndAnim_Chance = 50,
            EndAnim_Delay = {0.5,1.5},--移动结束后动画间隔
            EndAnim = {"Idle2","Idle"},--移动结束后播放动画
        },

        --追击信息
        Approach_Accpetance = 1000,--追击距离

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
            --出场
            {
                name = "Sequence",
                canInterrupt = false,
                decorators = {
                    {
                        name = "Once",
                    }
                },
                children = {
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = { time = 0.1 },
                    },
                    {
                        name = "PlayMontage",
                        args = { animBBKey = "Enter_Anim", durationBBKey = "Enter_Duration" },
                    },
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = { BBKey = "Enter_Wait" },
                    },
                },
            },
            --挂逼
            {
                id = "Dead",
                name = "Sequence",
                decorators = {
                    {
                        name = "Compare",
                        args = { op = "==", BBKey = "behavior", value = "Dead" },
                    }
                }
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
            --监听血量变化狂暴模式
            {
                id = "Fury",
                name = "Sequence",
                canInterrupt = false,
                decorators = {
                    {
                        name = "InRangeHealth",
                        args = { rangeBBKey = "Fury_Health" },
                    },
                    {
                        name = "Once",
                        args = {},
                    }
                },
                children = {
                    {
                        name = "PlayMontage",
                        args = { animBBKey = "Fury_Anim", durationBBKey = "Fury_Duration" },
                    },
                }
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
                children = {

                },
            },
            --唤醒
            {
                name = "Sequence",
                canInterrupt = false,
                decorators = {
                    {
                        name = "Check",
                        args = { BBKey = "Attack_Target" },
                    },
                    {
                        name = "Once",
                    }
                },
                children = {
                    {
                        name = "PlayMontage",
                        args = { animBBKey = "WakeUp_Anim", durationBBKey = "WakeUp_Duration" },
                    },
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = { BBKey = "WakeUp_Wait" },
                    },
                    {
                        name = "MoveByLocation",
                        args = { targetLocationBBKey = "WakeUp_MoveLocation", errBBKey = "locationErr" },
                    },
                    {
                        name = "Wait",
                        decorators = {
                        },
                        args = { BBKey = "WakeUp_MoveLocation_Wait" },
                    },
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
                            {
                                name = "Compare",
                                args = { op = "==", BBKey = "behavior", value = "Stand" },
                            }
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
                    --攻击10
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill10",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击9
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill9",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击8
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill8",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击7
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill7",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击6
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill6",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击5
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill5",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击4
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill4",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击3
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill3",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击2
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill2",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
                            },

                        }
                    },
                    --攻击1
                    {
                        name = "Sequence",
                        bbKeyGroup = "Skill1",
                        decorators = {
                            {
                                name = "Cooldown",
                                args = { cooldownBBKey = "Cooldown" },
                            },
                            {
                                name = "Chance",
                                args = { chanceBBKey = "Chance" },
                            },
                            {
                                name = "InRangeToTarget",
                                args = { targetBBKey = "Attack_Target", rangeBBKey = "Range" },
                            },
                        },
                        children = {
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "StartMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "StartAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "StartAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "StartAnim", duration = 1 },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "InAngleToTarget",
                                        args = { targetBBKey = "Attack_Target", angleBBKey = "Attack_Gaze_Angle",invert = true },
                                    },
                                },
                                children = {
                                    {
                                        name = "RotateToTarget",
                                        canInterrupt = false,
                                        args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
                                    },
        
                                }
                            },
                            {
                                name = "Attack",
                                args = {skillIndexBBKey = "SkillIndex"},
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndMove_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndMove_Delay" },
                                    },
                                    {
                                        name = "FindLocation",
                                        args = {locationBBKey = "EndMove_Location", targetLocationBBKey = "targetLocation" },
                                    },
                                    {
                                        name = "MoveToLocation",
                                        args = { targetLocationBBKey = "targetLocation", errBBKey = "locationErr" },
                                    },
        
                                }
                            },
                            {
                                name = "Sequence",
                                alwaysSuccess = true,
                                decorators = {
                                    {
                                        name = "Chance",
                                        args = { chanceBBKey = "EndAnim_Chance" },
                                    },
                                },
                                children = {
                                    {
                                        name = "Wait",
                                        args = { BBKey = "EndAnim_Delay" },
                                    },
                                    {
                                        name = "PlayMontage",
                                        args = { animBBKey = "EndAnim", duration = 1 },
                                    },
        
                                }
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
                                canInterrupt = false,
                                args = { targetBBKey = "Attack_Target", turnLeftBBKey = "Locomotion_Anim_TurnL", turnRightBBKey = "Locomotion_Anim_TurnR" },
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