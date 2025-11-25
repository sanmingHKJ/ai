-- 说明:切换控件
-- 日期:2025年2月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperSwitcher = UIClass.New("SuperSwitcher", UIWidget)

function SuperSwitcher:Constructor()
    self.activeIndex = 1
    self.keepSize = true
    self.keepPosition = true
    self.activeChild = nil

    --是否循环
    self.loop = false
end

function SuperSwitcher:Destructor()
    
end

--初始化
function SuperSwitcher:Init(bindObj)
    if not SuperSwitcher.super.Init(self, bindObj) then
        return false
    end
    self:SetActiveIndex(1)
    return true
end

--设置激活的子控件索引
function SuperSwitcher:SetActiveIndex(index)
    if index < 1 then
        index = 1
    end
    if index > #self.bindObj.Children then
        index = #self.bindObj.Children
    end
    local oldIndex = self.activeIndex
    self.activeIndex = index
    self:UpdateActiveChild()
    if self.indexChangedCallback then
        self.indexChangedCallback(oldIndex, index)
    end
end

--获取激活的子控件索引
function SuperSwitcher:GetActiveIndex()
    return self.activeIndex
end

--设置切换时是否保持子控件大小
function SuperSwitcher:SetKeepSize(keepSize)
    self.keepSize = keepSize
    self:UpdateActiveChildSize()
end

--设置切换时是否保持子控件位置
function SuperSwitcher:SetKeepPosition(keepPosition)
    self.keepPosition = keepPosition
    self:UpdateActiveChildSize()
end

--获取切换时是否保持子控件大小
function SuperSwitcher:GetKeepSize()
    return self.keepSize
end

--获取切换时是否保持子控件位置
function SuperSwitcher:GetKeepPosition()
    return self.keepPosition
end

--更新激活的子控件
function SuperSwitcher:UpdateActiveChild()
    if not self.bindObj then
        return
    end
    for i, child in ipairs(self.bindObj.Children) do
        if i == self.activeIndex then
            self.activeChild = child
            UIUtils:SetVisible(child, true)
            self:UpdateActiveChildSize()
        else
            UIUtils:SetVisible(child, false)
        end
    end
end

--更新激活的子控件大小
function SuperSwitcher:UpdateActiveChildSize()
    if not self.activeChild then
        return
    end
    if not self.keepSize then
        UIUtils:SetScreenSize(self.activeChild, UIUtils:GetScreenSize(self.bindObj))
    end
    if not self.keepPosition then
        UIUtils:SetScreenPosition(self.activeChild, UIUtils:GetScreenPosition(self.bindObj))
    end
end

--切换到下一个子控件
function SuperSwitcher:GoNext()
    if not self.bindObj then
        return false
    end
    if self.loop then
        if self.activeIndex == #self.bindObj.Children then
            self:SetActiveIndex(1)
        else
            self:SetActiveIndex(self.activeIndex + 1)
        end
    else
        if self.activeIndex < #self.bindObj.Children then
            self:SetActiveIndex(self.activeIndex + 1)
        else
            return false
        end
    end
    return true
end

--切换到上一个子控件
function SuperSwitcher:GoPrevious()
    if not self.bindObj then
        return false
    end
    if self.loop then
        if self.activeIndex == 1 then
            self:SetActiveIndex(#self.bindObj.Children)
        else
            self:SetActiveIndex(self.activeIndex - 1)
        end
    else
        if self.activeIndex > 1 then
            self:SetActiveIndex(self.activeIndex - 1)
        else
            return false
        end
    end
    return true
end

--切换到指定索引的子控件
function SuperSwitcher:GoTo(index)
    if not self.bindObj then
        return false
    end
    if index < 1 then
        return false
    end
    if index > #self.bindObj.Children then
        return false
    end
    self:SetActiveIndex(index)
    return true
end

--设置是否循环
function SuperSwitcher:SetLoop(loop)
    self.loop = loop
end

--获取是否循环
function SuperSwitcher:IsLoop()
    return self.loop
end

--获取激活的子控件
function SuperSwitcher:GetActiveChild()
    return self.activeChild
end

--设置索引改变回调
function SuperSwitcher:IndexChangedCallback(callback)
    self.indexChangedCallback = callback
end

return SuperSwitcher
