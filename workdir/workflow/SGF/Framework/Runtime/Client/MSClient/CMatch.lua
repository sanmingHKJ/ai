local Network = GFScript("NetworkModule.Network")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local ActorManager = GFScript("ActorModule.ActorManager")

local CMatch = {}
local UIEvent = {
    TeamInvitation      = "TeamInvitation",
    TeamAccept          = "TeamAccept",
    TeamReject          = "TeamReject",
    TeamFriendChanged   = "TeamFriendChanged",
    TeamInfoChanged     = "TeamInfoChanged",
    TeamMessage         = "TeamMessage",
    TeamList            = "TeamList",
    PlayerLeaveTeam     = "PlayerLeaveTeam",
}
CMatch.UIEvent = UIEvent  

CMatch.LastSessionID = 0

local AllCallBack = {}
CMatch.AllCallBack = AllCallBack

local MatchServerHandler = {}

function CMatch:Init()
    MS.NetworkHelper:RegisterNetObj(self)
    MS.ObserverHelper:RegisterObserver(self)

    for k, v in pairs(MatchServerHandler) do
        local msgid = assert(ActorNetProto[k], k)
        Network:ClientSetCallback(msgid, v, self)
    end
end

function CMatch:ToCenter(opt, typ, pack, callBack)
    local sid = self.LastSessionID + 1
    self.LastSessionID = sid
    pack = pack or {}
    pack.typ = typ
    pack.sid = sid
    if callBack then
        AllCallBack[sid] = {
            time = os.time,
            typ = typ,
            func = callBack,
        }
    end
    Network:SendToServer(opt, pack)
end

function MatchServerHandler:ResponseGCMatch(code, args)
    local callBack = AllCallBack[args.sid]
    print("ResponseGCMatch", args.sid, args.ok, args.msg, callBack)
    if callBack then
        callBack.func(args.ok, args.msg)
        AllCallBack[args.sid] = nil
    end
end

-----------------------------GM相关请求-------------------------------------------
-- 停止中心服
function CMatch:RequestStopGC()
    Network:SendToServer(ActorNetProto.RequestGCGM, { typ="Stop" })
end

-- 注册中心服日志
function CMatch:RequestRegisteGCLog(isOpen)
    Network:SendToServer(ActorNetProto.RequestGCGM, { typ="RegisteLog", isOpen=isOpen })
end

-- 传送到新房间
function CMatch:RequestToNewRoom()
    Network:SendToServer(ActorNetProto.RequestGCGM, { typ="ToNewRoom" })
end
-----------------------------Match相关请求-------------------------------------------
-- 请求玩家信息
function CMatch:RequestGCPlayerInfo(uin)
    Network:SendToServer(ActorNetProto.RequestGCPlayerInfo, { uin = uin })
end

-- 请求更新玩家信息
function CMatch:RequestUpdatePlayerInfo(infos)
    Network:SendToServer(ActorNetProto.UpdateGCPlayerInfo, infos)
end

-- 单人匹配
function CMatch:StartSingleMatch()
    self:ToCenter(ActorNetProto.RequestGCMatch, "StartSingleMatch", { cls = "1v1" }, 
        function(status, msg)
            -- 开始匹配
            if status then
            else
                local code = tonumber(msg)
                -- 1 正在匹配中 2 匹配类型错误 3 开始匹配失败
                print("StartSingleMatch:", code)
            end
        end)
end

-- 队伍匹配 返回->ResponseGCMatch
function CMatch:StartTeamMatch()
    self:ToCenter(ActorNetProto.RequestGCMatch, "StartTeamMatch", {}, 
        function(status, msg)
            -- 开始匹配
            if status then
            else
                local code = tonumber(msg)
                -- 1 正在匹配中 2 匹配类型错误 3 开始匹配失败
                print("StartTeamMatch:", code)
            end
        end)
end

-- 取消匹配（单人匹配及其它类型的匹配，当前最多进行一个匹配）
function CMatch:CancelMatch()
    self:ToCenter(ActorNetProto.RequestGCMatch, "CancelMatch", {}, function(status, msg) end)
end
-----------------------------Match相关返回-------------------------------------------
-- 开始匹配通知
function MatchServerHandler:StartMatchRespon(code, body)
    print("StartMatchRespon")
end

-- 停止匹配通知
function MatchServerHandler:StopMatchRespon(code, body)
    print("StopMatchRespon", tostring(body.reason))
end

--取到玩家信息
-- info: PlayerInfo
function MatchServerHandler:PlayerInfoGCResponse(code, body)
    if playerInfo.error ~= nil then
        -- 获取失败
    else
        -- body.uin body.name
    end
end

--中心服重连（需清除所有队伍、匹配等信息）
function MatchServerHandler:DisconnectGCResponse(code, body)
    print("MatchServerHandler:DisconnectGCResponse", body.reason)
end

