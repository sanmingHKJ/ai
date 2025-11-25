-- 说明:按钮控件基类
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local UIDefines = GFScript("UIModule.UIDefines")
local Color = GFScript("UIModule.UIMath.Color")
local UIUtils = GFScript("UIModule.UIUtils")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local UIResource = GFScript("UIModule.UIResource")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local SuperButtonBase = UIClass.New("SuperButtonBase", UIWidget)


function SuperButtonBase:Constructor()
    self.buttonState = UIDefines.EButtonState.Normal

    self.buttonStateChangedCallback = nil

    --每个状态的颜色
    self.buttonStateColors = {
        [UIDefines.EButtonState.Normal] = Color.white(),
        [UIDefines.EButtonState.Pressed] = Color.gray(),
        [UIDefines.EButtonState.Selected] = Color.yellow(),
        [UIDefines.EButtonState.Disabled] = Color.gray(),
    }

    self.buttonStateSprites = {
        [UIDefines.EButtonState.Normal] = nil,
        [UIDefines.EButtonState.Pressed] = nil,
        [UIDefines.EButtonState.Selected] = nil,
        [UIDefines.EButtonState.Disabled] = nil,
    }

    self.buttonStateColorEnabled = false
    self.buttonStateSpriteEnabled = false

    self.spriteSize = Vec2.New(0, 0)

    self.spriteScaleMode = UIDefines.ESpriteScaleMode.None
end 

function SuperButtonBase:Destructor()
    if self.fadeImageObj then
        self.fadeImageObj:Destroy()
        self.fadeImageObj = nil
    end
end

--初始化
function SuperButtonBase:Init(bindObj, managedBindObj)
    if not SuperButtonBase.super.Init(self, bindObj, managedBindObj) then
        return false
    end
    self.sprite = self.bindObj.Icon
    self.spritePath = UIUtils:RelativeSpritePath(self.sprite)
    return true
end

--设置按钮状态
function SuperButtonBase:SetButtonState(state)
    local oldState = self.buttonState
    self.buttonState = state
    self:OnButtonStateChanged(oldState, state)
end

--获取按钮状态
function SuperButtonBase:GetButtonState()
    return self.buttonState
end

--设置按钮状态颜色
function SuperButtonBase:SetButtonStateColor(state, color)
    self.buttonStateColors[state] = color
end

--获取按钮状态颜色
function SuperButtonBase:GetButtonStateColor(state)
    return self.buttonStateColors[state]
end

--设置按钮状态图片
function SuperButtonBase:SetButtonStateSprite(state, sprite)
    self.buttonStateSprites[state] = sprite
end

--获取按钮状态图片
function SuperButtonBase:GetButtonStateSprite(state)    
    return self.buttonStateSprites[state]
end

--是否正常状态
function SuperButtonBase:IsNormalState()
    return self.buttonState == UIDefines.EButtonState.Normal
end

--是否按下状态
function SuperButtonBase:IsPressedState()
    return self.buttonState == UIDefines.EButtonState.Pressed
end

--是否选中状态
function SuperButtonBase:IsSelectedState()
    return self.buttonState == UIDefines.EButtonState.Selected
end

--是否禁用状态
function SuperButtonBase:IsDisabledState()
    return self.buttonState == UIDefines.EButtonState.Disabled
end

--设置选中状态
function SuperButtonBase:SetSelectedState(selected)
    self:SetButtonState(selected and UIDefines.EButtonState.Selected or UIDefines.EButtonState.Normal)
end

--设置禁用状态
function SuperButtonBase:SetDisabledState(disabled)
    self:SetButtonState(disabled and UIDefines.EButtonState.Disabled or UIDefines.EButtonState.Normal)
end

--设置是否启用状态颜色
function SuperButtonBase:SetButtonStateColorEnabled(enabled)
    self.buttonStateColorEnabled = enabled
end

--设置是否启用状态图片
function SuperButtonBase:SetButtonStateSpriteEnabled(enabled)
    self.buttonStateSpriteEnabled = enabled
end

--按钮状态改变
function SuperButtonBase:OnButtonStateChanged(oldState, newState)
    self:UpdateButtonState(oldState, newState)
    if self.buttonStateChangedCallback then
        self.buttonStateChangedCallback(self, oldState, newState)
    end
end

