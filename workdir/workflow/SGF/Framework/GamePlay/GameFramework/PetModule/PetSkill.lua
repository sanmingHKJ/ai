local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ConfigLoaderSetup = GFScript("CoreModule.ConfigLoaderSetup")
local PetSettings = GFScript("PetModule.PetSettings")
local PetManager = GFScript("PetModule.PetManager")

local PetSkill = Class.New("PetSkill")

local eventClasses = {}

--实例化
function PetSkill:Constructor()
    self.skillEvents = {}
end

function PetSkill:Destructor()
    for _, event in ipairs(self.skillEvents) do
        event:Destroy()
    end
    self.skillEvents = {}
end

function PetSkill:Init(pet, data, skillIndex)
    self.pet = pet
    self.data = data
    self.skillIndex = skillIndex
    if data.events then
        for eventIndex, eventTid in ipairs(data.events) do
            local skillEvent = PetManager:GetPetSkillEvent(eventTid)
            if skillEvent then
                local eventClass = eventClasses[skillEvent.eventName]
                if eventClass then
                    local event = eventClass.New()
                    event:Init(pet, self, skillEvent, eventIndex)
                    table.insert(self.skillEvents, event)
                end
            end
        end
    elseif data.event then
        local eventClass = eventClasses[data.event.eventName]
        if eventClass then
            local event = eventClass.New()
            event:Init(pet, self, data.event, 0)
            table.insert(self.skillEvents, event)
        end
    end

    self:SyncSkillState()
    self:UpdateSkillState()
end

function PetSkill:Update(dt)
    for _, event in ipairs(self.skillEvents) do
        event:Update(dt)
    end
end

function PetSkill:GetEventByIndex(eventIndex)
    eventIndex = eventIndex or 1
    return self.skillEvents[eventIndex]
end

function PetSkill:GetPlayer()
    return self.pet:GetMaster()
end

--获取技能剩余时间
function PetSkill:GetRemainingTime(skillEventIndex)
    skillEventIndex = skillEventIndex or 1
    local event = self.skillEvents[skillEventIndex]
    if not event then
        return 0
    end
    return event:GetRemainingTime()
end

function PetSkill:SyncSkillState()
    local skillInfo = {}
    self:Serialize(skillInfo, "Sync")
    local player = self:GetPlayer()
    if player then
        player.PetComponent:SetPetSkillState(self.pet.petId, self.skillIndex, skillInfo)
    end
end

function PetSkill:NotifySkillEventExecuted(skillEventIndex)
    self:SyncSkillState()
    local player = self:GetPlayer()
    if player then
        player.PetComponent:NotifySkillEventExecuted(self.pet.petId, self.skillIndex, skillEventIndex)
    end
end

function PetSkill:UpdateSkillState()
    local player = self:GetPlayer()
    if player then
        local pet = self.pet:GetPet()
        if pet then
            local skillInfo = pet:GetSkillState(self.skillIndex)
            if skillInfo then
                self:Deserialize(skillInfo)
            end
        end
    end
end

function PetSkill:PackSkillInfo()
    local skillInfo = {}
    skillInfo.skillIndex = self.skillIndex
    skillInfo.events = {}
    for _, event in ipairs(self.skillEvents) do
        table.insert(skillInfo.events, event:PackSkillEventInfo())
    end
    return skillInfo
end

--序列化
function PetSkill:Serialize(data, purpose)
    data.skillEvents = {}
    for _, event in ipairs(self.skillEvents) do
        local eventData = {}
        event:Serialize(eventData, purpose)
        table.insert(data.skillEvents, eventData)
    end
end

--反序列化
function PetSkill:Deserialize(data)
    for index, eventData in ipairs(data.skillEvents) do
        local event = self.skillEvents[index]
        if event then
            event:Deserialize(eventData)
        end
    end
end


local function LoadEventClass(rootNode)
    for _, eventNode in ipairs(rootNode.Children) do
        if eventNode.ClassType == 'ModuleScript' then
            eventClasses[eventNode.Name] = require(eventNode)
        end
    end
end

LoadEventClass(Utils:GetMainStorageNode("Scripts.GameFramework.PetModule.PetSkill.PetSkillEvent"))


return PetSkill