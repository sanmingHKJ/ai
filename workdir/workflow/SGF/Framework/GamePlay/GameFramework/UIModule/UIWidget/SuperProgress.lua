-- 说明:进度条控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIDefines = GFScript("UIModule.UIDefines")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperProgressBase = GFScript("UIModule.UIWidget.SuperProgressBase")   
local UIManager = GFScript("UIModule.UIManager")
local SuperProgress = UIClass.New("SuperProgress", SuperProgressBase)

function SuperProgress:Constructor()
    self.progressType = UIDefines.EProgressType.Horizontal
    self.reverse = false
    self.clockwise = true

    self.thumb = nil
end 

function SuperProgress:Destructor()
    if self.thumb then
        self.thumb:Destroy()
        self.thumb = nil
    end
end

--初始化
function SuperProgress:Init(bindObj)
    if not SuperProgress.super.Init(self, bindObj) then
        return false
    end

    self:UpdateProgressCtrl()

    return true
end

--设置进度条形式
function SuperProgress:SetProgressType(progressType)
    self.progressType = progressType
    self:UpdateProgressCtrl()
end

--获取进度条形式
function SuperProgress:GetProgressType()
    return self.progressType
end

--设置是否反向
function SuperProgress:SetReverse(reverse)
    self.reverse = reverse
    self:UpdateProgressCtrl()
end

--获取是否反向
function SuperProgress:GetReverse()
    return self.reverse
end

--设置正时针
function SuperProgress:SetClockwise(clockwise)
    self.clockwise = clockwise
    self:UpdateProgressCtrl()
end

--获取正时针
function SuperProgress:GetClockwise()
    return self.clockwise
end

--更新进度条控件
function SuperProgress:UpdateProgressCtrl()
    if not self.bindObj then
        return
    end

    if self.progressType == UIDefines.EProgressType.Horizontal then
        self.bindObj.FillMethod = Enum.FillMethod.Horizontal
    elseif self.progressType == UIDefines.EProgressType.Vertical then
        self.bindObj.FillMethod = Enum.FillMethod.Vertical
    elseif self.progressType == UIDefines.EProgressType.Circle then
        self.bindObj.FillMethod = Enum.FillMethod.Radial360
    end

    if self.reverse then
        self.bindObj.FillOrigin = Enum.FillOrigin.Bottom
    else
        self.bindObj.FillOrigin = Enum.FillOrigin.Top
    end

    if self.clockwise then
        self.bindObj.FillClockwise = true
    else
        self.bindObj.FillClockwise = false
    end
end

--设置显示进度
function SuperProgress:SetDisplayProgress(progress)
    if not self.bindObj then
        return
    end
    self.bindObj.FillAmount = progress
    self:UpdateThumb()
end

--设置进度条的thumb
function SuperProgress:SetThumb(thumbName)
    self.thumb = self:FindImage(thumbName)
    if self.thumb then
        self.thumb:SetPivot(Vec2.New(0.5, 0.5))
    end
end

--更新thumb位置
function SuperProgress:UpdateThumb()
    if self.thumb then
        self.thumb:SetScreenPosition(self:GetProgressPointerPosition())
        if self:IsDisplayValueAtStart() or self:IsDisplayValueAtEnd() then
            self.thumb:SetVisible(false)
        else
            self.thumb:SetVisible(true)
        end
    end
end

--获取进度条的位置
function SuperProgress:GetProgressPointerPosition()
    if self.progressType == UIDefines.EProgressType.Circle then
        return Vec2.New(0, 0)
    else
        local screenRect = self:GetScreenRect()
        local progress = self:GetDisplayProgress()
        local center = screenRect:GetCenter()
        local x = center.x
        local y = center.y
        if self.progressType == UIDefines.EProgressType.Horizontal then
            if self.reverse then
                x = screenRect:GetRight() - progress * screenRect:GetWidth()
            else
                x = screenRect:GetLeft() + progress * screenRect:GetWidth()
            end
        elseif self.progressType == UIDefines.EProgressType.Vertical then
            if self.reverse then
                y = screenRect:GetTop() + progress * screenRect:GetHeight()
            else
                y = screenRect:GetBottom() - progress * screenRect:GetHeight()
            end
        end
        return Vec2.New(x, y)
    end
end

return SuperProgress

