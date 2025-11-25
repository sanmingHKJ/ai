--消息类型
local AvatarNetProto = 
{
    RequestInputDir = 6001,--同步输入方向
    RequestLocomotionState = 6002,--运动状态枚举
    RequestPoseState = 6003,--姿态枚举
    RequestMoveState = 6004,--运动状态
    ResponsePlayAnim = 6005,--请求播放动作
    ResponseStopAnim = 6006,--请求停止动作
    RequestMoveType = 6007,--请求移动类型
    RequestMoveSpeed = 6008,--请求重置移动速度

    ResponseInputDir = 6101,--响应输入方向
    ResponseLocomotionState = 6102,--运动状态枚举
    ResponsePoseState = 6103,--姿态枚举
    ResponseVelocity = 6104,--速率改变
    ResponseMoveType = 6105,--移动类型
    ResponseVisible = 6106,--可见性
    ResponseMoveSpeed = 6107,--同步重置移动速度

}
--消息对应的名称
local Names = {}

--初始化消息名称
local index = 0
for k, v in pairs(AvatarNetProto) do
    Names[v] = k
end

AvatarNetProto.Names = Names

return AvatarNetProto