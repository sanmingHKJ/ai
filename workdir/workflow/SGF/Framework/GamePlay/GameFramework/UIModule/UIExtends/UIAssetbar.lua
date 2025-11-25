-- 说明:资产条控件
-- 日期:2025年4月24日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperSlotBase = GFScript("UIModule.UIWidget.SuperSlotBase")
local InventoryKismet = GFScript("InventoryModule.InventoryKismet")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local ActorManager = GFScript("ActorModule.ActorManager")
local UIAssetbar = UIClass.New("UIAssetbar", SuperSlotBase)

function UIAssetbar:Constructor()
    self.currencyId = 1
end

function UIAssetbar:Destructor()
    self:FinitEvent()
    
end

function UIAssetbar:Init(bindObj)
    if not SuperSlotBase.Init(self, bindObj) then
        return false
    end

    self.actor = ActorManager:GetLocalPlayer()

    --绑定
    self:AddBind("icon", "Icon", "icon", function(control, dataValue)
        local id = self:GetData()
        local currencyConfig = ConfigManager:GetConfig("item_tbcurrency", id)
        if currencyConfig and currencyConfig.icon then
            control.Icon = UIUtils:GetIconPath(currencyConfig.icon)
        end
    end)
    self:AddBind("amount", "Title", "amount", function(control, dataValue)
        local id = self:GetData()
        local localPlayer = ActorManager:GetLocalPlayer()
        if localPlayer then
            local currency = localPlayer.InventoryComponent:CountItemByTid(id) or 0
            control.Title = UIUtils:FormatCurrency(currency)
        end
    end)

    return true
end

--初始化事件
function UIAssetbar:InitEvent()
    if not self.actor then
        return
    end
    
    self.currencyChangedEvent = self.actor:OnClientEvent("CurrencyChanged", function(currencyId, oldValue, newValue)
        local currencyTid = InventoryKismet:GetCurrencyIdBySubType(currencyId)
        if currencyTid and self.currencyId == currencyTid then
            self:SetData(currencyTid)
        end
    end)
end

--销毁事件
function UIAssetbar:FinitEvent()
    if not self.actor then
        return
    end

    if self.currencyChangedEvent then
        self.actor:RemoveByEventId(self.currencyChangedEvent)
        self.currencyChangedEvent = nil
    end
end

function UIAssetbar:SetData(currencyId)
    self:FinitEvent()
    self:InitEvent()
    UIAssetbar.super.SetData(self, currencyId) 
end

function UIAssetbar:SetCurrencyId(id)
    self.currencyId = id
end

return UIAssetbar
