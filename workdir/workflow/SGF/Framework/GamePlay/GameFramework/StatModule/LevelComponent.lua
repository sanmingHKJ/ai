local Class = GFScript("CoreModule.Class")
local EnergyComponent = GFScript("StatModule.EnergyComponent")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local ItemDefines = GFScript("InventoryModule.ItemDefines")
local Log = GFScript("CoreModule.Log")

-- 创建Level类并继承Energy类
local LevelComponent = Class.New("LevelComponent", EnergyComponent)

LevelComponent.version = 1

function LevelComponent:Construct()
    self.exp = 0 --升级所需经验
    self.rewards = {} --升级奖励
end

-- 构造函数
function LevelComponent:Awake()
    LevelComponent.super.Awake(self)
    self.valueStatName = "level"
    self.maxValueStatName = "maxLevel"
end

--获取能量名字
function LevelComponent:GetEnergyName()
    return "Level"
end

--启动服务端
function LevelComponent:OnStartServer()
    LevelComponent.super.OnStartServer(self)
    self.actor:OnServerEvent("LevelChanged", self.OnLevelChanged, self)
end
--启动客户端
function LevelComponent:OnStartClient()
    LevelComponent.super.OnStartClient(self)
end

--当前值改变事件
function LevelComponent:OnValueChange(oldValue, newValue)
    LevelComponent.super.OnValueChange(self, oldValue, newValue)

    -- 发放奖励
    self.actor.InventoryComponent:GrantRewards(self.rewards, ItemDefines.EOpSource.LevelUp)

    self.actor:Fire(self.actor:IsServer(), "LevelChanged", oldValue, newValue)

    --获取升级所需经验
    self:LoadLevelConfig(newValue)
end
--设置当前值
function LevelComponent:SetValue(value)
    LevelComponent.super.SetValue(self, value)
end

--等级改变
function LevelComponent:OnLevelChanged(oldLevel, newLevel)
    
end

--加载等级配置
function LevelComponent:LoadLevelConfig(level)
    local levelConfig = ConfigManager:Get("level_table", level)
    if not levelConfig then
        Log:Error("LevelComponent:LoadLevelConfig", "levelConfig is nil")
        return
    end
    self.exp = levelConfig.Exp
    self.rewards = levelConfig.Rewards
end

--获取升级所需经验
function LevelComponent:GetExp()
    return self.exp
end

--获取升级奖励
function LevelComponent:GetRewards()
    return self.rewards
end

return LevelComponent