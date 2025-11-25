--[[
    ConfigHelper - 配置管理辅助工具

    位置: Framework/GamePlay/
    依赖: CoreModule.ConfigManager, CoreModule.Log, CoreModule.Utils

    功能说明:
    - Init: 初始化配置系统，注册所有数据读取器
    - Register: 注册单个配置表的数据读取器

    支持的配置类型:
    - 游戏配置: Skill, Buff, Monster, Item, Quest, Pet, Player
    - 场景配置: Scene, SceneList
    - 系统配置: GameSettings, Stat, AIConfig
    - 图表配置: SkillGraph, BuffGraph

    使用场景:
    - 框架初始化：在ClientEntry和ServerEntry中首先初始化
    - 配置加载：为CoreModule.ConfigManager注册数据读取器
    - 数据访问：通过ConfigManager访问配置数据

    使用示例:
    ```lua
    -- 在ClientEntry.lua或ServerEntry.lua中
    local ConfigHelper = require(MainStorage.Scripts.ConfigHelper)
    local success = ConfigHelper:Init()

    -- 之后可以通过ConfigManager访问配置
    local ConfigManager = GFScript("CoreModule.ConfigManager")
    local skillData = ConfigManager:Get("Skill", skillId)
    ```

    注意事项:
    - 必须在框架初始化的第一步调用Init()
    - 配置文件位于MainStorage.Framework.Config或MainStorage.Framework.Config.User
    - 支持单个文件配置和多文件配置
    - 支持集合类型配置（通过数字ID或字符串ID访问）

    引用位置:
    - Framework/SGFFramework.lua (在GameFramework加载后,Startup之前调用)

    路径说明:
    - 代码引用路径: MainStorage.Framework.GamePlay.ConfigHelper
    - 实际文件位置: Framework/GamePlay/ConfigHelper.lua
    - 配置文件路径: MainStorage.Framework.Config.User (UserConfig)
    - 配置文件路径: MainStorage.Framework.Config (通用Config)
]]

local ConfigHelper = {}

function ConfigHelper:Init()
    local MainStorage = game:GetService("MainStorage")
    
    local ConfigManager = GFScript("CoreModule.ConfigManager")
    local Log = GFScript("CoreModule.Log")
    local Utils = GFScript("CoreModule.Utils")


    --注册数据读取器
    --name: 数据表名称
    --single: 是否单个数据读取
    --isSet: 是否是集合
    local function Register(name, single, isSet, keyFormat)
        ConfigManager:Register(name, single, function(tid)
            local loadAll = tid == nil
            if keyFormat then
                tid = keyFormat(tid)
            end
            tid = tostring(tid)
            single = single == nil and false or single
            isSet = isSet == nil and false or isSet
            -- rpg-gamedemo路径: MainStorage.Framework.Config.User 和 MainStorage.Framework.Config
            local table = MainStorage.Framework.Config.User[name]
            if not table then
                table = MainStorage.Framework.Config[name]
            end
            if not table then
                Log:Error("Can not find config : "..name)
                return nil
            end
            if not single then
                local node = table[tid]
                if node then
                    local data = require(node)
                    if isSet then
                        return data[tonumber(tid)]
                    end
                    return data
                end
                return nil
            end
            local data = require(table)
            if isSet then
                local numberId = tonumber(tid)
                if numberId then
                    return data[numberId]
                end
                if loadAll then
                    return data
                end
                return data[tid]
            end
            return data
        end)
    end
    
    --注册各类数据读取器
    Register("Skill")
    Register("SkillGraph",false, false, function(name)
        return "Skill_"..name
    end)
    Register("Buff")
    Register("BuffGraph",false, false, function(name)
        return "Buff_"..name
    end)

    Register("Monster")
    Register("AIConfig")
    Register("Item")
    Register("Quest")
    Register("Stat")
    Register("Pet")
    Register("Player")
    Register("GameSettings", true)
    Register("SceneList", true)
    Register("Scene")

    --注册所有配置表
    -- rpg-gamedemo路径: MainStorage.Framework.Config
    local configs = MainStorage.Framework.Config.Children
    for _, config in ipairs(configs) do
        local name = config.Name
        Register(name, true, true)
    end
end


return ConfigHelper
