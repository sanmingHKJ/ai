local CloudService = game:GetService("CloudService")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local SMatch = require(script.SMatch)
local STrade = require(script.STrade)
local SWareHouse = require(script.SWareHouse)
local MapTime = os.date("%Y%m%d_%H%M%S", RunService:GetCurMapUpdateTimestamp())
local MapIdMap = {
    -- 正式服

    ["66827222907990"] = "66814338006102",  -- TPS射击测试服
    ['39365275497853'] = "39369570465149",  -- 交易行测试服
    ['66831517875286'] = "66835812842582",  -- TPS正式服
}

local MyMapId = RunService:GetCurMapOwid()
local CenterMapId = MapIdMap[MyMapId]
local CenterMapTag = "tpsgc"

local SGameCenter = {}
_G.SGameCenter = SGameCenter

SGameCenter.MapIdMap = MapIdMap
SGameCenter.CenterRID = nil
SGameCenter.CenterRoomId = nil
SGameCenter.CenterHandler = {}

local function send_message(list, ...)
    assert(#list == 1)
    if GameCenterSim then -- 模拟中心服
        assert(list[1] == "single")
        GGameCenter:OnServerMessage("single", ...)
    else
        CloudService:SendMessage(list, ...)
    end
end

function SGameCenter:Init()
    print("SGameCenter:Init", MapTime, MyMapId, CenterMapId)
    MS.NetworkHelper:RegisterNetObj(SGameCenter.CenterHandler)
    MS.NetworkHelper:RegisterNetObj(self)

    Network:ServerSetCallback(ActorNetProto.RequestGCPlayerInfo, self.GetGCPlayerInfo, self)
    Network:ServerSetCallback(ActorNetProto.UpdateGCPlayerInfo, self.UpdateGCPlayerInfo, self)
    Network:ServerSetCallback(ActorNetProto.RequestGCGM, self.HandleGCGM, self)

    SMatch:Init(self)
    STrade:Init(self)
    SWareHouse:Init(self)

    if GameCenterSim then   -- 模拟中心服
        print("SGameCenter:Init GameCenterSim")
        self.CenterRID = "single"
        self:OnCenterConnected(0, "single")
        return
    end

    if RunService:GetAppPlatformName()~="CloudServer" then  -- 仅在线云服运行
        return
    end
    if not CenterMapId then
        Network:Error("SGameCenter:Init no CenterMapId - " .. MyMapId)
        return
    end

    -- 唤起Center（如果没启动的话）
    CloudService:GetCenterServerAsync(
        CenterMapTag,
        CenterMapId,
        function(ret, roomId) end
    )

    -- 收到：Center上线
    CloudService:SubscribeAsync("CenterOnline", function(rid, ver)
        self:OnCenterOnline(rid, ver)
    end)

    -- 收到：Center消息
    CloudService.NotifyOnMessage:Connect(function(rid, typ, ...)
        SGameCenter:OnCenterMessage(typ, ...)
    end)

    -- 通知：Server上线
    CloudService:PublishAsync("ServerOnline", MapTime)
end

function SGameCenter:OnCenterOnline(rid, mpt)
    local CenterRID = self.CenterRID
    print("CenterOnline", rid, mpt, CenterRID, MapTime)
    if CenterRID then   -- 之前的Center掉线
        SGameCenter:OnCenterDisconnected()
    end
    self.CenterRID = rid
    -- 获取游戏中心房间ID
    CloudService:GetCenterServerAsync(
        CenterMapTag,
        CenterMapId,
        function(ret, roomId)
            self:OnCenterConnected(ret, roomId)
        end
    )
end

function SGameCenter:OnCenterConnected(ret, roomId)
    print("SGameCenter:OnCenterConnected:", tostring(ret), tostring(roomId))
    if ret == 0 then
        self.CenterRoomId = roomId
        SGameCenter:ToCenter("Init", MapTime, CloudService:GetServerID(), MyMapId)
        -- 补调已上线玩家
        for i, player in pairs(PlayersService:GetPlayers()) do
            -- 防止重复请求
            if MSServer.SActorManager:GetPlayerByUserId(player.UserId) ~= nil then
                self:OnPlayerAdded(player, true)
            end
        end
    else
        self.CenterRoomId = nil
    end
end

function SGameCenter:OnCenterDisconnected()
    self.CenterRoomId = nil
    -- 通知所有客户端：Center断线
    Network:Broadcast(ActorNetProto.DisconnectGCResponse, {reason = "CenterDisconnect"})
end

function SGameCenter:OnCenterMessage(typ, ...)
    local fun = self.CenterHandler[typ]
    if not fun then
        Network:Error("SGameCenter:OnCenterMessage no handler:" .. tostring(typ))
        return
    end
    local ok, msg = pcall(fun, self, ...)
    if not ok then
        Network:Error("SGameCenter:OnCenterMessage error["..typ.."]:\n"..tostring(msg))
    end
end

function SGameCenter:OnPlayerAdded(player, second)
    -- 上线通知
    local uin = player.UserId
    print("SGameCenter:OnPlayerAdded", uin, second, self.CenterRoomId)
    if not second then    -- 不是第二次
        -- 首次上线处理
    end
    if self.CenterRoomId then   -- 如果Center已连接
        self:ToCenter("PlayerAdded", uin, self:GetPlayerInfo(player))

        SMatch:OnPlayerAdded(player, second)
        STrade:OnPlayerAdded(player, second)
        SWareHouse:OnPlayerAdded(player, second)
    end
end

-- 操作玩家数据
function SGameCenter:OnPlayerLoadFinished(uin)
    SWareHouse:CheckOfflineItems(uin)
end

function SGameCenter:OnPlayerRemoved(player)
    -- 下线通知
    if self.CenterRoomId then
        SGameCenter:ToCenter("PlayerRemoved", player.UserId)
        SMatch:OnPlayerRemoved(player)
        STrade:OnPlayerRemoved(player, second)
        SWareHouse:OnPlayerRemoved(player, second)
    end
end

function SGameCenter:IsOnLine()
    return self.CenterRoomId ~= nil
end

function SGameCenter:ToCenter(typ, ...)
    print("Server->Center", typ, ...)
    assert(self.CenterRoomId, "GameCenter not ready")
    send_message({self.CenterRoomId}, typ, ...)
end

-- 构建玩家信息同步给Center，以便后期查询、匹配用
-- 如有更新，可以另加协议通知Center
function SGameCenter:GetPlayerInfo(player)
    return {
        uin = player.UserId,
        name = player.Nickname,
    }
end

---- Center->Server Handler ----
function SGameCenter.CenterHandler:ToClient(uin, msgkey, body)
    print("Center->Client", uin, msgkey, body)
    local msgid = assert(ActorNetProto[msgkey], msgkey)
    SMatch:HandleTeamMessage(msgid, body)
    Network:SendToClient(uin, msgid, body)
end

function SGameCenter.CenterHandler:ToBroadcast(msgkey, body)
    print("Center->Client", msgkey, body)
    local msgid = assert(ActorNetProto[msgkey], msgkey)
    Network:Broadcast(msgid, body)
end

function SGameCenter.CenterHandler:GCLog(time, msg)
    print("GCLog:", time, msg)
end

---- Client->Server Handler ----
function SGameCenter:HandleGCGM(uin, code, body)
    local typ = body.typ
    print("HandleGCGM:" .. tostring(typ))
    if typ == "Stop" then
        SGameCenter:ToCenter("Stop")
    elseif typ == "RegisteLog" then
        SGameCenter:ToCenter("RegisteLog", body.isOpen)
    elseif typ == "ToNewRoom" then
        SMatch:TeleportToNewRoom(uin)
    end
end

-- 获取在线玩家信息
function SGameCenter:GetGCPlayerInfo(uin, code, body)
    local playerInfo = self:GetPlayerInfoByID(body.uin)
    if playerInfo ~= nil then -- 当前服存在
        Network:SendToClient(uin, ActorNetProto.PlayerInfoGCResponse, playerInfo)
    else    -- 当前服不存在，发给中心服
        SGameCenter:ToCenter("GetGCPlayerInfo", uin, body.uin)
    end
end

-- 更新中心服玩家信息
function SGameCenter:UpdateGCPlayerInfo(uin, code, body)
    SGameCenter:ToCenter("UpdateGCPlayerInfo", uin, body)
end

-- h获取玩家信息
function SGameCenter:GetPlayerInfoByID(uin)
    local player = PlayersService:GetPlayerByUserId(uin)
    if player ~= nil then
        return self:GetPlayerInfo(player)
    end
    return nil
end

--server->center
--例如：SGameCenter:ToCenter("xxx", userId, info)

--移动到msserver初始化保证顺序 SGameCenter:Init()

return SGameCenter
