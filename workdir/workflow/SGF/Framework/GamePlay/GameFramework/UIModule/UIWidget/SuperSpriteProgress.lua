-- 说明:精灵进度条控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIDefines = GFScript("UIModule.UIDefines")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperProgressBase = GFScript("UIModule.UIWidget.SuperProgressBase") 
local UIUtils = GFScript("UIModule.UIUtils")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local SuperSpriteProgress = UIClass.New("SuperSpriteProgress", SuperProgressBase)

function SuperSpriteProgress:Constructor()
    self.progressType = UIDefines.EProgressType.Horizontal
    self.sprite = nil
    self.spacing = {x = 0, y = 0}
    self.padding = {left = 0, right = 0, top = 0, bottom = 0}
    self.reverse = false

    --未激活精灵
    self.inactiveSprites = {}
    --激活精灵
    self.activeSprites = {}

    self.inactiveSpriteTemplate = nil
    self.activeSpriteTemplate = nil

    self.inactiveSpritePool = {}
    self.activeSpritePool = {}

    self.activePanel = nil
    self.inactivePanel = nil

    self.lastActiveSpriteCount = 0
end 

function SuperSpriteProgress:Destructor()
    -- 清理所有未激活精灵
    for _, sprite in ipairs(self.inactiveSpritePool) do
        self:RecycleInactiveSprite(sprite)
    end
    -- 清理所有激活精灵
    for _, sprite in ipairs(self.activeSpritePool) do
        self:RecycleActiveSprite(sprite)
    end

    if self.activePanel then
        self.activePanel:Destroy()
    end

    if self.inactivePanel then
        self.inactivePanel:Destroy()
    end

    self.activePanel = nil
    self.inactivePanel = nil
    
    self.inactiveSpritePool = {}
    self.activeSpritePool = {}
end
--初始化
function SuperSpriteProgress:Init(bindObj)
    if not SuperSpriteProgress.super.Init(self, bindObj) then
        return false
    end
    
    self.inactivePanel = SandboxNode.New("UIImage")
    self.inactivePanel.Name = "InactivePanel"
    self.inactivePanel.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.inactivePanel.Parent = self.bindObj
    self.inactivePanel.Pivot = Vector2.New(0, 0)
    self.inactivePanel.Position  = Vector2.New(0, 0)
    self.inactivePanel.Size = self.bindObj.Size


    self.activePanel = SandboxNode.New("UIImage")
    self.activePanel.Name = "ActivePanel"
    self.activePanel.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    self.activePanel.Parent = self.bindObj
    self.activePanel.Pivot = Vector2.New(0, 0)
    self.activePanel.Position  = Vector2.New(0, 0)
    self.activePanel.Size = self.bindObj.Size


    self:Refresh()

    return true
end

--大小改变回调
function SuperSpriteProgress:OnSizeChanged()
    self.inactivePanel.Size = self.bindObj.Size
    self.activePanel.Size = self.bindObj.Size
end

--设置进度条形式
function SuperSpriteProgress:SetProgressType(progressType)
    self.progressType = progressType
end

--获取进度条形式
function SuperSpriteProgress:GetProgressType()
    return self.progressType
end

--设置是否反向
function SuperSpriteProgress:SetReverse(reverse)
    self.reverse = reverse
end

--获取是否反向
function SuperSpriteProgress:GetReverse()
    return self.reverse
end

--设置未激活精灵模板
function SuperSpriteProgress:SetInactiveSpriteTemplate(inactiveSpriteTemplate)
    self.inactiveSpriteTemplate = inactiveSpriteTemplate
    if self.inactiveSpriteTemplate then
        self.inactiveSpriteTemplate.Visible = false
        self:Refresh()
    end
end

--获取未激活精灵模板
function SuperSpriteProgress:GetInactiveSpriteTemplate()
    return self.inactiveSpriteTemplate
end

--设置激活精灵模板
function SuperSpriteProgress:SetActiveSpriteTemplate(activeSpriteTemplate)
    self.activeSpriteTemplate = activeSpriteTemplate
    if self.activeSpriteTemplate then
        self.activeSpriteTemplate.Visible = false
        self:Refresh()
    end
end

--获取激活精灵模板
function SuperSpriteProgress:GetActiveSpriteTemplate()
    return self.activeSpriteTemplate
end

