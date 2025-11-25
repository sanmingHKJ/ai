local Math = GFScript("CoreModule.Math")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local LootItem = GFScript("PetModule.PetSkill.PetSkillEvent.LootItem")

local LootCurrency = LootItem.Extend("LootCurrency")

function LootCurrency:Loot()
    if not self.player then
        return false
    end
    local reason = "PetLootCurrencySkill"
    --掉落货币
    local minCoin = self:GetDerivedValue("minCoin")
    local maxCoin = self:GetDerivedValue("maxCoin")
    if minCoin and maxCoin then
        local coin = math.floor(Math:Random(minCoin, maxCoin))  
        if coin > 0 then
            XPlants.PlayerStatus:AddCoin(self.player.bindObj, coin, reason)
            if self.petActor then
                local pet = self.petActor:GetPet()
                if pet then
                    local petName = pet.data.name
                    local tips = petName.." 偷到了“"..tostring(coin).."”硬币"
                    self.petActor:ShowTip(tips)
                end
            end
        end
    end
end

return LootCurrency