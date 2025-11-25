-- 说明:文本控件
-- 日期:2025年2月12日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIManager = GFScript("UIModule.UIManager")
local SuperText = UIClass.New("SuperText", UIWidget)

function SuperText:Constructor()
    self.text = nil
    self.displayText = nil
end 

function SuperText:Destructor()
    
end

--初始化
function SuperText:Init(bindObj)
    if not SuperText.super.Init(self, bindObj) then
        return false
    end
    
    return true
end

--设置文本
function SuperText:SetText(text)
    if not self.bindObj then
        UILog:Error("SetText: bindObj is nil")
        return
    end
    self.text = text
    if self.text and self.typewriterSpeed and self.typewriterSpeed > 0 then
        self.displayText = ""
        self.bindObj.Title = ""
        local duration = self:GetTextLength() / self.typewriterSpeed
        self:Tween({
            {"ValueTo", 1, duration, function(target, value)
                self.displayText = self.text:sub(1, math.floor(value * self:GetTextLength()))
                self.bindObj.Title = self.displayText
            end,
            function(target, value)
                return 0
            end}
        }):Tag("UpdateText"):Start()
    else
        self.displayText = text
        self.bindObj.Title = text
    end
end

--获取文本
function SuperText:GetText()
    if not self.bindObj then
        UILog:Error("GetText: bindObj is nil")
        return
    end
    return self.text
end

--获取字符数
function SuperText:GetTextLength()
    if not self.text then
        return 0
    end
    return string.len(self.text)
end

--设置文本颜色
function SuperText:SetTextColor(color)
    if not self.bindObj then
        UILog:Error("SetTextColor: bindObj is nil")
        return
    end
    self.bindObj.TitleColor = ColorQuad.New(color.r * 255, color.g * 255, color.b * 255, color.a * 255)
end

--获取文本颜色
function SuperText:GetTextColor()
    if not self.bindObj then
        UILog:Error("GetTextColor: bindObj is nil")
        return
    end
    local color = self.bindObj.TitleColor
    return Color.New(color.R / 255, color.G / 255, color.B / 255, color.A / 255)
end

--设置间距
function SuperText:SetSpacing(spacing)
    if not self.bindObj then
        UILog:Error("SetSpacing: bindObj is nil")
        return
    end
    self.bindObj.LetterSpacing = spacing
end

--获取间距
function SuperText:GetSpacing()
    if not self.bindObj then
        UILog:Error("GetSpacing: bindObj is nil")
        return
    end
    return self.bindObj.LetterSpacing
end

--设置富文本
function SuperText:SetRichText(richText)
    if not self.bindObj then
        UILog:Error("SetRichText: bindObj is nil")
        return
    end
    self.bindObj.RichText = richText
end

--获取富文本
function SuperText:IsRichText()
    if not self.bindObj then
        UILog:Error("IsRichText: bindObj is nil")
        return
    end
    return self.bindObj.RichText
end
--启用打字机效果
function SuperText:EnableTypewriterAnimation(speed)
    if not self.bindObj then
        UILog:Error("EnableTypewriterAnimation: bindObj is nil")
        return
    end
    self.typewriterSpeed = speed
end

--禁用打字机效果
function SuperText:DisableTypewriterAnimation()
    self.typewriterSpeed = nil
end

--获取打字机速度
function SuperText:GetTypewriterSpeed()
    return self.typewriterSpeed
end

return SuperText

