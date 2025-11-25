-- 说明:角色Gm指令
-- 日期:2025年7月8日
-- 支持:揭育龙
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Commands = {}

Commands.category = "Pet"
Commands.order = 0

--服务端指令
Commands.commands = {
    {
        name = "pet_description",
        example = "pet_description",
        description = "打印宠物信息",
        callback = function(player, ...)
            local resultStr = player.PetComponent:GetDescription()
            player:Say("宠物信息：\n" .. resultStr)
        end
    },
    {
        name = "pet_add",
        example = "pet_add 1001",
        description = "添加宠物,tid",
        callback = function(player, tid)
            player.PetComponent:AddPetByTid(tid)
        end
        
    },
    {
        name = "pet_remove",
        example = "pet_remove 1001",
        description = "移除宠物,tid",
        callback = function(player, tid)
            player.PetComponent:RemovePetByTid(tid)
        end
    },
    {
        name = "pet_summon",
        example = "pet_summon 1001",
        description = "召唤宠物,tid",
        callback = function(player, tid)
            player.PetComponent:SummonPetByTid(tid)
        end
        
    },

}


--客户端指令
Commands.clientCommands = {
    {
        name = "client_pet_description",
        example = "client_pet_description",
        description = "打印宠物信息",
        callback = function(player, ...)
            local resultStr = player.PetComponent:GetDescription()
            player:Say("宠物信息：\n" .. resultStr)
        end
    }
}

return Commands
