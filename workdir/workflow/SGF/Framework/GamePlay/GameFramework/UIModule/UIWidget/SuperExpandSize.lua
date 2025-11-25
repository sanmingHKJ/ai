-- 说明:撑开大小控件
-- 日期:2025年6月11日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperExpandSize = UIClass.New("SuperExpandSize", UIWidget)

function SuperExpandSize:Constructor()
    self.preWidth = 0
    self.preHeight = 0
    self.expandTargets = {} --撑开目标
    self.expandWidth = true --是否展开宽度
    self.expandHeight = true --是否展开

    --最小参考目标
    self.minReferenceTarget = nil
end

function SuperExpandSize:Destructor()
    self:ClearExpandTargets()
end

--初始化
function SuperExpandSize:Init(bindObj)
    if not SuperExpandSize.super.Init(self, bindObj) then
        return false
    end
    
    self:EnableUpdate()

    return true
end

--更新
function SuperExpandSize:Update(deltaTime)
    local width = self.bindObj.Size.X
    local height = self.bindObj.Size.Y
    if width ~= self.preWidth or height ~= self.preHeight then
        self.preWidth = width
        self.preHeight = height
        self:ExpandTargets()
    end
end

--展开目标
function SuperExpandSize:ExpandTargets(widthOffset, heightOffset)
    if #self.expandTargets > 0 then
        for _, expand in pairs(self.expandTargets) do
            self:ExpandTarget(expand.expandTarget, expand.sizeOffset.x, expand.sizeOffset.y)
        end
    end
    if self.expandFinishedCallback then
        self.expandFinishedCallback(self)
    end
end

--展开目标
function SuperExpandSize:ExpandTarget(expandTarget, widthOffset, heightOffset)
    if not expandTarget then
        return
    end
    local width = self.bindObj.Size.X
    local height = self.bindObj.Size.Y

    if self.minReferenceTarget then
        local minReferenceTargetSize = self.minReferenceTarget.Size
        if width < minReferenceTargetSize.X then
            width = minReferenceTargetSize.X
        end
        if height < minReferenceTargetSize.Y then
            height = minReferenceTargetSize.Y
        end
    end

    local targetSize = expandTarget.Size
    if self.expandWidth then
        targetSize.X = width + widthOffset
    end
    if self.expandHeight then
        targetSize.Y = height + heightOffset
    end
    expandTarget.Size = targetSize
    if self.expandedCallback then
        self.expandedCallback(self, expandTarget, targetSize.X, targetSize.Y)
    end
end

--设置撑开目标
function SuperExpandSize:AddExpandTarget(expandTarget)
    local sizeOffset = UIUtils:GetScreenSize(expandTarget) - UIUtils:GetScreenSize(self.bindObj)
    table.insert(self.expandTargets, {expandTarget = expandTarget, sizeOffset = sizeOffset})
end

--移除撑开目标
function SuperExpandSize:RemoveExpandTarget(expandTarget)
    for i, expandTarget in pairs(self.expandTargets) do
        if expandTarget.expandTarget == expandTarget then
            table.remove(self.expandTargets, i)
            break
        end
    end
end

--设置撑开目标
function SuperExpandSize:SetExpandTarget(expandTarget)
    self:ClearExpandTargets()
    self:AddExpandTarget(expandTarget)
end

--清空撑开目标
function SuperExpandSize:ClearExpandTargets()
    self.expandTargets = {}
end

--添加撑开目标至某个父节点为止
function SuperExpandSize:AddExpandTargetToParent(toParent)
    self:AddExpandTargetFromChildToParent(self.bindObj, toParent)
end

--添加撑开目标至某个父节点为止
function SuperExpandSize:AddExpandTargetFromChildToParent(fromChild, toParent)
    local parent = fromChild.Parent
    while parent do
        self:AddExpandTarget(parent)
        if parent == toParent then
            break
        end
        parent = parent.Parent
    end
end

--设置展开回调
function SuperExpandSize:ExpandedCallback(callback)
    self.expandedCallback = callback
end

--设置展开完成回调
function SuperExpandSize:ExpandFinishedCallback(callback)
    self.expandFinishedCallback = callback
end

--设置是否展开宽度
function SuperExpandSize:SetExpandWidth(expandWidth)
    self.expandWidth = expandWidth
end

--设置是否展开高度
function SuperExpandSize:SetExpandHeight(expandHeight)
    self.expandHeight = expandHeight
end

function SuperExpandSize:SetExpand(expandWidth, expandHeight)
    self.expandWidth = expandWidth
    self.expandHeight = expandHeight
end

--设置最小参考目标
function SuperExpandSize:SetMinReferenceTarget(minReferenceTarget)
    self.minReferenceTarget = minReferenceTarget
end

return SuperExpandSize