local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActorManager = GFScript("ActorModule.ActorManager")

local FixedJoint = Class.New("FixedJoint")

--实例化
function FixedJoint:Constructor()
    --目标
    self.source = nil
    self.target = nil
end
--析构
function FixedJoint:Destructor()
    GameFramework:UnRegisterLaterUpdate(self)
end
--初始化
function FixedJoint:Init(source, target)
    self.source = source
    self.target = target
    --计算两者的偏移变换
    self.sourcePos = source:GetPosition()
    self.sourceRot = source:GetRotation()
    self.prevSourcePos = source:GetPosition()
    self.offset = target:GetPosition() - self.sourcePos
    self.rotation = target:GetRotation() * self.sourceRot:Inversed()
    GameFramework:RegisterLaterUpdate(self)
end

function FixedJoint:OnLaterUpdate(dt)
    local posDelta = self.source:GetPosition() - self.prevSourcePos
    -- local newPos = self.source:GetPosition() + self.offset
    local newRot = self.source:GetRotation() * self.rotation
    -- self.target:SetPosition(newPos)
    self.target.AvatarComponent:MoveStep(posDelta)

    self.target:SetRotation(newRot)

    self.prevSourcePos = self.source:GetPosition()
end



return FixedJoint