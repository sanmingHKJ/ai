-- 漫游控制类
local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local TimerManager = GFScript("CoreModule.TimerManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Debugger = GFScript("CoreModule.Debugger")
local SkillManager = GFScript("SkillModule.SkillManager")
local CombatDefines = GFScript("CombatModule.CombatDefines")

local CNpc = require(script.Parent.CNpc)

local CWalker = Class.New("CWalker", CNpc)


return CWalker