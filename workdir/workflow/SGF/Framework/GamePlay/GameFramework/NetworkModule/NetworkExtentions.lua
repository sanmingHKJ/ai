local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local NetworkPacker = GFScript("NetworkModule.NetworkPacker")
local NetworkExtentions = {}


function NetworkExtentions:Init()
    local Skill = GFScript("SkillModule.Skill")
    local Buff = GFScript("BuffModule.Buff")
    local Vec2 = GFScript("CoreModule.Math.Vec2")
    local Vec3 = GFScript("CoreModule.Math.Vec3")
    local Quat = GFScript("CoreModule.Math.Quat")
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Vec2",
    function(obj)
        --序列化
        local data = {
            x = obj.x,
            y = obj.y,
        }
        return data
    end,
    function(data)
        --反序列化
        local obj = Vec2.New(data.x,data.y)
        return obj
    end)
    
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Vec3",
    function(obj)
        --序列化
        local data = {
            x = obj.x,
            y = obj.y,
            z = obj.z,
        }
        return data
    end,
    function(data)
        --反序列化
        local obj = Vec3.New(data.x,data.y,data.z)
        return obj
    end)
    
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Quat",
    function(obj)
        --序列化
        local data = {
            w = obj.w,
            x = obj.x,
            y = obj.y,
            z = obj.z,
        }
        return data
    end,
    function(data)
        --反序列化
        local obj = Quat.New(data.w,data.x,data.y,data.z)
        return obj
    end)
    
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Actor",
    function(obj)
        --序列化
        local data = {
            actorId = obj.actorId,
        }
        return data
    end,
    function(data,isServer)
        --反序列化
        if isServer then
            return NetworkServer:GetSpawned(data.actorId)
        end
        return NetworkClient:GetSpawned(data.actorId)
    end)
    
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Buff",
    function(obj)
        --序列化
        local data = {
            tid = obj.tid,
            durationEnd = obj.durationEnd,
            stack = obj.stack
        }
        return data
    end,
    function(data)
        --反序列化
        local obj = Buff.New()
        obj:Init(data.tid, data.stack)
        obj.durationEnd = data.durationEnd
        return obj
    end)
    
    
    --注册序列化处理器
    NetworkPacker:RegisterSerializer("Skill",
    function(obj)
        --序列化
        local data = {
            tid = obj.tid,
        }
        return data
    end,
    function(data)
        --反序列化
        local obj = Skill.New()
        obj:Init(data.tid)
        return obj
    end)
end

return NetworkExtentions