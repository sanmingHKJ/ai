--[[
    ArenaBattleProto.lua - Arena Battle Game Network Protocol

    网络协议定义文件
    定义客户端和服务端之间的所有网络消息类型

    Version: 1.0.0
]]

local ArenaBattleProto = {
    -- ========== 客户端 -> 服务端 ==========
    Client = {
        -- 玩家战斗相关
        RequestAttackPlayer = 1001,     -- 请求攻击玩家
        RequestPlayerData = 1002,       -- 请求玩家战斗数据

        -- 得分系统相关
        RequestLeaderboard = 1003,      -- 请求排行榜数据

        -- 竞技场相关
        RequestJoinArena = 1004,        -- 请求加入竞技场
        RequestRespawn = 1005,          -- 请求复活
    },

    -- ========== 服务端 -> 客户端 ==========
    Server = {
        -- 玩家战斗响应
        ResponseAttackResult = 2001,    -- 攻击结果响应
        ResponsePlayerData = 2002,      -- 玩家数据响应

        -- 玩家状态通知
        NotifyPlayerHit = 2004,         -- 通知玩家被击中
        NotifyPlayerKilled = 2005,      -- 通知玩家被击杀
        NotifyPlayerRespawn = 2006,     -- 通知玩家复活
        NotifyHealthUpdate = 2007,      -- 通知生命值更新

        -- 得分系统响应
        ResponseLeaderboard = 2003,     -- 排行榜响应
        BroadcastScoreUpdate = 2008,    -- 广播得分更新

        -- 竞技场响应
        ResponseJoinArena = 2009,       -- 加入竞技场响应
        BroadcastPlayerJoined = 2010,   -- 广播玩家加入
        BroadcastPlayerLeft = 2011,     -- 广播玩家离开
    },
}

-- 合并为单一命名空间（兼容旧代码）
local ArenaProto = {}
for _, codes in pairs(ArenaBattleProto.Client) do
    ArenaProto[_] = codes
end
for _, codes in pairs(ArenaBattleProto.Server) do
    ArenaProto[_] = codes
end

-- 导出两种格式
ArenaBattleProto.All = ArenaProto

return ArenaBattleProto
