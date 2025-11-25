-- 说明:倒计时文本控件
-- 日期:2025年4月16日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperText = GFScript("UIModule.UIWidget.SuperText")
local UIManager = GFScript("UIModule.UIManager")
local Color = GFScript("UIModule.UIMath.Color")
local SuperCooldown = UIClass.New("SuperCooldown", SuperText)

-- 格式化类型
SuperCooldown.FORMAT_TYPE = {
    DAY_HOUR_MIN_SEC = 1,    -- 天时分秒
    HOUR_MIN_SEC = 2,        -- 时分秒
    MIN_SEC = 3,             -- 分秒
    SEC = 4                  -- 秒
}

function SuperCooldown:Constructor()
    self.remainingTime = 0
    self.totalTime = 0
    self.isRunning = false
    self.isPaused = false
    self.formatType = SuperCooldown.FORMAT_TYPE.DAY_HOUR_MIN_SEC
    self.formatString = "%d天%02d:%02d:%02d"
    self.removeInvalidInfo = true  -- 是否移除无效的时间信息
    self.warningThreshold = 10      -- 警告阈值（秒）
    self.normalColor = Color.New(1, 1, 1, 1) -- 正常颜色
    self.warningColor = Color.New(1, 0, 0, 1)  -- 警告颜色
end

function SuperCooldown:Init(bindObj)
    if not SuperCooldown.super.Init(self, bindObj) then
        return false
    end
    self:EnableUpdate()
    return true
end

-- 设置总时间（秒）
function SuperCooldown:SetTotalTime(seconds)
    self.totalTime = seconds
    self.remainingTime = seconds
    self:UpdateText()
end

-- 设置格式化类型
function SuperCooldown:SetFormatType(formatType)
    self.formatType = formatType
    if formatType == SuperCooldown.FORMAT_TYPE.DAY_HOUR_MIN_SEC then
        self.formatString = "%d天%02d:%02d:%02d"
    elseif formatType == SuperCooldown.FORMAT_TYPE.HOUR_MIN_SEC then
        self.formatString = "%02d:%02d:%02d"
    elseif formatType == SuperCooldown.FORMAT_TYPE.MIN_SEC then
        self.formatString = "%02d:%02d"
    elseif formatType == SuperCooldown.FORMAT_TYPE.SEC then
        self.formatString = "%d"
    end
    self:UpdateText()
end

-- 开始倒计时
function SuperCooldown:Start()
    if self.totalTime <= 0 then
        UILog:Error("SuperCooldown:Start - Total time must be greater than 0")
        return
    end
    self.isRunning = true
    self.isPaused = false
    self.remainingTime = self.totalTime
    self:UpdateText()
end

-- 停止倒计时
function SuperCooldown:Stop()
    self.isRunning = false
    self.isPaused = false
    self.remainingTime = self.totalTime
    self:UpdateText()
end

-- 暂停倒计时
function SuperCooldown:Pause()
    if self.isRunning then
        self.isPaused = true
    end
end

-- 恢复倒计时
function SuperCooldown:Resume()
    if self.isRunning and self.isPaused then
        self.isPaused = false
    end
end

-- 设置是否移除无效的时间信息
function SuperCooldown:SetRemoveInvalidInfo(remove)
    self.removeInvalidInfo = remove
    self:UpdateText()
end

-- 设置警告阈值（秒）
function SuperCooldown:SetWarningThreshold(seconds)
    self.warningThreshold = seconds
    self:UpdateText()
end

-- 设置正常颜色
function SuperCooldown:SetNormalColor(color)
    self.normalColor = color
    self:UpdateText()
end

-- 设置警告颜色
function SuperCooldown:SetWarningColor(color)
    self.warningColor = color
    self:UpdateText()
end

-- 更新文本显示
function SuperCooldown:UpdateText()
    local days = math.floor(self.remainingTime / 86400)
    local hours = math.floor((self.remainingTime % 86400) / 3600)
    local minutes = math.floor((self.remainingTime % 3600) / 60)
    local seconds = math.floor(self.remainingTime % 60)

    local text = ""
    if self.formatType == SuperCooldown.FORMAT_TYPE.DAY_HOUR_MIN_SEC then
        if self.removeInvalidInfo and days == 0 then
            text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        else
            text = string.format(self.formatString, days, hours, minutes, seconds)
        end
    elseif self.formatType == SuperCooldown.FORMAT_TYPE.HOUR_MIN_SEC then
        if self.removeInvalidInfo and hours == 0 then
            text = string.format("%02d:%02d", minutes, seconds)
        else
            text = string.format(self.formatString, hours, minutes, seconds)
        end
    elseif self.formatType == SuperCooldown.FORMAT_TYPE.MIN_SEC then
        text = string.format(self.formatString, minutes, seconds)
    elseif self.formatType == SuperCooldown.FORMAT_TYPE.SEC then
        text = string.format(self.formatString, self.remainingTime)
    end

    self:SetText(text)
    
    -- 根据剩余时间设置颜色
    if self.warningThreshold > 0 and math.floor(self.remainingTime) <= self.warningThreshold then
        self:SetColor(self.warningColor)
    else
        self:SetColor(self.normalColor)
    end
end

function SuperCooldown:Update(deltaTime)
    if not self.isRunning or self.isPaused then
        return
    end

    self.remainingTime = self.remainingTime - deltaTime
    if self.remainingTime <= 0 then
        self.remainingTime = 0
        self.isRunning = false
        if self.completedCallback then
            self.completedCallback(self)
        end
    end

    self:UpdateText()
end

--完成回调
function SuperCooldown:CompletedCallback(completedCallback)
    self.completedCallback = completedCallback
end

return SuperCooldown