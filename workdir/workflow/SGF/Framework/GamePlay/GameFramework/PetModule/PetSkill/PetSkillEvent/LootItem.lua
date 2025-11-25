local Math = GFScript("CoreModule.Math")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local PetSkillEvent = GFScript("PetModule.PetSkill.PetSkillEvent")

local LootItem = PetSkillEvent.Extend("LootItem")

function LootItem:Execute()   
    LootItem.super.Execute(self)

    if self.skillEventData.moveToTarget then
        --查找一个随机玩家
        local players = {}
        for _, player in pairs(ActorManager.serverPlayers) do
            if player ~= self.player then
                table.insert(players, player)
            end
        end
        if #players == 0 then
            self:Loot()
            return
        end
        local player = players[Math:Random(1, #players)]
        if not player then
            self:Loot()
            return
        end
        local backupCollideGroup = self.petActor:GetCollideGroup()
        --暂停AI
        self.petActor.AIComponent:SetAIEnabled(false)
        --关掉碰撞
        self.petActor:SetCollideGroup(ActorDefines.CollideGroup.Soul)

        --移动到玩家
        if not self.petActor.__lootItem_orginPos then
            self.petActor.__lootItem_orginPos = self.petActor:GetPosition():Clone()
        end
        self.petActor:MoveToTarget(player, function()
            self:Loot()
            self.petActor:MoveTo(self.petActor.__lootItem_orginPos, function()
                self.petActor.AIComponent:SetAIEnabled(true)
                self.petActor:SetCollideGroup(backupCollideGroup)
                self.petActor.__lootItem_orginPos = nil
            end, self.skillEventData.errorDistance or 150)
        end, self.skillEventData.errorDistance or 150)
    else
        self:Loot()
    end
end

function LootItem:Loot()
    if not self.player then
        return false
    end
    local reason = "PetLootItemSkill"
    local chance = self:IsNullValue("chance") and 100 or self:GetDerivedValue("chance")
    --概率分母
    local denominator = self.skillEventData.denominator or 100
    if chance then
        if self.skillEventData.items then
            local item = Math:RandomByWeight(self.skillEventData.items)
            if item then
                XPlants.Backpack:AddItemByItemId(self.player.bindObj, item.itemId, 1, reason)

                if self.petActor then
                    local pet = self.petActor:GetPet()
                    if pet then
                        local itemDefine = XPlants.Item:GetItemDefine(item.itemId)
                        if itemDefine then
                            local itemName = itemDefine.name
                            local tips = pet.data.name.." 帮你找到了一个“"..tostring(itemName).."”"
                            self.petActor:ShowTip(tips)
                        end
                    end
                end
            end
        end
    end
end

return LootItem