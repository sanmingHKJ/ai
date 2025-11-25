local Class = GFScript("CoreModule.Class")
local ActorComponent = GFScript("ActorModule.ActorComponent")

local CampComponent = Class.New("CampComponent", ActorComponent)

--版本号
CampComponent.version = 1

--构造函数
function CampComponent:Constructor(owner)
end

--初始化
function CampComponent:Init()
    CampComponent.super.Init(self)
end

--获取阵营
function CampComponent:GetCamp()
    return self.camp
end

--设置阵营
function CampComponent:SetCamp(camp)
    self.camp = camp
end

--获取阵营关系
function CampComponent:GetRelation(targetCampComp)
    if self:GetCamp() == targetCampComp:GetCamp() then
        --友好
        return "Friend"
    end
    --敌对
    return "Enemy"
end
-----------------------------------------------------------------------

--序列化
function CampComponent:Serialize(data, purpose)
    data.version = self.version
    CampComponent.super.Serialize(self, data, purpose)
    data.camp = self:GetCamp()
end

--反序列化
function CampComponent:Deserialize(data)
    self.version = data.version
    CampComponent.super.Deserialize(self, data)
    self:SetCamp(data.camp)
end

function CampComponent:CopyFrom(src)
    self:SetCamp(src:GetCamp())
end


return CampComponent