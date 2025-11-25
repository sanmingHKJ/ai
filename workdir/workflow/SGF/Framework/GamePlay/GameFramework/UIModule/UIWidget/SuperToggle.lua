-- 说明:开关控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Color = GFScript("UIModule.UIMath.Color")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperButtonBase = GFScript("UIModule.UIWidget.SuperButtonBase")   
local UIDefines = GFScript("UIModule.UIDefines")
local UIUtils = GFScript("UIModule.UIUtils")
local SuperToggle = UIClass.New("SuperToggle", SuperButtonBase)

local selectedCallback = {}

--设置组选择回调
function SuperToggle.GroupSelectedCallback(group, callback)
    selectedCallback[group] = callback
end

--设置组选择
function SuperToggle.SetGroupSelected(group, value)
    local UIManager = GFScript("UIModule.UIManager")
    UIManager:ForEachGroup(group, function(widget)
        if widget.SetSelectedState and widget.GetValue then
            if widget:GetValue() == value then
                widget:SetToggle(true)
            end
        end
    end)
end

--获取组选择值
function SuperToggle:GetGroupSelected(group)
    local UIManager = GFScript("UIModule.UIManager")
    local value = nil
    UIManager:ForEachGroup(group, function(widget)
        if widget.SetSelectedState and widget.GetValue then
            if widget:IsSelectedState() then
                value = widget:GetValue()
            end
        end
    end)
    return value
end

function SuperToggle:Constructor()
    self.value = nil
    --是否单选
    self.isRadio = false

    self.activeNode = nil
    self.inactiveNode = nil
end 

function SuperToggle:Destructor()
    
end

--设置激活节点
function SuperToggle:SetActiveNode(nodeName)
    self.activeNode = self:FindControl(nodeName)
end

--设置非激活节点
function SuperToggle:SetInactiveNode(nodeName)
    self.inactiveNode = self:FindControl(nodeName)
end

--设置值
function SuperToggle:SetValue(value)
    self.value = value
end

--获取值
function SuperToggle:GetValue()
    return self.value
end

--设置是否单选
function SuperToggle:SetRadio(isRadio)
    self.isRadio = isRadio
end

--获取是否单选
function SuperToggle:GetRadio()
    return self.isRadio
end

--初始化
function SuperToggle:Init(bindObj)
    if not SuperToggle.super.Init(self, bindObj) then
        return false
    end
    self:SetActiveNode("active")
    self:SetInactiveNode("inactive")
    self:SetToggle(false)
    return true
end

--点击
function SuperToggle:OnClicked(touchPos)
    SuperToggle.super.OnClicked(self, touchPos)
    if self.isRadio and self.group and self:IsSelectedState() then
        return
    end
    self:Toggle()
end

--设置开关状态
function SuperToggle:SetToggle(toggle)
    self:SetSelectedState(toggle)

    if self.isRadio and self.group then
        self.UIManager:ForEachGroup(self.group, function(widget)
            if widget ~= self and widget.SetSelectedState then
                widget:SetSelectedState(false)
            end
        end)
    end
    if self.group and selectedCallback[self.group] then
        selectedCallback[self.group](self)
    end
end

--获取开关状态
function SuperToggle:IsToggle()
    return self:IsSelectedState()
end

--切换开关状态
function SuperToggle:Toggle()
    self:SetToggle(not self:IsToggle())
end

function SuperToggle:SetGroup(group)
    SuperToggle.super.SetGroup(self, group)
    if self.isRadio and self.group then
        self.UIManager:ForEachGroup(self.group, function(widget)
            if widget ~= self and widget.IsSelectedState then
                if widget:IsSelectedState() then
                    self:SetToggle(false)
                end
            end
        end)
    end
end

--按钮状态改变
function SuperToggle:OnButtonStateChanged(oldState, newState)
    SuperToggle.super.OnButtonStateChanged(self, oldState, newState)
    if newState == UIDefines.EButtonState.Selected then
        if self.openDegree and self.closeDegree then
            self:PlayRotateAnimation(function()
                if self.toggleCallback then
                    self.toggleCallback(self, toggle)
                end
            end)
        else
            if self.toggleCallback then
                self.toggleCallback(self, toggle)
            end
        end
    end

    if self.activeNode then
        UIUtils:SetVisible(self.activeNode, newState == UIDefines.EButtonState.Selected)
    end
    if self.inactiveNode then
        UIUtils:SetVisible(self.inactiveNode, newState ~= UIDefines.EButtonState.Selected)
    end
end

--启用旋转动画
function SuperToggle:EnableRotateAnimation(openDegree, closeDegree)
    self.openDegree = openDegree
    self.closeDegree = closeDegree

    self:PlayRotateAnimation()
end

--禁用旋转动画
function SuperToggle:DisableRotateAnimation()
    self.openDegree = nil
    self.closeDegree = nil
end

--播放旋转动画
function SuperToggle:PlayRotateAnimation(finishCallback)
    if self:IsSelectedState() then
        if self.openDegree then
            self:RotateTo(self.openDegree, 0.25):Ease("EaseInOutBack"):OnComplete(finishCallback):Start()
        end
    else
        if self.closeDegree then
            self:RotateTo(self.closeDegree, 0.25):Ease("EaseInOutBack"):OnComplete(finishCallback):Start()
        end
    end
end

--设置开关状态改变回调
function SuperToggle:ToggleCallback(callback)
    self.toggleCallback = callback
end

return SuperToggle