-----------------------------Team相关请求-------------------------------------------
-- 请求已存在的队伍列表 并返回 TeamListRespon
function CMatch:RequestTeamList()
    self:ToCenter(ActorNetProto.RequestGCTeam, "RequestTeamList", {}, function(status, msg) end)
end

-- 请求队伍信息 返回->TeamInfoSyncRespon
function CMatch:RequestTeamInfo()
    self:ToCenter(ActorNetProto.RequestGCTeam, "RequestTeamInfo", {})
end

-- 请求设置队伍状态 返回->TeamInfoSyncRespon
function CMatch:SetTeamReady(isReady)
    -- 只有队长设置有效 isReady为true时会锁定玩家操作
    self:ToCenter(ActorNetProto.RequestGCTeam, "SetTeamReady", { status=isReady }, 
        function(status, msg)
            if status then
            else
                local code = tonumber(msg)
                -- 1 没有队伍 2 状态设置失败
                print("SetTeamReady:", code)
            end
        end)
end

-- 请求好友的状态 返回->ResponseGCMatch 并直连返回 InvitableFriendsListRespon
function CMatch:RequestInvitableFriendsList(friendUinList)
    self:ToCenter(ActorNetProto.RequestGCTeam, "RequestInvitableFriendsList", { friendUinList=friendUinList }, 
        function(status, msg) end)
end

-- 发送组队邀请 返回->ResponseGCMatch 并直连返回 InvitationRespon
function CMatch:SendInvitation(friendUin)
    -- 更新中心服当前玩家数据
    self:ToCenter(ActorNetProto.RequestGCTeam, "SendInvitation", { friendUin=friendUin, cls="tps" },
        function(status, msg)
            -- 邀请者返回
            if status then
            else
                local code = tonumber(msg)
                -- 1 不能邀请自己 2 好友不在线 3 邀请发送过快 4 创建队伍失败 5 不能邀请同队伍的人 6 被邀请者队伍就绪
                print("SendInvitation:", code)
            end
        end)
end

-- 发送接受组队邀请 返回->ResponseGCMatch 并直连返回 AcceptInvitationRespon
function CMatch:AcceptInvitation(friendUin)
    self:ToCenter(ActorNetProto.RequestGCTeam, "AcceptInvitation", { friendUin=friendUin }, 
        function(status, msg)
            -- 接受者返回
            if status then
            else
                local code = tonumber(msg)
                -- 1 不能接受自己邀请 2 未被邀请 3 邀请人不在线 4 邀请人没有队伍 5 队伍不能加入了 6 离队失败
                print("AcceptInvitation:", code)
            end
        end)
end

-- 发送拒绝组队邀请 返回->ResponseGCMatch 并直连返回 RejectInvitationRespon
function CMatch:RejectInvitation(friendUin)
    self:ToCenter(ActorNetProto.RequestGCTeam, "RejectInvitation", { friendUin=friendUin }, 
        function(status, msg)
            -- 拒绝者返回
            if status then
            else
                local code = tonumber(msg)
                -- 1 不能拒绝自己邀请 2 邀请者不在线 3 邀请者没队伍
                print("RejectInvitation:", code)
            end
        end)
end

-- 踢人 返回->ResponseGCMatch 并直连返回 KickRespon
function CMatch:Kick(friendUin)
    self:ToCenter(ActorNetProto.RequestGCTeam, "Kick", { friendUin=friendUin }, 
        function(status, msg)
            -- 踢人者返回
            if status then
            else
                local code = tonumber(msg)
                -- 1 不能踢自己 2 踢人者没有队伍 3 踢人失败
                print("Kick:", code)
            end
        end)
end

-- 离队 返回->ResponseGCMatch 并直连返回 LeaveTeamRespon
function CMatch:LeaveTeam()
    self:ToCenter(ActorNetProto.RequestGCTeam, "LeaveTeam", {}, function(status, msg) end)
end

-- 转移队长 返回->ResponseGCMatch 并直连返回 TransferLeaderRespon
function CMatch:TransferLeader(friendUin)
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer ~= nil and localPlayer:GetPlayerId() ~= friendUin then
        self:ToCenter(ActorNetProto.RequestGCTeam, "TransferLeader", { friendUin=friendUin }, 
            function(status, msg)
                -- 转移队长
                if status then
                else
                    local code = tonumber(msg)
                    -- 1 不能转给自己 2 不能转给离线玩家 3 自己没有队伍 4 转移队长失败
                    print("TransferLeader:", code)
                end
            end)
    else
        print("CMatch:TransferLeader Fail ", friendUin)
    end
end

-- 发送队伍消息 返回->ResponseGCMatch 并广播返回 TeamMessageRespon
function CMatch:SendTeamMessage(msg, utc)
    self:ToCenter(ActorNetProto.RequestGCTeam, "SendTeamMessage", { msg=msg, utc=utc }, 
        function(status, msg)
            -- 发消息
            if status then
            else
                local code = tonumber(msg)
                -- 1 自己没有队伍
                print("SendTeamMessage:", code)
            end
        end)
