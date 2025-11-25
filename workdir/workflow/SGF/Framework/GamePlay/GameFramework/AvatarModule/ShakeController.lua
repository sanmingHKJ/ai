local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec2 = GFScript("CoreModule.Math.Vec2")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Math = GFScript("CoreModule.Math")
local Tween = GFScript("CoreModule.Tween")
local Perlin = GFScript("CoreModule.Math.Perlin")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")

local ShakeController = Class.New("ShakeController")

--震动数据
local ShakeData = 
{
    --曲线类型
    easing = "Linear",
    --曲线参数
    easingStart = 0.0,
    easingEnd = 1.0,
    --震动持续时间
    duration = 1.0,
    --震动频率
    frequency = 0.05,
    --强度
    strength = 1.0,
    --旋转参数
    rotX = 0.0,
    rotY = 0.0,
    rotZ = 0.0,
    --位移参数
    posX = 0.0,
    posY = 0.0,
    posZ = 0.0,
    --运行状态
    loop = false,
    stop = false,
    stopFade = false,

    elapsedTime = 0.0,
    rotDelta = nil,
    posDelta = nil,
    randSeed = nil,
}


--初始化
function ShakeController:Constructor()
    self.shakeDatas = {}
    self._shaking = false

    self._shakePosDelta = Vec3.New(0,0,0)
    self._shakeRotDelta = Vec3.New(0,0,0)

end

--加载震动数据
function ShakeController:LoadData(name)
    local data = DataProviderManager:GetData("ShakeConfig",name)
    if not data then
        return false
    end
    data = Utils:ShallowCopy(data)
    data.stop = true
    data._posShake = data.posX ~= 0.0 or data.posY ~= 0.0 or data.posZ ~= 0.0
    data._rotShake = data.rotX ~= 0.0 or data.rotY ~= 0.0 or data.rotZ ~= 0.0
    self.shakeDatas[name] = data
    self.shakeDatas[name].stop = true
    return true
end

--震动屏幕
--spaceData: 震动空间数据，包含位置、半径、衰减，{pos = Vec3.New(0,0,0), radius = 10.0, decay = 1.0, strengthScale = 1.0}
function ShakeController:Start(name, spaceData)
    if not self.shakeDatas[name] then
        self:LoadData(name)
    end
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stop = false
    self.shakeDatas[name].loop = false
    self.shakeDatas[name].elapsedTime = 0.0
    self.shakeDatas[name].posDelta = Vec3.New(0,0,0)
    self.shakeDatas[name].rotDelta = Vec3.New(0,0,0)
    self.shakeDatas[name].randSeed = Math:Random(0, 36)
    self.shakeDatas[name].spaceData = spaceData
end
--开始持续震动
--spaceData: 震动空间数据，包含位置、半径、衰减，{pos = Vec3.New(0,0,0), radius = 10.0, decay = 1.0, strengthScale = 1.0}
function ShakeController:StartLoop(name, spaceData)
    if not self.shakeDatas[name] then
        self:LoadData(name)
    end
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stop = false
    self.shakeDatas[name].loop = true
    self.shakeDatas[name].elapsedTime = 0.0
    self.shakeDatas[name].posDelta = Vec3.New(0,0,0)
    self.shakeDatas[name].rotDelta = Vec3.New(0,0,0)
    self.shakeDatas[name].randSeed = Math:Random(0, 36)
    self.shakeDatas[name].spaceData = spaceData
end
--停止持续震动
function ShakeController:StopLoop(name)
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].loop = false
end
--淡出震动
function ShakeController:StopFade(name)
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stopFade = true
    self.shakeDatas[name].loop = false
end

--停止震动
function ShakeController:Stop(name)
    self.shakeDatas[name].stop = true
    self.shakeDatas[name].loop = false
end

--停止全部
function ShakeController:StopAll()
    for name, shakeData in pairs(self.shakeDatas) do
        shakeData.stop = true
        shakeData.loop = false
    end
end

--是否有正在震动的数据
function ShakeController:HasAnyShake()
    for name, shakeData in pairs(self.shakeDatas) do
        if not shakeData.stop then
            return true
        end
    end
    return false
end

function ShakeController:Update(dt, actorPos)
    self._shakeRotDelta = Vec3.New(0,0,0)
    self._shakePosDelta = Vec3.New(0,0,0)

    self._shaking = false
    for name, shakeData in pairs(self.shakeDatas) do
        if not shakeData.stop then
            self._shaking = true
            --进行震动
            self:Shake(shakeData,dt, actorPos)
            self._shakePosDelta = self._shakePosDelta + shakeData.posDelta
            self._shakeRotDelta = self._shakeRotDelta + shakeData.rotDelta
        end
    end
end
--震动屏幕
function ShakeController:Shake(shakeData, dt, actorPos)
    local function Noise2D(x,y)
        return Perlin:StaticNoise2D(x, y)
    end
    if not shakeData.stop and shakeData.elapsedTime < shakeData.duration then
        local strengthScale = 1.0
        if shakeData.spaceData then
            if actorPos and shakeData.spaceData.pos then
                local pos = actorPos:Distance(shakeData.spaceData.pos)
                if pos < shakeData.spaceData.radius then
                    strengthScale = 1.0 - pos / shakeData.spaceData.radius
                else
                    strengthScale = 0.0
                end
            end
            strengthScale = strengthScale * shakeData.spaceData.strengthScale
        end
        --执行震动
        shakeData.elapsedTime = shakeData.elapsedTime + dt

        if strengthScale > 0.0 then
            local progress = shakeData.elapsedTime / shakeData.duration
            local easingProgress = Tween[shakeData.easing or "Linear"](progress)
            local easingValue = shakeData.easingStart + (shakeData.easingEnd - shakeData.easingStart) * easingProgress
            if shakeData._rotShake then
                local rx = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 0.0) - 0.5
                local ry = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 1.0) - 0.5
                local rz = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 2.0) - 0.5
                shakeData.rotDelta = Vec3.New(rx, ry, rz) * Vec3.New(shakeData.rotX,shakeData.rotY,shakeData.rotZ) * shakeData.strength * strengthScale * easingValue
            end
            if shakeData._posShake then
                local px = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 3.0) - 0.5
                local py = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 4.0) - 0.5
                local pz = Noise2D(shakeData.elapsedTime * shakeData.frequency, shakeData.randSeed + 5.0) - 0.5
                shakeData.posDelta = Vec3.New(px, py, pz) * Vec3.New(shakeData.posX,shakeData.posY,shakeData.posZ) * shakeData.strength * strengthScale * easingValue
            end
        end


        if shakeData.stopFade then
            shakeData.duration = shakeData.elapsedTime + 1.0
            shakeData.stopFade = false
        end
    else
        --震动完毕
        if shakeData.loop then
            shakeData.stop = false
            shakeData.elapsedTime = 0.0
        else
            shakeData.stop = true
        end
    end
end
--是否正在震动
function ShakeController:IsShaking()
    return self._shaking
end
--获取震动位移
function ShakeController:GetPosDelta()
    return self._shakePosDelta
end
--获取震动旋转
function ShakeController:GetRotDelta()
    return self._shakeRotDelta
end

return ShakeController