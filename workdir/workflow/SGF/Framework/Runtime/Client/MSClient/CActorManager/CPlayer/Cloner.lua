--brief 分身
--Date:2024年6月20日
--Author:Tom
--Copyright (c) 2024 迷你创想. All rights reserved.
local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Quat = GFScript("CoreModule.Math.Quat")

local Cloner = Class.New("Cloner")

--实例化
function Cloner:Constructor(actor, skill, template)
    --初始化根节点
    self:InitRootNode()

    self.actor = actor
    --技能
    self.skill = skill
    
    if template ~= nil then
        self.bindObj = template:Clone()
        local body = self.bindObj.Body
        if body then
            body.Visible = false
            self.animator = body:GetAnimator()
            local listener = nil
            listener = self.animator.UpdateAssetNotify:connect(function(url, state)
                if state then
                    listener:disconnect()
                    listener = nil
                    body.Visible = true
                end
            end)
        end
    end
end

--创建根节点
function Cloner:InitRootNode()
    local workspace = MSClient.CMapManager:GetCurWorkspaceObj()
    if workspace.ClonerRootNode == nil then
        local newNode = SandboxNode.New('SandboxNode')
        newNode.Name = 'ClonerRootNode'
        newNode.Parent = workspace
        self.rootNode = newNode
    else
        self.rootNode = workspace.ClonerRootNode
    end
end

--设置父节点
function Cloner:SetParent(parent)
    self.bindObj.Parent = parent
end

--获取Body
function Cloner:GetBody()
    local body = self.bindObj
    if body and body.Body then
        body =  body.Body
    end
    return body
end

--初始化
function Cloner:Start(params)
    if not self.bindObj then
        return
    end

    self:SetParent(self.actor.node)

    local startPos = self.actor.node.Position
    if params.groundCast then
        local groundPos = self.actor:GetGroundPosition(startPos)
        startPos = Vector3.New(groundPos.x, groundPos.y, groundPos.z)
    end
        
    self.bindObj.Position = startPos
    self.bindObj.LocalEuler = Vector3.New(0, 0, 0)

    -- 坐标
    if params.localPosition ~= nil then
        self.bindObj.LocalPosition = self.bindObj.LocalPosition + Vector3.New(params.localPosition.x, params.localPosition.y, params.localPosition.z)
    end
    -- 旋转
    if params.localEuler ~= nil then
        self.bindObj.LocalEuler = self.bindObj.LocalEuler + Vector3.New(params.localEuler.x, params.localEuler.y, params.localEuler.z)
    end
    -- 缩放
    if params.localScale ~= nil then
        self.bindObj.LocalScale = self.bindObj.LocalScale + Vector3.New(params.localScale.x, params.localScale.y, params.localScale.z)
    end

    self:SetParent(self.rootNode)

    self:Attack(params)
end

-- 攻击
function Cloner:Attack(params)
    --获取当前的移动方向，为0表示后方
    local inputDir = self.actor.AvatarComponent:GetInputDir()
    if not inputDir:IsZero() then
        local orient = Quat.New()
        orient:FromDirection(inputDir * -1)
        if self.bindObj then
            self.bindObj.Rotation = Quaternion.New(orient.x,orient.y,orient.z,orient.w)
        end
    end
    if self.animator then
        self.animator:Play(params.animation, 0, 0)
    end
end

--销毁
function Cloner:Destructor()
    self.animator = nil

    if self.bindObj then
        self.bindObj:Destroy()
    end
end

return Cloner