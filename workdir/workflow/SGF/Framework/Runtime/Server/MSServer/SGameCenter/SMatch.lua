local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local MapId = tonumber(game.RunService:GetCurMapOwid())
local SGameCenter = nil
local SMatch = {}

function SMatch:Init(_SGameCenter)
    local Match = self
    SGameCenter = _SGameCenter

    -- 队伍数据
    self.teamsMap = {}

    Network:ServerSetCallback(ActorNetProto.RequestGCMatch, self.OnMatchMessage, self)
    Network:ServerSetCallback(ActorNetProto.RequestGCTeam, self.OnTeamMessage, self)

    -- 进入匹配战场
    function SGameCenter.CenterHandler:MatchEnterGame(uin, gameKey, players)
        print("MatchEnterGame", " uin:", uin, " gameKey:", gameKey, " MapId:", MapId)
        game.CloudService:ReserveServer(uin, tonumber(MapId), gameKey, players, players)
    end

    -- 传送到队长房间
    function SGameCenter.CenterHandler:TeleportToServer(uin, teleportData)
        if teleportData == nil or teleportData.serverId == nil then
            return false
        end
        local serverId = game.CloudService:GetServerID()
        if serverId == teleportData.serverId then
            if SGameCenter:IsOnLine() then
                SGameCenter:ToCenter("TeamFromClient", uin, { typ="TeleportSuccess", status=true })
            end
            return true --在同一个房间不用传送
        end
        local status = game.CloudService:TeleportToServer(teleportData.serverId, uin, {})
        if SGameCenter:IsOnLine() then
            SGameCenter:ToCenter("TeamFromClient", uin, { typ="TeleportSuccess", status=status })
        end
        return status
    end
end

-- 传送到新房间或指定房间
function SMatch:TeleportToNewRoom(uin)
    -- local status = game.CloudService:TeleportToMap(MapId, uin, {})
    local status = game.CloudService:ReserveServer(uin, MapId, string.format("RoomKey%d_%d", uin, os.time()))
    -- if SGameCenter:IsOnLine() then
    --     SGameCenter:ToCenter("MatchFromClient", uin, { typ="TeleportToNewRoom", status=status })
    -- end
    print(string.format("TeleportToNewRoom:%d %s", uin, tostring(status)))
    return status
end

function SMatch:OnPlayerAdded(player, second)
    if not second then
        -- 首次上线处理
    end
end

-- 玩家移除
function SMatch:OnPlayerRemoved(player)
    -- 检测是否需要清理队伍信息
    local uin = player.UserId
    local team = self:GetTeamByPlayerID(uin)
    if (team ~= nil) and (team.leader == uin) then
        local isClear = true
        for id, info in pairs(team.players) do
            if uin ~= id then
                isClear = false
                break
            end
        end
        if isClear then
            self.teamsMap[team.tid] = nil
        end
    end
end

-- 记录队伍信息
function SMatch:RecordTeamInfo(teamData)
    if teamData ~= nil then
        self.teamsMap[teamData.tid] = teamData
    end
end

function SMatch:GetTeamByTeamID(id)
    return self.teamsMap[id]
end

function SMatch:GetTeamByPlayerID(uin)
    for id, team in pairs(self.teamsMap) do
        if team.players[uin] ~= nil then
            return team
        end
    end
    return nil
end

-- 处理队伍数据
function SMatch:HandleTeamMessage(msgid, body)
    if ActorNetProto.AcceptInvitationRespon == msgid then
        -- 接受邀请 队伍:body.team 接受者id:body.uin 邀请者id:body.friendUin
        self:RecordTeamInfo(body.team)
    elseif ActorNetProto.KickRespon == msgid then
        -- 踢人 队伍(被踢者为nil):body.team  踢人者id:body.uin 被踢者id:body.friendUin
        self:RecordTeamInfo(body.team)
    elseif ActorNetProto.LeaveTeamRespon == msgid then
        -- 离队 队伍(离队者为nil):body.team 离队者id:body.uin
        -- 可能队伍不存在了 玩家离队时是队长则清理队伍信息
        self:RecordTeamInfo(body.team)
    elseif ActorNetProto.TransferLeaderRespon == msgid then
        -- 转移队长 队伍:body.team 老队长id:body.uin 新队长id:body.friendUin
        self:RecordTeamInfo(body.team)
    elseif ActorNetProto.TeamInfoSyncRespon == msgid then
        -- 同步队伍信息 队伍:body.team
        self:RecordTeamInfo(body.team)
    end
    print("HandleTeamMessage:" .. tostring(msgid))
end

-- 客户端至Center的消息，透传一下
function SMatch:OnMatchMessage(uin, code, body)
    if SGameCenter:IsOnLine() then
        SGameCenter:ToCenter("MatchFromClient", uin, body)
    else
        print("OnMatchMessage Ban")
    end
end

function SMatch:OnTeamMessage(uin, code, body)
    if SGameCenter:IsOnLine() then
        SGameCenter:ToCenter("TeamFromClient", uin, body)
    else
        -- 中心服不可用时
        print("OnTeamMessage Ban")
        if body.typ == "RequestTeamInfo" then
            SGameCenter.CenterHandler:ToClient(uin, "RequestTeamInfo", {})
        end
    end
end

return SMatch