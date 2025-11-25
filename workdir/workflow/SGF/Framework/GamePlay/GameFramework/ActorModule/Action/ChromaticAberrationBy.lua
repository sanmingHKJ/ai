local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Action = GFScript("ActorModule.Action")

local ChromaticAberrationBy = Class.New("ChromaticAberrationBy", Action)

--初始化
function ChromaticAberrationBy:Init(duration,delta)
    Action.Init(self,duration)
    self.delta = delta
    self.startValue = nil
	self.previousValue = nil
    self.speed = self.delta / self.duration
end

--开始
function ChromaticAberrationBy:StartWith(target)
    Action.StartWith(self, target)
    self.target.PostProcessing:EnableChromaticAberration(true)
    self.startValue = self.target.PostProcessing:GetChromaticAberrationIntensity()
    self.previousValue = self.startValue
end
--开始
function ChromaticAberrationBy:OnStart()
end

--更新
function ChromaticAberrationBy:OnUpdate(t)
    local value = self.target.PostProcessing:GetChromaticAberrationIntensity()
    local diff = value - self.previousValue
    self.startValue = self.startValue + diff
    local newValue = self.startValue + self.delta * t
    self.target.PostProcessing:SetChromaticAberrationIntensity(newValue)
    self.previousValue = newValue
end

--结束
function ChromaticAberrationBy:Stop()
    self.target.PostProcessing:EnableChromaticAberration(false)
    Action.Stop(self)
end


return ChromaticAberrationBy
