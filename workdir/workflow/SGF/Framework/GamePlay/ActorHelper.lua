--[[
    ActorHelper - 角色系统辅助工具

    位置: Framework/GamePlay/
    依赖: CoreModule.Math (Vec3, Quat), CoreModule.Utils, CoreModule.Sound.SoundManager

    功能说明:
    - PlayHitFeedback: 播放受击反馈效果（震屏、震动、顿帧、屏幕色差）
    - PlayPostProcessing: 播放后处理效果（屏幕色差等）
    - PlayFootstepSound: 播放脚步声（根据地面材质自动选择音效）

    使用场景:
    - 战斗系统：受击反馈、打击感
    - 角色移动：脚步声播放
    - 视觉效果：后处理特效

    使用示例:
    ```lua
    local ActorHelper = require(MainStorage.Scripts.ActorHelper)

    -- 播放受击反馈
    ActorHelper:PlayHitFeedback(localPlayer, damageResult, skillData.hitFeedback)

    -- 播放脚步声
    ActorHelper:PlayFootstepSound(self:GetPosition(), 'Footstep/Monster_', true)
    ```

    注意事项:
    - 仅在客户端使用
    - PlayHitFeedback需要localPlayer对象
    - 脚步声会根据地面材质自动选择音效（水面、草地、石头等）

    引用位置:
    - Framework/Runtime/Client/MSClient/CActorManager/CNpc.lua
    - Framework/Runtime/Client/MSClient/CActorManager/CPlayer.lua
]]

local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Utils = GFScript("CoreModule.Utils")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")

local ActorHelper = {}

--受击反馈
function ActorHelper:PlayHitFeedback(localPlayer, damageResult, hitFeedback)
	if damageResult.causer and damageResult.causer == localPlayer then
        local targetIsPlayer = damageResult.target:IsPlayer()
        --震屏
        local cameraShake = hitFeedback.cameraShake
        if cameraShake and cameraShake ~= "" then
            localPlayer.CameraController:StopAllShake()
            localPlayer.CameraController:StartShake(cameraShake)
        end
        --震屏
        local objShake = hitFeedback.objShake
        if objShake and objShake ~= "" then
            damageResult.target.AvatarComponent:StartShake(objShake)
        end
        --顿帧
        local pauseTime = hitFeedback.pauseTime
        if pauseTime and pauseTime > 0 then
            localPlayer.AvatarComponent:PauseResumeAnimDelay(pauseTime, hitFeedback.speed)
            damageResult.target.AvatarComponent:PauseResumeAnimDelay(pauseTime, hitFeedback.speed)
        end
        --屏幕效果
        local ca = hitFeedback.ca
        if ca then
            localPlayer.CameraController:StartChromaticAberration(ca.duration,ca.intensity,ca.startOffset,ca.iterationStep,ca.iterationSamples)
        end

        --测试代码
        -- damageResult.target.AvatarComponent:StartShake("MonsterHit")
        -- localPlayer.CameraController:StopAllShake()
        -- localPlayer.CameraController:StartShake("Punch")
        -- localPlayer.CameraController:StartChromaticAberration(0.3,5)
    end
end

--后处理
function ActorHelper:PlayPostProcessing(localPlayer, params)
    --屏幕效果
    local ca = params.ca
    if ca then
        localPlayer.CameraController:StartChromaticAberration(ca.duration,ca.intensity,ca.startOffset,ca.iterationStep,ca.iterationSamples)
    end
end

--播放脚步声
function ActorHelper:PlayFootstepSound(pos, soundPath, isLeft)
    local needPlay, pos, tag = Utils:GetFootstepInfo(pos)
    if needPlay then
        local path = nil
        if isLeft then
            path = soundPath..tag..'_L.mp3'
        else
            path = soundPath..tag..'_R.mp3'
        end

        -- print("@@@@@@@@@@@@@  PlayFootstepSound   soundPath = ", soundPath, ',tag = ', tag, ', path = ', path)
        -- MSClient.CSoundManager:PlaySound(path, Vector3.New(pos.x, pos.y, pos.z))
        local soundPath =  MS.Utils.Resources:GetSoundID(path)
        SoundManager:PlaySound("Footstep", soundPath, {pos = pos, priority = 10})
    else
        -- print("@@@@@@@@@@@@@  PlayFootstepSound   no need play")
    end
end

return ActorHelper