--[[
    从对象池中获取一个未激活精灵
    @return: 未激活精灵实例
]]
function SuperSpriteProgress:GetInactiveSpriteFromPool()
    if not self.inactiveSpriteTemplate then
        UILog:Error("GetInactiveSpriteFromPool: inactiveSpriteTemplate is nil")
        return nil
    end
    local function InitSprite(sprite)   
        sprite.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        sprite.Parent = self.inactivePanel
        sprite.Visible = true
        sprite.Position  = Vector2.New(0, 0)
        sprite.Scale = self.inactiveSpriteTemplate.Scale
        UIUtils:SetAlpha(sprite, UIUtils:GetAlpha(self.inactiveSpriteTemplate))
    end
    if #self.inactiveSpritePool > 0 then
        -- 从对象池中获取一个sprite
        local sprite = table.remove(self.inactiveSpritePool)
        if not sprite then
            -- 如果对象池中没有sprite，则创建一个新的sprite
            sprite = self.inactiveSpriteTemplate:Clone()
            InitSprite(sprite)
        else
            InitSprite(sprite)
        end
        return sprite
    end
    -- 如果对象池中没有sprite，则创建一个新的sprite
    local sprite = self.inactiveSpriteTemplate:Clone()
    InitSprite(sprite)
    return sprite
end

--[[
    回收未激活精灵到对象池
    @param sprite: 要回收的未激活精灵对象
]]
function SuperSpriteProgress:RecycleInactiveSprite(sprite)
    if sprite then
        -- 清理父节点关系
        sprite.Parent = self.UIManager:GetNodePoolNode()
        table.insert(self.inactiveSpritePool, sprite)
    end
end

--[[
    从对象池中获取一个激活精灵
    @return: 激活精灵实例
]]
function SuperSpriteProgress:GetActiveSpriteFromPool()
    if not self.activeSpriteTemplate then
        UILog:Error("GetActiveSpriteFromPool: activeSpriteTemplate is nil")
        return nil
    end
    local function InitSprite(sprite)
        sprite.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        sprite.Parent = self.activePanel
        sprite.Visible = true
        sprite.Position  = Vector2.New(0, 0)
        sprite.Scale = self.activeSpriteTemplate.Scale
        UIUtils:SetAlpha(sprite, UIUtils:GetAlpha(self.activeSpriteTemplate))
    end
    if #self.activeSpritePool > 0 then
        -- 从对象池中获取一个sprite
        local sprite = table.remove(self.activeSpritePool)
        if not sprite then
            -- 如果对象池中没有sprite，则创建一个新的sprite
            sprite = self.activeSpriteTemplate:Clone()
            InitSprite(sprite)
        else
            InitSprite(sprite)
        end
        return sprite
    end
    -- 如果对象池中没有sprite，则创建一个新的sprite
    local sprite = self.activeSpriteTemplate:Clone()
    InitSprite(sprite)
    return sprite
end

--[[
    回收激活精灵到对象池
    @param sprite: 要回收的激活精灵对象
]]
function SuperSpriteProgress:RecycleActiveSprite(sprite)
    if sprite then
        -- 清理父节点关系
        sprite.Parent = self.UIManager:GetNodePoolNode()
        table.insert(self.activeSpritePool, sprite)
    end
end

--设置显示进度
function SuperSpriteProgress:SetDisplayProgress(progress)
    if not self.bindObj then
        return
    end
    self:Refresh()
end


--重绘回调
function SuperSpriteProgress:OnRefresh()
    self:UpdateActiveSprites()
    self:UpdateInactiveSprites()
end

--更新未激活精灵
function SuperSpriteProgress:UpdateInactiveSprites()
    local count = self.maxValue

    local createdSprites = {}
    local recycledSprites = {}
    
    -- 回收多余的精灵
    while #self.inactiveSprites > count do
        local sprite = table.remove(self.inactiveSprites)
        table.insert(recycledSprites, sprite)
        self:RecycleInactiveSprite(sprite)
    end

    -- 创建不足的精灵
    while #self.inactiveSprites < count do
        local sprite = self:GetInactiveSpriteFromPool()
        if sprite then
            table.insert(createdSprites, sprite)
            table.insert(self.inactiveSprites, sprite)
        else
            break
        end
    end

    local layoutOrgin, layoutDirection = self:GetLayoutOrginAndDirection()

    self:AdjustLayoutInactiveSprites()

    for _, sprite in ipairs(recycledSprites) do
        self:OnInactiveSpriteRecycled(sprite)
    end

    for _, sprite in ipairs(createdSprites) do
        self:OnInactiveSpriteCreated(sprite)
    end
end