--更新按钮状态
function SuperButtonBase:UpdateButtonState(oldState, newState)
    if self.buttonStateColorEnabled then
        if self.stateChangedColorAnimationDuration then
            self:ColorTo(self.buttonStateColors[newState], self.stateChangedColorAnimationDuration):Tag("UpdateButtonState"):OnComplete(function()
                
            end):Start()
        else
            self:SetColor(self.buttonStateColors[newState])
        end
    end

    if self.buttonStateSpriteEnabled then
        if self.buttonStateSprites[newState] then
            self:SetSprite(self.buttonStateSprites[newState])
        end
    end
end

--触摸开始
function SuperButtonBase:OnTouchBegin(touchPos, touchId)
    if not SuperButtonBase.super.OnTouchBegin(self, touchPos, touchId) then
        return false
    end
    if self.buttonState == UIDefines.EButtonState.Disabled then
        return false
    end
    self:SetButtonState(UIDefines.EButtonState.Pressed)
    return true
end

--触摸结束
function SuperButtonBase:OnTouchEnd(touchPos, touchId)
    if not SuperButtonBase.super.OnTouchEnd(self, touchPos, touchId) then
        return
    end
    if self.buttonState == UIDefines.EButtonState.Disabled then
        return false
    end
    self:SetButtonState(UIDefines.EButtonState.Normal)

    return true
end


--设置图片
function SuperButtonBase:SetSprite(sprite, finishedCallback)
    if not self.bindObj then
        UILog:Error("SetSprite: bindObj is nil")
        return
    end
    self.sprite = sprite
    sprite = UIUtils:FullSpritePath(sprite)
    UIResource:AsyncGetImageSize(self.bindObj, function(success, control, width, height)
        if success then
            self:OnSpriteSizeChanged(Vec2.New(width, height))
        end
        if finishedCallback then
            finishedCallback()
        end
    end, 3, self)
    if self.fadeAnimationDuration then
        if self.fadeImageObj then
            self.fadeImageObj:Destroy()
            self.fadeImageObj = nil
        end
        self.fadeImageObj = self.bindObj:Clone()
        self.fadeImageObj.Parent = self.bindObj.Parent  

        self.fadeImageObj.Icon = self.bindObj.Icon
        self.bindObj.Icon = sprite
        UIUtils:SetAlpha(self.fadeImageObj, 1)
        UIUtils:SetAlpha(self.bindObj, 0)
        UITweenUtils:FadeOut(self.fadeImageObj, self.fadeAnimationDuration, "Linear")
        UITweenUtils:FadeIn(self.bindObj, self.fadeAnimationDuration, "Linear", function()
            self.fadeImageObj:Destroy()
            self.fadeImageObj = nil
        end)
    else
        self.bindObj.Icon = sprite
    end
end

--获取图片
function SuperButtonBase:GetSprite()
    if not self.bindObj then
        UILog:Error("GetSprite: bindObj is nil")
        return
    end
    return self.sprite
end

--设置缩放模式
function SuperButtonBase:SetSpriteScaleMode(mode)
    self.spriteScaleMode = mode
end

--获取缩放模式
function SuperButtonBase:GetSpriteScaleMode()
    return self.spriteScaleMode
end

--精灵大小改变
function SuperButtonBase:OnSpriteSizeChanged(size)
    self.spriteSize = size
    if self.spriteScaleMode == UIDefines.ESpriteScaleMode.None then
        return
    end
    local parent = self:GetParent()
    if not parent then
        UILog:Error("OnSpriteSizeChanged: parent is nil")
        return
    end

    local parentSize = UIUtils:GetSize(parent)

    local finalWidth, finalHeight, scaleX, scaleY = UIUtils:CalculateImageFitSize(parentSize.x, parentSize.y, self.spriteSize.x, self.spriteSize.y, self.spriteScaleMode)
    self:SetSize(Vec2.New(finalWidth, finalHeight))
    self:Middle()
end

--设置是否启用精灵动画
function SuperButtonBase:EnableFadeAnimation(duration)
    if not self.bindObj then
        UILog:Error("EnableFadeAnimation: bindObj is nil")
        return
    end
    self.fadeAnimationDuration = duration
end
--------------------------------------------------UI事件管理--------------------------------------------------

--设置按钮状态改变回调
function SuperButtonBase:ButtonStateChangedCallback(callback)
    self.buttonStateChangedCallback = callback
end


-----------------------------------交互效果-----------------------------------

--启用状态改变颜色动画
function SuperButtonBase:EnableStateChangedColorAnimation(duration)
    self.stateChangedColorAnimationDuration = duration
end

--禁用状态改变颜色动画
function SuperButtonBase:DisableStateChangedColorAnimation()
    self.stateChangedColorAnimationDuration = nil
end


return SuperButtonBase

