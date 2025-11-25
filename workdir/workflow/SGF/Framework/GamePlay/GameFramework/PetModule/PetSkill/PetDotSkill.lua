local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local PetSkill = GFScript("PetModule.PetSkill")
local PetSettings = GFScript("PetModule.PetSettings")
local TimerManager = GFScript("CoreModule.TimerManager")
local PetDotSkill = Class.New("PetDotSkill", PetSkill)

--实例化
function PetDotSkill:Constructor()
    self.dotInterval = 0
    self.dotTimeEnd = 0
end

function PetDotSkill:Destructor()
    self:StopDot()
end

function PetDotSkill:Init(pet, skillData)
    PetDotSkill.super.Init(self, pet, skillData)
    self.dotInterval = skillData.dotInterval or 0
    self.dotTimeEnd = Utils:GetServerTime() + self.dotInterval
    self:StartDot()
end

-- 开始持续
function PetDotSkill:StartDot()
    if self.dotInterval <= 0 then
        return
    end
    self:StopDot()
    self.dotTimeEnd = Utils:GetServerTime() + self.dotInterval
    self.dotTimer = TimerManager:AddTimer(function()
        if Utils:GetServerTime() >= self.dotTimeEnd then
            self:OnDot()
            self.dotTimeEnd = Utils:GetServerTime() + self.dotInterval
        end
    end, 1)
end

function PetDotSkill:StopDot()
    if self.dotTimer then
        TimerManager:RemoveTimer(self.dotTimer)
        self.dotTimer = nil
    end
end

-- 持续
function PetDotSkill:OnDot()
    self:ExecuteEvents(self.skillData.events)
    return true
end

--序列化
function PetDotSkill:Serialize(data, purpose)
    --剩余多少时间
    local remainingTime = self.dotTimeEnd - Utils:GetServerTime()
    data.remainingTime = math.max(0, remainingTime)

end

--反序列化
function PetDotSkill:Deserialize(data)
    if data.remainingTime > 0 then
        self.dotTimeEnd = Utils:GetServerTime() + data.remainingTime
    else
        self.dotTimeEnd = Utils:GetServerTime() + self.dotInterval
    end
end

return PetDotSkill