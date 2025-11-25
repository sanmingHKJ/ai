# SGF框架 4.0 使用指南

**版本**: 4.0.0
**构建日期**: 2025-10-21
**状态**: ✅ 生产就绪

---

## 📖 简介

SGF（Studio Game Framework）是一个为迷你世界Studio设计的模块化游戏框架，提供了完整的游戏系统集合和辅助工具。

### 核心特性

- ✅ **模块化设计**：11个独立的游戏系统模块
- ✅ **统一接口**：所有系统遵循统一的初始化和更新接口
- ✅ **按需加载**：支持选择性加载需要的系统
- ✅ **无依赖**：完全移除旧框架依赖（GFScript）
- ✅ **易于扩展**：清晰的架构便于添加新系统
- ✅ **标准化开发**：固化的开发流程和套路，AI友好

---

## 🎯 SGF标准化开发框架

SGF 4.0引入了完整的标准化开发体系，通过固化开发流程、标准化模块接口、统一开发套路，让AI能够按照固定的模式开发各种类型的游戏。

### 标准化开发文档

📚 **完整文档请查看**: [SGF标准化开发框架完整指南](./Docs/SGF_README.md)

#### 核心文档

1. **[SGF开发标准总览](./Docs/SGF_Development_Standard.md)** - 框架架构和标准化生命周期
2. **[业务模块开发指南](./Docs/SGF_Module_Development_Guide.md)** - 业务系统模块规范和模板
3. **[UI开发标准套路](./Docs/SGF_UI_Development_Guide.md)** - UI面板开发标准流程
4. **[网络通信标准套路](./Docs/SGF_Network_Development_Guide.md)** - 客户端-服务端通信标准
5. **[3D交互标准套路](./Docs/SGF_3D_Interaction_Guide.md)** - 3D场景交互标准处理
6. **[主客机分离开发指南](./Docs/SGF_Client_Server_Separation.md)** - 客户端和服务端开发套路

#### 模板文件

- `Templates/BusinessSystemTemplate.lua` - 业务系统模板
- `Templates/UIPanelTemplate.lua` - UI面板模板

### 标准化开发的优势

1. **固化流程**：游戏加载、启动、初始化、主循环等流程完全标准化
2. **统一接口**：所有业务模块遵循统一的生命周期接口
3. **AI友好**：标准化的开发模式让AI能够快速理解和实现
4. **易于维护**：统一的代码结构便于团队协作和维护
5. **快速开发**：使用模板可以快速创建新的业务系统和UI面板

---

## 🚀 快速开始

### 基础使用

```lua
-- 1. 引入SGF框架
local MainStorage = game:GetService("MainStorage")
local SGFFramework = require(MainStorage.Framework.SGFFramework)

-- 2. 创建框架实例
local sgf = SGFFramework.new()

-- 3. 初始化框架（加载所有系统）
sgf:Init()

-- 4. 在游戏循环中更新框架
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
    sgf:Update(dt)
end)
```

### 选择性加载系统

```lua
-- 只加载需要的系统
local sgf = SGFFramework.new()
sgf:Init({
    systems = {"core", "network", "actor", "ui"}
})
```

---

## 📦 系统模块

### 1. CoreSystem（核心工具系统）

**功能**：提供基础工具和服务

**包含组件**：
- Log, Class, Json, Utils, TableUtils
- TimerManager, Tween, Database, Resource
- Math库（Vec2/3/4, Mat3/4, Quat等）
- Effect系统、Sound系统

**使用示例**：
```lua
local coreSystem = sgf:GetSystem("core")
local Log = coreSystem:GetComponent("Log")
Log:Info("Hello SGF!")

local TimerManager = coreSystem:GetComponent("TimerManager")
TimerManager:AddTimer(1.0, function()
    print("1秒后执行")
end)
```

---

### 2. NetworkSystem（网络系统）

**功能**：提供网络通信功能

**包含组件**：
- Network, NetProto, NetworkDefines
- NetworkPacker, NetworkExtentions

**使用示例**：
```lua
local networkSystem = sgf:GetSystem("network")
local Network = networkSystem:GetComponent("Network")

-- 发送网络消息
Network:SendMessage("PlayerMove", {x = 10, y = 20})
```

---

### 3. ActorSystem（Actor系统）

**功能**：管理游戏中的角色和实体

**包含组件**：
- Actor, Player, Npc, ActorManager
- AOI, PathSystem, PedestrianSystem

**使用示例**：
```lua
local actorSystem = sgf:GetSystem("actor")
local ActorManager = actorSystem:GetComponent("ActorManager")

-- 创建玩家Actor
local player = ActorManager:CreatePlayer(playerId)
```

---

### 4. UISystem（UI系统）

**功能**：管理游戏UI

**包含组件**：
- UIManager, UIView, UILayout
- UITween, UIResource, UIEventObject

**使用示例**：
```lua
local uiSystem = sgf:GetSystem("ui")
local UIManager = uiSystem:GetComponent("UIManager")

-- 显示UI界面
UIManager:ShowView("MainMenu")
```

---

### 5. StatSystem（属性系统）

**功能**：管理角色属性

**包含组件**：
- Stat, StatManager, StatCalculater
- HealthComponent, ManaComponent, ExpComponent

**使用示例**：
```lua
local statSystem = sgf:GetSystem("stat")
local StatManager = statSystem:GetComponent("StatManager")

-- 设置角色生命值
StatManager:SetHealth(actorId, 100)
```

