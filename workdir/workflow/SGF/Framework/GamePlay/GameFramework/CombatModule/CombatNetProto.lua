--消息类型
local CombatNetProto = 
{
    ResponseTakeDamage = 2001,--收到伤害
    ResponseKill = 2002,--收到击杀

    ResponseReceiveHeal = 2003,--收到治疗
    ResponseReceiveAnger = 2004,--收到恢复能量
}
--消息对应的名称
local Names = {}

--初始化消息名称
local index = 0
for k, v in pairs(CombatNetProto) do
    Names[v] = k
end

CombatNetProto.Names = Names

return CombatNetProto