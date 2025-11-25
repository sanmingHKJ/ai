-- 说明:角色Gm指令
-- 日期:2025年7月8日
-- 支持:揭育龙
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Commands = {}

Commands.category = "Actor"
Commands.order = 0

--服务端指令
Commands.commands = {
    {
        name = "save_all",
        example = "save_all",
        description = "保存所有数据",
        callback = function(player)
            player.DataComponent:SaveAll(function(ret)
                if ret then
                    player:Say("保存成功")
                else
                    player:Say("保存失败")
                end
            end)
        end
        
    },
    {
        name = "summon",
        example = "summon 3001",
        description = "召唤分身,tid",
        callback = function(player, tid)
            player.SummonComponent:Summon(tid)
        end
        
    },

}


--客户端指令
Commands.clientCommands = {
    {
        name = "client_print_equip_description",
        example = "client_print_equip_description",
        description = "打印装备信息",
        callback = function(player, ...)
            local resultStr = player.EquipmentComponent:GetDescription()
            player:Say("装备信息：\n" .. resultStr)
        end
    }
}

return Commands