--更新激活精灵
function SuperSpriteProgress:UpdateActiveSprites()
    local displayValue = self.displayValue % self.maxValue
    local count = math.floor(displayValue + 0.5)

    if count == self.lastActiveSpriteCount then
        return
    end

    local createdSprites = {}
    local recycledSprites = {}

    -- 回收多余的精灵
    while #self.activeSprites > count do
        local sprite = table.remove(self.activeSprites)
        table.insert(recycledSprites, sprite)
    end

    -- 创建不足的精灵
    while #self.activeSprites < count do
        local sprite = self:GetActiveSpriteFromPool()
        if sprite then
            table.insert(createdSprites, sprite)
            table.insert(self.activeSprites, sprite)
        else
            break
        end
    end
    
    self:AdjustLayoutActiveSprites()

    for _, sprite in ipairs(recycledSprites) do
        self:OnActiveSpriteRecycled(sprite)
    end
    
    for _, sprite in ipairs(createdSprites) do
        self:OnActiveSpriteCreated(sprite)
    end

    self.lastActiveSpriteCount = count
end

function SuperSpriteProgress:AdjustLayoutActiveSprites()
    local layoutOrgin, layoutDirection = self:GetLayoutOrginAndDirection()

    UIUtils:AdjustLayoutChildren(self.activePanel, self.activeSprites, 
        layoutOrgin, layoutDirection, 
        self.reverse, self.padding, self.spacing, -1, nil)
end

function SuperSpriteProgress:AdjustLayoutInactiveSprites()
    local layoutOrgin, layoutDirection = self:GetLayoutOrginAndDirection()

    UIUtils:AdjustLayoutChildren(self.inactivePanel, self.inactiveSprites, 
        layoutOrgin, layoutDirection, 
        self.reverse, self.padding, self.spacing, -1, nil)
end

--获取布局起点和方向
function SuperSpriteProgress:GetLayoutOrginAndDirection()
    local layoutOrgin = "CenterMiddle"
    local layoutDirection = "Horizontal"

    if self.progressType == UIDefines.EProgressType.Horizontal then
        layoutDirection = "Horizontal"
        if self.reverse then    
            layoutOrgin = "RightMiddle"
        else
            layoutOrgin = "LeftMiddle"
        end
    elseif self.progressType == UIDefines.EProgressType.Vertical then
        layoutDirection = "Vertical"
        if self.reverse then
            layoutOrgin = "CenterBottom"
        else
            layoutOrgin = "CenterTop"
        end
    end

    return layoutOrgin, layoutDirection
end

--未激活精灵创建
function SuperSpriteProgress:OnInactiveSpriteCreated(sprite)

end

--未激活精灵回收
function SuperSpriteProgress:OnInactiveSpriteRecycled(sprite)

end

--激活精灵创建
function SuperSpriteProgress:OnActiveSpriteCreated(sprite)
    if self.activeSpriteScale then
        UITweenUtils:ScaleIn(sprite, self.activeSpriteScale, 0.5, "EaseOutBack")
    end
end

--激活精灵回收
function SuperSpriteProgress:OnActiveSpriteRecycled(sprite)
    if self.activeSpriteScale then
        UITweenUtils:ScaleOut(sprite, self.activeSpriteScale, 0.5, "EaseInBack", function()
            self:RecycleActiveSprite(sprite)
        end)
    else
        self:RecycleActiveSprite(sprite)
    end
end

--设置填充
function SuperSpriteProgress:SetPadding(padding)
    self.padding = padding
    self:AdjustLayoutActiveSprites()
    self:AdjustLayoutInactiveSprites()
end

--获取填充
function SuperSpriteProgress:GetPadding()
    return self.padding
end

--设置间距
function SuperSpriteProgress:SetSpacing(spacing)
    self.spacing = spacing
    self:AdjustLayoutActiveSprites()
    self:AdjustLayoutInactiveSprites()
end

--获取间距
function SuperSpriteProgress:GetSpacing()
    return self.spacing
end

function SuperSpriteProgress:SetReverse(reverse)
    self.reverse = reverse
    self:AdjustLayoutActiveSprites()
    self:AdjustLayoutInactiveSprites()
end

--获取是否反向
function SuperSpriteProgress:IsReverse()
    return self.reverse
end

--设置激活精灵缩放动画
function SuperSpriteProgress:EnableActiveSpriteScaleAnimation(scale)
    scale = scale or 0.2
    self.activeSpriteScale = scale
end

--禁用激活精灵缩放动画
function SuperSpriteProgress:DisableActiveSpriteScaleAnimation()
    self.activeSpriteScale = nil
end

return SuperSpriteProgress