end

-- 队伍是否满员
function CMatch:IsTeamFull()
    local teamInfo = self.teamInfo
    if teamInfo == nil or teamInfo.players == nil then
        return false
    end
    local count = 0
    for uin, player in pairs(teamInfo.players) do
        count = count + 1
    end
    return count >= teamInfo.teamSize
end

-----------------------------Team相关返回-------------------------------------------
-- 所有房间在线人数
function MatchServerHandler:AllRoomPlayerCountRespon(code, body)
    print("AllRoomPlayerCountRespon:", tostring(body.count))
end

-- 队伍列表
function MatchServerHandler:TeamListRespon(code, body)
    -- 广播队伍列表
    self:BroadcastObservers(UIEvent.TeamList, body.teamArr)
end

-- 请求好友列表 { isOnline,isInvited,teamID,isReady }
function MatchServerHandler:InvitableFriendsListRespon(code, body)
    self.invitableFriendsList = body.friendList
    self:BroadcastObservers(UIEvent.TeamFriendChanged, self.invitableFriendsList)
end

-- 更新好友状态 { isOnline,isInvited,teamID,isReady }
function MatchServerHandler:InvitableFriendInfoRespon(code, body)
    local friendUin = body.friendUin
    if self.invitableFriendsList == nil then
        self.invitableFriendsList = {}
    end
    self.invitableFriendsList[friendUin] = body.invitableFriendInfo
    self:BroadcastObservers(UIEvent.TeamFriendChanged, self.invitableFriendsList)
end

-- 同步队伍
function MatchServerHandler:TeamInfoSyncRespon(code, body)
    self.teamInfo = body.team or {}
    self:BroadcastObservers(UIEvent.TeamInfoChanged, self.teamInfo)
end

-- 被邀请者通知
function MatchServerHandler:InvitationRespon(code, body)
    --队伍类型
    local cls = body.cls
    --邀请人信息
    local friendUin = body.friendUin
    local friendName = body.friendName

    print("InvitationRespon:", friendUin)
    self:BroadcastObservers(UIEvent.TeamInvitation, friendUin, friendName, cls)
end

-- 广播接受邀请
function MatchServerHandler:AcceptInvitationRespon(code, body)
    self.teamInfo = body.team
    self:BroadcastObservers(UIEvent.TeamInfoChanged, self.teamInfo)

    local uin = body.uin -- 接受邀请者id
    local friendUin = body.friendUin --发送邀请者id
    print("AcceptInvitationRespon:", uin, friendUin)
    self:BroadcastObservers(UIEvent.TeamAccept, uin, friendUin)
end

-- 通知邀请者被拒绝了
function MatchServerHandler:RejectInvitationRespon(code, body)
    local friendUin = body.friendUin
    local friendName = body.friendName
    print("RejectInvitationRespon:", friendUin)
    self:BroadcastObservers(UIEvent.TeamReject, friendUin, friendName)
end

-- 被踢通知
function MatchServerHandler:KickRespon(code, body)
    local uin = body.uin -- 踢人者id
    local name = body.name
    local friendUin = body.friendUin -- 被踢者id
    local friendName = body.friendName

    local teamInfo = body.team
    if teamInfo == nil then
        -- 被踢者
        self.teamInfo = {}
    else
        -- 其他成员
        self.teamInfo = teamInfo
    end
    self:BroadcastObservers(UIEvent.TeamInfoChanged, self.teamInfo)
    print("KickRespon:", friendUin)
end

-- 离队通知
function MatchServerHandler:LeaveTeamRespon(code, body)
    local uin = body.uin -- 离队者

    local teamInfo = body.team
    if teamInfo == nil then
        -- 离队者
        self.teamInfo = {}
    else
        -- 其他成员
        local name = body.name -- 离队者名称
        self.teamInfo = teamInfo
    end

    self:BroadcastObservers(UIEvent.TeamInfoChanged, self.teamInfo)
    self:BroadcastObservers(UIEvent.PlayerLeaveTeam, uin)
    print("LeaveTeamRespon:", uin)
end

-- 通知成员转移队长
function MatchServerHandler:TransferLeaderRespon(code, body)
    self.teamInfo = body.team

    local uin = body.uin
    local friendUin = body.friendUin

    self:BroadcastObservers(UIEvent.TeamInfoChanged, self.teamInfo)
end

-- 队伍消息
function MatchServerHandler:TeamMessageRespon(code, body)
    local senderID = body.sender
    local msg = body.msg
    local etc = body.etc
    -- 广播队伍消息
    self:BroadcastObservers(UIEvent.TeamMessage, senderID, msg, etc)
end

--创建队伍例子：

--更多接口见中心服GMatch脚本的接口注释

CMatch:Init()

return CMatch