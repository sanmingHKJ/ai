--消息类型
local ActorNetProto = 
{
ResponseAddActor = 1001,--添加Actor
ResponseRemoveActor = 1002,--移除Actor
ResponseActor = 1004,--响应Actor
ResponseSelectServer = 1007,--响应Actor
ResponseSetTarget = 1008,--请求选择目标
ResponseMoveBy = 1010,--位移
ResponseEnergy = 1021,--能量
ResponseServerInfo = 1022,--服务器信息
ResponseEnterCombat = 1023,--进入战斗信息
ResponseLeaveCombat = 1024,--进入战斗信息
ResponseActorSay = 1026,--Actor说话
ResponseActorEvent = 1027,--Actor事件
ResponseActorMakeShadow = 1028,--Actor转移
ResponseActorBindObjChanged = 1029,--BindObj改变
ResponseActorShadow = 1030,--创建分身
ResponseActorMakeShadowFinished = 1031,--创造影子完成
ResponseActorRevive = 1032,--复活

--有些Actor在创建的时候由于不在AOI范围内，未能同步，后续监听到同步以后，需要客户端主动发送查询请求
RequestActor = 1003,--请求Actor
ResponseActorState = 1005,--响应Actor状态
RequestSelectServer = 1006,--请求选择服务器
RequestSetTarget = 1009,--请求选择目标
RequestActorSay = 1025, --请求Actor说话

--场景
RequestSceneWeather = 1033,--请求场景天气
ResponseSceneWeather = 1034,--响应场景天气

--中心服
DisconnectGCResponse = 2001, --重连
RequestGCMatch = 2002,    --匹配、组队
ResponseGCMatch = 2003,
RequestGCPlayerInfo = 2004, --其它玩家信息
PlayerInfoGCResponse = 2005,--玩家数据返回
UpdateGCPlayerInfo = 2006,  --上报玩家信息
RequestGCGM = 2008, --gm操作

-- 匹配
StartMatchRespon = 2050, --开始匹配返回
StopMatchRespon = 2051, --停止匹配返回

-- 队伍
RequestGCTeam = 2100, --队伍请求
InvitableFriendsListRespon = 2103, --好友列表信息返回
InvitationRespon = 2104, --邀请成功返回
InvitableFriendInfoRespon = 2105, --好友信息返回
AcceptInvitationRespon = 2106, --接受邀请
RejectInvitationRespon = 2107, --拒绝邀请
TeamInfoSyncRespon = 2108, --同步队伍信息
KickRespon = 2110, --踢人通知
LeaveTeamRespon = 2111, --离队通知
AllRoomPlayerCountRespon = 2112, --所有房间人数
TeamMessageRespon = 2113,   --队伍消息返回
TeamListRespon = 2114,  --队伍列表
TransferLeaderRespon = 2115, --转移队长返回

}
--消息对应的名称
local Names = {}

--初始化消息名称
local index = 0
for k, v in pairs(ActorNetProto) do
    Names[v] = k
end

ActorNetProto.Names = Names

return ActorNetProto