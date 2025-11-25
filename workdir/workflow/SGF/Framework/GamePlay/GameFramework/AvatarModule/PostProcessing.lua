local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local PostProcessing = Class.New("PostProcessing", ActorComponent)

function PostProcessing:Constructor()
    
end
--启动客户端
function PostProcessing:OnStartClient()

end

function PostProcessing:OnSceneSet(scene)
    if not self:IsServer() and scene then
        local env = scene:GetEnvironment()
        if env then
            self.bindObj = env.PostProcessing
        else
            Log:Error("PostProcessing:OnSceneSet() env is nil")
        end
    end
end

--启用色差
function PostProcessing:EnableChromaticAberration(enable)
    if not self.bindObj then
        return 
    end
    self.bindObj.ChromaticAberrationActive = enable
end

--设置色差强度
function PostProcessing:SetChromaticAberrationIntensity(intensity)
    if not self.bindObj then
        return 
    end
    self.bindObj.ChromaticAberrationIntensity = intensity
end

--获取色差强度
function PostProcessing:GetChromaticAberrationIntensity()
    if not self.bindObj then
        return 0
    end
    return self.bindObj.ChromaticAberrationIntensity
end


--设置色差开始偏移
function PostProcessing:SetChromaticAberrationStartOffset(value)
    if not self.bindObj then
        return 
    end
    self.bindObj.ChromaticAberrationStartOffset = value
end

--获取色差开始偏移
function PostProcessing:GetChromaticAberrationStartOffset()
    if not self.bindObj then
        return 0
    end
    return self.bindObj.ChromaticAberrationStartOffset
end

--设置色差迭代
function PostProcessing:SetChromaticAberrationIterationStep(value)
    if not self.bindObj then
        return 
    end
    self.bindObj.ChromaticAberrationIterationStep = value
end

--获取色差迭代
function PostProcessing:GetChromaticAberrationIterationStep()
    if not self.bindObj then
        return 0
    end
    return self.bindObj.ChromaticAberrationIterationStep
end

--设置色差迭代采样
function PostProcessing:SetChromaticAberrationIterationSamples(value)
    if not self.bindObj then
        return 
    end
    self.bindObj.ChromaticAberrationIterationSamples = value
end

--获取色差迭代采样
function PostProcessing:GetChromaticAberrationIterationSamples()
    if not self.bindObj then
        return 0
    end
    return self.bindObj.ChromaticAberrationIterationSamples
end


return PostProcessing