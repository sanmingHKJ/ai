-- 说明:UI焦点遮罩
-- 日期:2025年2月19日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Rect = GFScript("UIModule.UIMath.Rect")
local UIDefines = GFScript("UIModule.UIDefines")
local UIView = GFScript("UIModule.UIView")
local UIUtils = GFScript("UIModule.UIUtils")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local UISettings = GFScript("UIModule.UISettings")
local UIFocusMask = UIClass.New("UIFocusMask", UIView)

UIFocusMask.Style = UIDefines.EViewStyle.Normal
UIFocusMask.Layer = UIDefines.EViewLayer.Top

function UIFocusMask:Constructor()
    self.alpha = 0.5
    self.focusRect = Rect.New(0, 0, 0, 0)
end

function UIFocusMask:InitControls()
    local createMask = function(name)
        local mask = SandboxNode.New("UIImage")
        mask.Name = name
        mask.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        mask.Icon = UIUtils:FullSpritePath(UISettings:GetGenericWhiteSprite())
        mask.ClickPass = false
        mask.IsNotifyEventStop = true
        mask.Pivot = Vector2.New(0, 0)
        mask.Parent = self.rootNode
        UIUtils:SetColor(mask, Color.New(0, 0, 0))
        UIUtils:SetAlpha(mask, self.alpha)
        return mask
    end
    self.topMask = createMask("topMask")
    self.bottomMask = createMask("bottomMask")
    self.leftMask = createMask("leftMask")
    self.rightMask = createMask("rightMask")
end

--聚焦
--control: 聚焦的控件
--expand: 扩展
function UIFocusMask:Focus(control, expand)
    if control.bindObj then
        control = control.bindObj
    end
    expand = expand or {x = 0, y = 0, z = 0, w = 0}
    local rect = UIUtils:GetScreenRect(control)
    rect:Expand(expand.x, expand.y, expand.z, expand.w)
    self:SetFocusRect(rect)
    
end

--取消聚焦
function UIFocusMask:Unfocus()

    self.topMask.Visible = false
    self.bottomMask.Visible = false
    self.leftMask.Visible = false
    self.rightMask.Visible = false
end

--设置焦点
--rect: 焦点矩形
function UIFocusMask:SetFocusRect(rect)
    self.focusRect = rect
    self:UpdateFocusRect()
end

--更新焦点矩形
function UIFocusMask:UpdateFocusRect()
    self.topMask.Visible = true
    self.bottomMask.Visible = true
    self.leftMask.Visible = true
    self.rightMask.Visible = true

    local rect = self.focusRect
    
    local viewportSize = UIUtils:GetViewportSize()
    
    self.topMask.Position = Vector2.New(0, 0)
    self.topMask.Size = Vector2.New(viewportSize.x, rect:GetTop())
    
    local bottom = rect:GetBottom()
    self.bottomMask.Position = Vector2.New(0, bottom)
    self.bottomMask.Size = Vector2.New(viewportSize.x, viewportSize.y - bottom)
    
    self.leftMask.Position = Vector2.New(0, rect:GetTop())
    self.leftMask.Size = Vector2.New(rect:GetLeft(), rect:GetHeight())
    
    local right = rect:GetRight()
    self.rightMask.Position = Vector2.New(right, rect:GetTop())
    self.rightMask.Size = Vector2.New(viewportSize.x - right, rect:GetHeight())

end

--设置颜色
--color: 颜色
function UIFocusMask:SetColor(color)
    UIUtils:SetColor(self.topMask, color)
    UIUtils:SetColor(self.bottomMask, color)
    UIUtils:SetColor(self.leftMask, color)
    UIUtils:SetColor(self.rightMask, color)
end

--设置透明度
--alpha: 透明度
function UIFocusMask:SetAlpha(alpha)
    self.alpha = alpha
    UIUtils:SetAlpha(self.topMask, alpha)
    UIUtils:SetAlpha(self.bottomMask, alpha)   
    UIUtils:SetAlpha(self.leftMask, alpha)
    UIUtils:SetAlpha(self.rightMask, alpha)
end

return UIFocusMask