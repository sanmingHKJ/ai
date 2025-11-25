-- Mini Studio Global Definitions
-- SGF Framework Core Module

MS = {}

-- 服务
MS.RunService			        =   game:GetService("RunService")
MS.Players 				        =   game:GetService("Players")
MS.TweenService 		        =   game:GetService('TweenService')
MS.WorkSpace 			        =   game:GetService("WorkSpace")
MS.Environment                  =   MS.WorkSpace.Environment
MS.ServerStorage 		        =   game:GetService("ServerStorage")
MS.MainStorage 	    	        =   game:GetService("MainStorage")
MS.ContextActionService         =   game:GetService("ContextActionService")
MS.UserInputService             =   game:GetService("UserInputService")
MS.WorldService                 =   game:GetService("WorldService")
MS.CloudService                 =   game:GetService("CloudService")                     -- 云数据
MS.DeveloperStoreService        =   game:GetService("DeveloperStoreService")            -- 迷你币商品服务
MS.CoreUi                       =   game:GetService("CoreUi")                           -- 游戏核心界面信息
MS.PhysXService                 =   game:GetService("PhysXService")
MS.Chat                         =   game:GetService("Chat")
MS.FriendInviteService          =   game:GetService("FriendInviteService")              -- 好友拉新
MS.FriendService                =   game:GetService("FriendsService")                    -- 好友情况
MS.StarterGui                   =   game:GetService("StarterGui")
MS.TeleportService              =   game:GetService("TeleportService")                  -- 传送服务
MS.AnalyticsService             =   game:GetService("AnalyticsService")                 -- 数据埋点服务
MS.UtilService                  =   game:GetService('UtilService')
MS.MouseService                 =   game:GetService('MouseService')                     -- 鼠标服务
MS.CloudServerConfigService     =   game:GetService('CloudServerConfigService')         -- 机器人服务
MS.SceneMgr                     =   game:GetService("SceneMgr")                         --副本服务

-- 平台
MS.CUR_PLATFORM                 =   MS.Environment:GetDeviceType()

-- SGF Framework 路径
local Framework      =   script.Parent.Parent
local Core           =   Framework:WaitForChild("Core")
local Runtime        =   Framework:WaitForChild("Runtime")
local Utils          =   Framework:WaitForChild("Utils")
local GamePlay       =   Framework:WaitForChild("GamePlay")
local ConfigFramework=   Framework:WaitForChild("Config"):WaitForChild("Framework")

-- 核心模块
MS.EventBus          =   require(Core:WaitForChild("EventBus"))
MS.Events            =   MS.EventBus.new()
MS.EventID           =   require(Runtime:WaitForChild("EventID"))
MS.Protocol          =   require(Runtime:WaitForChild("Protocol"))
MS.Config            =   require(ConfigFramework:WaitForChild('CommonConfig'))
MS.Const             =   require(ConfigFramework:WaitForChild("Const"))

-- GamePlay模块
MS.GameStateBase     =   require(GamePlay:WaitForChild("GameStateBase"))
MS.Bridge            =   require(Runtime:WaitForChild("Bridge"))

-- 工具模块
MS.ReportData        =   require(Utils:WaitForChild("ReportData"))

return MS
