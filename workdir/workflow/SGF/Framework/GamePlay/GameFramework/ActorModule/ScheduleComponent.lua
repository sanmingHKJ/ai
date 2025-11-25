local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActorComponent = GFScript("ActorModule.ActorComponent")

-- scheduler:AddTrigger(triggerName, {sec = 30}, TriggerPeriod.Minute)  -- 每分钟触发（在每分钟的第30秒触发）
-- scheduler:AddTrigger(triggerName, {min = 30, sec = 0}, TriggerPeriod.Hour)  -- 每小时的第30分钟触发
-- scheduler:AddTrigger(triggerName, {hour = 4, min = 0, sec = 0}, TriggerPeriod.Day)  -- 每天4点触发
-- scheduler:AddTrigger(triggerName, {hour = 4, min = 0, sec = 0, wday = 1}, TriggerPeriod.Week)  -- 每周一4点触发
-- scheduler:AddTrigger(triggerName, {hour = 4, min = 0, sec = 0, day = 1}, TriggerPeriod.Month)  -- 每月1号4点触发
-- scheduler:AddTrigger(triggerName, {hour = 4, min = 0, sec = 0, day = 1, month = 1}, TriggerPeriod.Year)  -- 每年1月1号4点触发

-- 触发周期类型
local TriggerPeriod = {
    Minute = "Minute", -- 每分钟
    Hour = "Hour",    -- 每小时
    Day = "Day",      -- 每天
    Week = "Week",    -- 每周
    Month = "Month",  -- 每月
    Year = "Year"     -- 每年
}

local ScheduleComponent = ActorComponent.Extend("ScheduleComponent")

function ScheduleComponent:Constructor()
    self.triggers = {}
    self.lastCheckTime = 0
    self.dataTableName = "Scheduler"
end

function ScheduleComponent:Awake()
    ScheduleComponent.super.Awake(self)
    self:CheckMissedTriggers()
end

--服务端初始化
function ScheduleComponent:OnStartServer()
    ScheduleComponent.super.OnStartServer(self)
end

function ScheduleComponent:UpdateServer(dt)
    ScheduleComponent.super.UpdateServer(self, dt)
    self:CheckTimeTriggers()
end

-- 添加定时触发器
function ScheduleComponent:AddTrigger(triggerName, triggerTime, period)
    self.triggers[triggerName] = {
        triggerName = triggerName,
        triggerTime = triggerTime,  -- {hour = 4, min = 0, sec = 0, wday = 1} 根据period类型需要不同的字段
        period = period or TriggerPeriod.Day
    }
end

-- 移除定时触发器
function ScheduleComponent:RemoveTrigger(triggerName)
    self.triggers[triggerName] = nil
end

-- 检查错过的触发
function ScheduleComponent:CheckMissedTriggers()
    local currentTime = os.time()
    local lastCheckTime = self.lastCheckTime
    
    for triggerName, trigger in pairs(self.triggers) do
        local nextTriggerTime = self:GetNextTriggerTime(trigger.triggerTime, lastCheckTime, trigger.period)
        while nextTriggerTime <= currentTime do
            self:FireTrigger(trigger)
            nextTriggerTime = self:GetNextTriggerTime(trigger.triggerTime, nextTriggerTime, trigger.period)
        end
    end

    self.lastCheckTime = currentTime
end

-- 检查定时触发
function ScheduleComponent:CheckTimeTriggers()
    local currentTime = os.time()
    -- 对于每分钟触发的触发器，我们需要更频繁地检查
    local checkInterval = 1  -- 默认1秒检查一次
    if currentTime - self.lastCheckTime >= checkInterval then
        for triggerName, trigger in pairs(self.triggers) do
            local nextTriggerTime = self:GetNextTriggerTime(trigger.triggerTime, self.lastCheckTime, trigger.period)
            if nextTriggerTime <= currentTime then
                self:FireTrigger(trigger)
            end
        end
        self.lastCheckTime = currentTime
    end
end

-- 获取下一个触发时间
function ScheduleComponent:GetNextTriggerTime(triggerTime, fromTime, period)
    local timeTable = os.date("*t", fromTime)
    
    -- 设置基本时间（秒）
    timeTable.sec = triggerTime.sec or 0
    
    -- 根据不同的触发周期设置时间
    if period == TriggerPeriod.Minute then
        -- 每分钟触发，只需要设置秒
    elseif period == TriggerPeriod.Hour then
        timeTable.min = triggerTime.min or 0
    elseif period == TriggerPeriod.Day then
        timeTable.hour = triggerTime.hour or 0
        timeTable.min = triggerTime.min or 0
    elseif period == TriggerPeriod.Week then
        timeTable.hour = triggerTime.hour or 0
        timeTable.min = triggerTime.min or 0
        -- 调整到下一个指定的星期几
        local targetWday = triggerTime.wday or 1
        local currentWday = timeTable.wday
        if currentWday > targetWday then
            timeTable.day = timeTable.day + (7 - currentWday + targetWday)
        elseif currentWday < targetWday then
            timeTable.day = timeTable.day + (targetWday - currentWday)
        end
    elseif period == TriggerPeriod.Month then
        timeTable.hour = triggerTime.hour or 0
        timeTable.min = triggerTime.min or 0
        timeTable.day = triggerTime.day or 1
    elseif period == TriggerPeriod.Year then
        timeTable.hour = triggerTime.hour or 0
        timeTable.min = triggerTime.min or 0
        timeTable.day = triggerTime.day or 1
        timeTable.month = triggerTime.month or 1
    end
    
    local nextTime = os.time(timeTable)
    if nextTime <= fromTime then
        -- 根据不同的触发周期增加时间
        if period == TriggerPeriod.Minute then
            timeTable.min = timeTable.min + 1
        elseif period == TriggerPeriod.Hour then
            timeTable.hour = timeTable.hour + 1
        elseif period == TriggerPeriod.Day then
            timeTable.day = timeTable.day + 1
        elseif period == TriggerPeriod.Week then
            timeTable.day = timeTable.day + 7
        elseif period == TriggerPeriod.Month then
            timeTable.month = timeTable.month + 1
            if timeTable.month > 12 then
                timeTable.month = 1
                timeTable.year = timeTable.year + 1
            end
        elseif period == TriggerPeriod.Year then
            timeTable.year = timeTable.year + 1
        end
        nextTime = os.time(timeTable)
    end
    return nextTime
end

-- 执行触发器
function ScheduleComponent:FireTrigger(trigger)
    if self:IsServer() then
        self:FireServer("Scheduler", trigger.triggerName)
    else
        self:FireClient("Scheduler", trigger.triggerName)
    end
end

function ScheduleComponent:Serialize(data, purpose)
    ScheduleComponent.super.Serialize(self, data, purpose)
    -- data.lastCheckTime = self.lastCheckTime
end

function ScheduleComponent:Deserialize(data)
    ScheduleComponent.super.Deserialize(self, data)
    -- self.lastCheckTime = data.lastCheckTime
end

--获取数据
function ScheduleComponent:GetData()
    local data = {}
    data.lastCheckTime = self.lastCheckTime
    return data
end

--设置数据
function ScheduleComponent:SetData(data)
    self.lastCheckTime = data.lastCheckTime
end

return ScheduleComponent
