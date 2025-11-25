--消息类型
local StatNetProto = 
{
    RequestX = 4001,

    ResponseHealth = 4101,
    ResponseMana = 4102,
    ResponseAnger = 4103,
}
--消息对应的名称
local Names = {}

--初始化消息名称
local index = 0
for k, v in pairs(StatNetProto) do
    Names[v] = k
end

StatNetProto.Names = Names

return StatNetProto