-- 说明:震动action
-- 日期:2025年3月7日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIAction = GFScript("UIModule.UIAction")
local Ease = GFScript("UIModule.UIMath.Ease")
local Vec2 = GFScript("UIModule.UIMath.Vec2")

local UIShake = UIClass.New("UIShake", UIAction)

local function Noise(x, y, z)
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local n = x + y * 57 + z * 57 * 57
	n = n + n / 2
	n = math.floor(n)
	n = (n % 289) + 1
	local s = math.floor((n +31) / 32)
    return (((s * s * 31 + s) * 6 + s) % 289) / 289.0
end

local function Noise2D(x, y, octaves, persistence)
	local total = 0
	local frequency = 1
	local amplitude = 1
	local maxValue = 0
	local d = octaves or 6
    persistence = persistence or 0.5
	for i = 1, d do
		total = total + Noise(x * frequency, y * frequency) * amplitude
		maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
	end
    return total / maxValue
end

local NoiseData_2D = nil

local function StaticNoise2D(x, y)
	if NoiseData_2D == nil then
		NoiseData_2D = {}
		for y = 1, 64 do
			NoiseData_2D[y] = {}
			for x = 1, 64 do
				NoiseData_2D[y][x] = Noise2D(x, y)
			end
		end
	end
	x = math.floor(x) % 64 + 1
	y = math.floor(y) % 64 + 1
	return NoiseData_2D[y][x]
end

--初始化
function UIShake:Init(duration, params)
    UIAction.Init(self, duration)
    
    -- 默认参数
    self.params = params or {}
    self.params.easing = self.params.easing or "Linear"
    self.params.easingStart = self.params.easingStart or 0.0
    self.params.easingEnd = self.params.easingEnd or 1.0
    self.params.frequency = self.params.frequency or 0.05 -- 频率
    self.params.strength = self.params.strength or 1.0 -- 强度
    
    -- 位置震动参数
    self.params.posX = self.params.posX or 0.0
    self.params.posY = self.params.posY or 0.0
    
    -- 旋转震动参数
    self.params.rot = self.params.rot or 0.0
    
    -- 缩放震动参数
    self.params.scaleX = self.params.scaleX or 0.0
    self.params.scaleY = self.params.scaleY or 0.0
    self.params.scale = self.params.scale or nil
    
    -- 是否循环
    self.params.loop = self.params.loop or false
    
    -- 震动状态
    self._posShake = self.params.posX ~= 0.0 or self.params.posY ~= 0.0
    self._rotShake = self.params.rot ~= 0.0
    self._scaleShake = self.params.scaleX ~= 0.0 or self.params.scaleY ~= 0.0 or self.params.scale ~= nil
    
    -- 震动偏移量
    self.posDelta = Vec2.New(0, 0)
    self.rotDelta = 0
    self.scaleDelta = Vec2.New(0, 0)
    
    -- 随机种子
    self.randSeed = UIUtils:Random(0, 36)
    
    -- 原始变换
    self.originalPos = nil
    self.originalRot = nil
    self.originalScale = nil
end

--开始
function UIShake:StartWith(target)
    UIAction.StartWith(self, target)
    
    -- 保存原始变换
    if self._posShake then
        self.originalPos = self:GetPosition()
    end
    
    if self._rotShake then
        self.originalRot = self:GetRotation()
    end
    
    if self._scaleShake then
        self.originalScale = self:GetScale()
    end
end

--开始
function UIShake:OnStart()
    self.elapsedTime = 0
end

--更新
function UIShake:OnUpdate(t)
    local function Noise2D(x, y)
        return StaticNoise2D(x, y)
    end
    
    self.elapsedTime = self.elapsedTime + t
    
    local progress = self.elapsedTime / self.duration
    local easingProgress = Ease[self.params.easing](progress)
    local easingValue = self.params.easingStart + (self.params.easingEnd - self.params.easingStart) * easingProgress
    
    -- 计算位置震动
    if self._posShake then
        local px = Noise2D(self.elapsedTime * self.params.frequency, self.randSeed + 0.0) - 0.5
        local py = Noise2D(self.elapsedTime * self.params.frequency, self.randSeed + 1.0) - 0.5
        
        self.posDelta = Vec2.New(px, py) * Vec2.New(self.params.posX, self.params.posY) * self.params.strength * easingValue
        
        -- 应用位置震动
        self:SetPosition(self.originalPos + self.posDelta)
    end
    
    -- 计算旋转震动
    if self._rotShake then
        local r = Noise2D(self.elapsedTime * self.params.frequency, self.randSeed + 3.0) - 0.5
        
        self.rotDelta = r * self.params.rot * self.params.strength * easingValue
        
        -- 应用旋转震动
        self:SetRotation(self.originalRot + self.rotDelta)
    end
    
    -- 计算缩放震动
    if self._scaleShake then
        local sx = Noise2D(self.elapsedTime * self.params.frequency, self.randSeed + 6.0) - 0.5
        local sy = Noise2D(self.elapsedTime * self.params.frequency, self.randSeed + 7.0) - 0.5
        
        if self.params.scale then
            self.scaleDelta = Vec2.New(sx, sy) * Vec2.New(self.params.scale, self.params.scale) * self.params.strength * easingValue
        else
            self.scaleDelta = Vec2.New(sx, sy) * Vec2.New(self.params.scaleX, self.params.scaleY) * self.params.strength * easingValue
        end
        
        -- 应用缩放震动
        self:SetScale(self.originalScale + self.scaleDelta)
    end
    
    -- 如果震动结束且需要循环，则重置时间
    if progress >= 1.0 and self.params.loop then
        self.elapsedTime = 0
    end
end

--结束
function UIShake:Stop()
    -- 恢复原始变换
    if self.target then
        if self._posShake and self.originalPos then
            self:SetPosition(self.originalPos)
        end
        
        if self._rotShake and self.originalRot then
            self:SetRotation(self.originalRot)
        end
        
        if self._scaleShake and self.originalScale then
            self:SetScale(self.originalScale)
        end
    end
    
    UIAction.Stop(self)
end

return UIShake
