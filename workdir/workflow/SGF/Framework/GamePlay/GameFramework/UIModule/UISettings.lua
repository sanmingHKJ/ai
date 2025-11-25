-- 说明:UI设置
-- 日期:2025年2月17日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")

local UISettings = {}

function UISettings:SetRedDotSprite(sprite)
    self.redDotSprite = sprite
end

--获取红点精灵
function UISettings:GetRedDotSprite()
    return self.redDotSprite
end

--设置通用白色精灵
function UISettings:SetGenericWhiteSprite(sprite)
    self.genericWhiteSprite = sprite
end

--获取通用白色精灵
function UISettings:GetGenericWhiteSprite()
    return self.genericWhiteSprite
end



return UISettings