-- 说明:输入框控件
-- 日期:2025年5月13日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local SuperInput = UIClass.New("SuperInput", UIWidget)

function SuperInput:Constructor()
end 

function SuperInput:Destructor()
    
end

--初始化
function SuperInput:Init(bindObj)
    if not SuperInput.super.Init(self, bindObj) then
        return false
    end

    
    return true
end

--设置文本
function SuperInput:SetText(text)
    if not self.bindObj then
        UILog:Error("SetText: bindObj is nil")
        return
    end
    self.bindObj.Title = text
end

--获取文本
function SuperInput:GetText()
    if not self.bindObj then
        UILog:Error("GetText: bindObj is nil")
        return
    end
    return self.bindObj.Title
end

--获取字符数
function SuperInput:GetTextLength()
    local text = self:GetText()
    if not text then
        return 0
    end
    return string.len(text)
end

--设置文本颜色
function SuperInput:SetTextColor(color)
    if not self.bindObj then
        UILog:Error("SetTextColor: bindObj is nil")
        return
    end
    self.bindObj.TitleColor = ColorQuad.New(color.r * 255, color.g * 255, color.b * 255, color.a * 255)
end

--获取文本颜色
function SuperInput:GetTextColor()
    if not self.bindObj then
        UILog:Error("GetTextColor: bindObj is nil")
        return
    end
    local color = self.bindObj.TitleColor
    return Color.New(color.R / 255, color.G / 255, color.B / 255, color.A / 255)
end

--设置最大字符数
function SuperInput:SetMaxLength(maxLength)
    self.bindObj.MaxLength = maxLength
end

--获取最大字符数
function SuperInput:GetMaxLength()
    return self.bindObj.MaxLength
end

return SuperInput