---

### 6. CombatSystem（战斗系统）

**功能**：管理战斗逻辑

**包含组件**：
- Combat, CombatManager, TargetSystem
- HateSystem, Skill, DamageCalculator

**使用示例**：
```lua
local combatSystem = sgf:GetSystem("combat")
local CombatManager = combatSystem:GetComponent("CombatManager")

-- 发起攻击
CombatManager:Attack(attackerId, targetId)
```

---

### 7. AISystem（AI系统）

**功能**：管理AI行为

**包含组件**：
- AI, AIManager, AIBehaviorTree
- PerceptionSystem, PathFinding

**使用示例**：
```lua
local aiSystem = sgf:GetSystem("ai")
local AIManager = aiSystem:GetComponent("AIManager")

-- 设置AI行为
AIManager:SetBehavior(npcId, "Patrol")
```

---

### 8. AvatarSystem（Avatar系统）

**功能**：管理角色外观和动画

**包含组件**：
- Avatar, AvatarManager
- AnimationController, CameraController

---

### 9. PetSystem（宠物系统）

**功能**：管理宠物

**包含组件**：
- Pet, PetManager, PetSkill

---

### 10. GmSystem（GM系统）

**功能**：提供GM命令和调试工具

**包含组件**：
- GmManager, GmCommands, DebugConsole

---

### 11. TestSystem（测试系统）

**功能**：提供测试框架

**包含组件**：
- TestManager, UnitTest, IntegrationTest

---

## 🛠️ 辅助模块

### ModulesManager

**功能**：管理框架辅助模块

**包含模块**：
- ConfigHelper - 配置辅助
- NetworkHelper - 网络辅助
- ActorHelper - Actor辅助
- EffectPoolManager - 特效池管理
- Bridge - 桥接模块
- Protocol - 协议模块

**使用示例**：
```lua
local configHelper = sgf:GetModule("ConfigHelper")
local config = configHelper:LoadConfig("GameSettings")
```

---

## 📁 目录结构

```
framework/
├── SGFFramework.lua          # 框架主入口
├── README.md                 # 本文档
│
├── shared/                   # 共享层
│   ├── GlobalServices.lua
│   ├── EventID.lua
│   └── Constants.lua
│
├── utils/                    # 工具层
│   ├── ObserverHelper.lua
│   └── ReportData.lua
│
├── config/                   # 配置层
│   ├── MapConfig.lua
│   └── TradeConfig.lua
│
├── core/                     # 核心服务
│   ├── LogService.lua
│   ├── EventBus.lua
│   ├── ConfigService.lua
│   └── ...
│
├── modules/                  # 辅助模块
│   ├── ModulesManager.lua
│   ├── ConfigHelper.lua
│   ├── NetworkHelper.lua
│   └── ...
│
├── server/                   # 服务器入口
│   └── ServerEntry.lua
│
├── client/                   # 客户端入口
│   └── ClientEntry.lua
│
└── systems/                  # 游戏系统
    ├── core/                 # 核心工具系统
    ├── network/              # 网络系统
    ├── actor/                # Actor系统
    ├── ui/                   # UI系统
    ├── stat/                 # 属性系统
    ├── combat/               # 战斗系统
    ├── ai/                   # AI系统
    ├── avatar/               # Avatar系统
    ├── pet/                  # 宠物系统
    ├── gm/                   # GM系统
    └── test/                 # 测试系统
```

---

## 🔧 高级用法

### 自定义系统初始化顺序

```lua
local sgf = SGFFramework.new()

-- 先初始化核心系统
sgf:Init({systems = {"core", "network"}})

-- 游戏开始后再加载其他系统
sgf:InitSystems({"actor", "ui", "combat"})
```

### 获取框架信息

```lua
local info = sgf:GetInfo()
print("SGF版本: " .. info.version)
print("已加载系统数: " .. info.systemsCount)

-- 打印详细信息
sgf:PrintInfo()
```

### 事件系统

```lua
-- 订阅事件
sgf.eventBus:Subscribe("PlayerJoin", function(player)
    print("玩家加入: " .. player.Name)
end)

-- 发布事件
sgf.eventBus:Publish("PlayerJoin", player)
```

---

## 📊 性能建议

1. **按需加载**：只加载游戏需要的系统模块
2. **延迟初始化**：非核心系统可以延迟到需要时再初始化
3. **对象池**：使用EffectPoolManager管理特效对象
4. **事件驱动**：使用EventBus而不是轮询

---

## 🐛 调试

### 启用日志

```lua
-- 设置日志级别
sgf.log:SetLevel("DEBUG")

-- 输出日志
sgf.log:debug("调试信息")
sgf.log:info("普通信息")
sgf.log:warn("警告信息")
sgf.log:error("错误信息")
```

### 使用GM命令

```lua
local gmSystem = sgf:GetSystem("gm")
local GmManager = gmSystem:GetComponent("GmManager")

-- 执行GM命令
GmManager:ExecuteCommand("give_item 1001 10")
```

---

## 📚 更多文档

- `SGF_FRAMEWORK_INTEGRATION_PROGRESS.md` - 整合进度详情
- `SGF_FRAMEWORK_INTEGRATION_SUMMARY.md` - 整合总结
- `SGF_FRAMEWORK_FINAL_REPORT.md` - 最终报告

---

## 🤝 贡献

欢迎提交问题和改进建议！

---

**SGF框架 4.0** - 为迷你世界Studio打造的专业游戏框架

