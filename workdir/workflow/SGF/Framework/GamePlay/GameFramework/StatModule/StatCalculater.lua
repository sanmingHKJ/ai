local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local StatCalculater = Class.New("StatCalculater")

function StatCalculater:Constructor()
    self.stats = {}
    self.percentStats = {}

    self.finalStats = {}
    self.dirty = true
end

--添加属性
function StatCalculater:AddStat(statName, value)
    if Utils:EndWith(statName, "Per") then
        statName = string.sub(statName, 1, #statName - 3)
        if self.percentStats[statName] == nil then
            self.percentStats[statName] = 0
        end
        self.percentStats[statName] = self.percentStats[statName] + value
    else
        if self.stats[statName] == nil then
            self.stats[statName] = 0
        end
        self.stats[statName] = self.stats[statName] + value
    end
    self.dirty = true
end

--获取属性
function StatCalculater:GetFinalStat(statName)
    if self.dirty then
        self:Calculate()
    end
    if self.finalStats[statName] == nil then
        return 0
    end
    return self.finalStats[statName]
end

--清理
function StatCalculater:Clear()
    self.stats = {}
    self.percentStats = {}
    self.finalStats = {}
end

--计算属性  
function StatCalculater:Calculate()
    self.finalStats = {}
    for k, v in pairs(self.stats) do
        local mul = 1
        if self.percentStats[k] ~= nil then
            mul = 1 + self.percentStats[k] / 100
        end
        self.finalStats[k] = v * mul
    end

    self.dirty = false
end

return StatCalculater