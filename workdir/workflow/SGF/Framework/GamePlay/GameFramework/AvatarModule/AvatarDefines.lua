local AvatarDefines = {}

--运动状态枚举
AvatarDefines.ELocomotionState = {
    Idle = "Idle",              -- 静止
    Walk = "Walk",              -- 静步走
    Move = "Move",              -- 行走
    Run = "Run",                -- 奔跑
    Sprint = "Sprint",          -- 冲刺
    Jump = "Jump",              -- 跳跃
    Jumping = "Jumping",        -- 跳跃中
    Fly = "Fly",                -- 飞行
    Fall = "Fall",              -- 下落
    Slide = "Slide",            -- 滑铲（Sprint后触发）
    Climb = "Climb",            -- 攀爬
    Vault = "Vault",            -- 越障
    Swim = "Swim",              -- 游泳
    Glide = "Glide",            -- 滑翔
    CrouchWalk = "CrouchWalk",  -- 蹲行
}

--姿态枚举
AvatarDefines.EPoseState = {
    Stand = "Stand",        -- 站立
    Crouch = "Crouch",      -- 蹲伏
    Prone = "Prone",        -- 趴伏
    Swim = "Swim",          -- 游泳
    SwimDive = "SwimDive",  -- 潜水（水下专用）
    Fly = "Fly",            -- 飞行
    Dead = "Dead",          -- 死亡
    Sit = "Sit",            -- 坐下
    Kneel = "Kneel",        -- 跪姿
    LeanLeft = "LeanLeft",  -- 左倾
    LeanRight = "LeanRight",-- 右倾
    Hang = "Hang",          -- 悬挂
    Aim = "Aim",            -- 瞄准姿态（影响移动速度）
}

--移动类型
AvatarDefines.EMoveType = {
    Walk = "Walk",              -- 静步走
    Move = "Move",              -- 行走
    Run = "Run",                -- 奔跑
    Sprint = "Sprint",          -- 冲刺
    CrouchWalk = "CrouchWalk",  -- 蹲走
    ProneCrawl = "ProneCrawl",  -- 匍匐爬行（极慢）
    Swim = "Swim",              -- 游泳
    Climb = "Climb",            -- 攀爬
    Vault = "Vault",            -- 越障
}

AvatarDefines.EncodeLocomotionState = function(state)
    if state == AvatarDefines.ELocomotionState.Idle then
        return 1
    elseif state == AvatarDefines.ELocomotionState.Walk then
        return 2
    elseif state == AvatarDefines.ELocomotionState.Move then
        return 3
    elseif state == AvatarDefines.ELocomotionState.Run then
        return 4
    elseif state == AvatarDefines.ELocomotionState.Sprint then
        return 5
    elseif state == AvatarDefines.ELocomotionState.Jump then
        return 6
    elseif state == AvatarDefines.ELocomotionState.Jumping then
        return 7
    elseif state == AvatarDefines.ELocomotionState.Fly then
        return 8
    elseif state == AvatarDefines.ELocomotionState.Fall then
        return 9
    end
    return 1
end
AvatarDefines.DecodeLocomotionState = function(state)
    if state == 1 then
        return AvatarDefines.ELocomotionState.Idle
    elseif state == 2 then
        return AvatarDefines.ELocomotionState.Walk
    elseif state == 3 then
        return AvatarDefines.ELocomotionState.Move
    elseif state == 4 then
        return AvatarDefines.ELocomotionState.Run
    elseif state == 5 then
        return AvatarDefines.ELocomotionState.Sprint
    elseif state == 6 then
        return AvatarDefines.ELocomotionState.Jump
    elseif state == 7 then
        return AvatarDefines.ELocomotionState.Jumping
    elseif state == 8 then
        return AvatarDefines.ELocomotionState.Fly
    elseif state == 9 then
        return AvatarDefines.ELocomotionState.Fall
    end
    return AvatarDefines.ELocomotionState.Idle
end


AvatarDefines.NormalLocomotionState = function(character)
    local state = character:GetCurMoveState()
    if state == Enum.BehaviorState.ZERO then
        return AvatarDefines.ELocomotionState.Idle
    elseif state == Enum.BehaviorState.Jump then
        return AvatarDefines.ELocomotionState.Jump
    elseif state == Enum.BehaviorState.Jumping then
        return AvatarDefines.ELocomotionState.Jumping
    elseif state == Enum.BehaviorState.Stand then
        return AvatarDefines.ELocomotionState.Idle
    elseif state ==Enum.BehaviorState.Walk then
        return AvatarDefines.ELocomotionState.Walk
    elseif state ==Enum.BehaviorState.Fly then
        return AvatarDefines.ELocomotionState.Fly
    elseif state ==Enum.BehaviorState.Died then
        return AvatarDefines.ELocomotionState.Idle
    end
    return 1
end

return AvatarDefines