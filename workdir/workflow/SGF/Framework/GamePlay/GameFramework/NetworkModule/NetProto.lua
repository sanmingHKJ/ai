--消息类型
local NetProto = 
{
--系统
Error = 1,--错误信息
Say = 2,
Ping = 3,
--RPC协议号定义
RpcNetCode = 13,
SyncNetCode = 14,
RequestNetCode = 15,
ResponseNetCode = 16,



}

return NetProto