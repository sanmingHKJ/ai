local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Database = GFScript("CoreModule.Database")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local GlobalEvent = GFScript("CoreModule.GlobalEvent")
local NetworkSetup = GFScript("NetworkModule.NetworkSetup")
local Math = GFScript("CoreModule.Math")
local SoundManager = GFScript("CoreModule.Sound.SoundManager")
local TimerManager = GFScript("CoreModule.TimerManager")
local UIManager = GFScript("UIModule.UIManager")
local Math = GFScript("CoreModule.Math")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorUtils = GFScript("ActorModule.ActorUtils")
local SummonComponent = Class.New("SummonComponent", ActorComponent)

SummonComponent.version = 1

--实例化
function SummonComponent:Constructor()
    self.summons = {}
    self.maxSummonCount = 99
end

function SummonComponent:Destructor()
    self:DestroyAllSummons()
end

--设置最大召唤数量
function SummonComponent:SetMaxSummonCount(maxSummonCount)
    self.maxSummonCount = maxSummonCount
    if self:IsServer() then
        self:TRpcSetMaxSummonCount(maxSummonCount)
    end
end

--生成召唤
function SummonComponent:Summon(tid, summonPos, summonRotation, preCallback, finishedCallback)
    if not self.actor:IsServer() then
        Log:Error("Summon failed, not server")
        return
    end

    if #self.summons >= self.maxSummonCount then
        Log:Error("Summon failed, max summon count = %d",self.maxSummonCount)
        return
    end

    local config = ActorManager:GetActorConfig(tid)

    if config == nil then
        Log:Error("SpawnActor failed, tid = %s",tid)
        return
    end
    local nodeTemplate = Utils:GetServerStorageNode(config.modelId)
    if nodeTemplate == nil then
        Log:Error("SpawnActor failed, tid = %s",tid)
        return
    end
    local actorType = ActorUtils:GetActorType(tid)

    local workspace = self.actor:GetScene():GetWorkspace()
    local summon = ActorManager:ServerCreateActor(workspace, actorType, nodeTemplate, true, function(summon)
        if preCallback then
            preCallback(summon)
        end
        summon:SetCollideGroup(ActorDefines.CollideGroup.NoCollide)
        summon:SetMaster(self.actor)
        summon:LoadConfigFromTid(tid)

        summon.HealthComponent:SetFull()

        if not summonPos then
            local offsetPos = Vec3.New(200, 0, 0)
            local pos = self.actor:GetOffsetPosition(offsetPos)
            local validPos = self.actor:GetValidPosition(pos)
            summon:SetPosition(validPos)
            summon:SetBornPosition(validPos) 
        else
            summon:SetPosition(summonPos)
            summon:SetBornPosition(summonPos)
        end

        if not summonRotation then
            summon:SetRotation(self.actor.AvatarComponent:GetRotation())
        else
            summon:SetRotation(summonRotation)
        end

        if finishedCallback then
            finishedCallback(summon)
        end
    end)
    table.insert(self.summons, summon)
    return summon
end

--销毁展示宠物
function SummonComponent:DestroySummon(summon)
    if not self.actor:IsServer() then
        Log:Error("DestroySummon failed, not server")
        return
    end
    if summon then
        ActorManager:ServerDestroyActor(summon)
    end
    for i, v in ipairs(self.summons) do     
        if v == summon then
            table.remove(self.summons, i)
            break
        end
    end
end

function SummonComponent:GetSummon(index)
    if index and index > 0 and index <= #self.summons then
        return self.summons[index]
    end
    return nil
end


function SummonComponent:DestroyAllSummons()
    for i, v in ipairs(self.summons) do
        ActorManager:ServerDestroyActor(v)
    end
    self.summons = {}
end

-----------------------------------------------------------------------

--序列化
function SummonComponent:Serialize(data, purpose)
    data.version = self.version
    SummonComponent.super.Serialize(self, data, purpose)
    data.maxSummonCount = self.maxSummonCount

    if purpose == "Save" then
        --保存已经召唤的宠物列表
        data.summons = {}
        for i, v in ipairs(self.summons) do
            local summonData = {}
            v:Serialize(summonData, purpose)
            table.insert(data.summons, summonData)
        end
    end
end

--反序列化
function SummonComponent:Deserialize(data)
    self.version = data.version
    SummonComponent.super.Deserialize(self, data)
    self.maxSummonCount = data.maxSummonCount


    if data.summons then
        for i, v in ipairs(data.summons) do
            local summon = self:Summon(v.tid)
            summon:Deserialize(v)
            table.insert(self.summons, summon)
        end
    end
end
-----------------------------------------Cmd-----------------------------------------

-----------------------------------------Rpc-----------------------------------------
function SummonComponent:TRpcSetMaxSummonCount(maxSummonCount)
    self:SetMaxSummonCount(maxSummonCount)
end


return SummonComponent