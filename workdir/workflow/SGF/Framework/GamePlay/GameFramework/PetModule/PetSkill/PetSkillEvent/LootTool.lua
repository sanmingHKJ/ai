local Math = GFScript("CoreModule.Math")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local PetKismet = GFScript("PetModule.PetKismet")
local LootItem = GFScript("PetModule.PetSkill.PetSkillEvent.LootItem")

local LootTool = LootItem.Extend("LootTool")

function LootTool:Loot()
    if not self.player then
        return false
    end
    local reason = "PetLootToolSkill"
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
        else
            PetKismet:PetLootTool(self.petActor, self.player, chance / denominator)
        end
    end
end

return LootTool