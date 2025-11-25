-- 说明:物品槽位控件
-- 日期:2025年4月24日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperSlotBase = GFScript("UIModule.UIWidget.SuperSlotBase")
local UIUtils = GFScript("UIModule.UIUtils")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")

local UIBagItemSlot = UIClass.New("UIBagItemSlot", SuperSlotBase)

function UIBagItemSlot:Constructor()
    
end

function UIBagItemSlot:Destructor()
    
end

function UIBagItemSlot:Init(bindObj)
    if not SuperSlotBase.Init(self, bindObj) then
        return false
    end


    self:AddBinds({
        {"icon", "Icon", "icon", function(control, dataValue, item)
            if item then
                control.Icon = UIUtils:GetIconPath(item.data.icon)
            else             
                control.Icon = ""
            end
        end},
        {"name", "Title", "name", function(control, dataValue, item)
            if item then
                control.Title = item.data.name
            else
                control.Title = ""
            end
        end},
        {"lv", "Title", "lv", function(control, dataValue, item)
            if item then
                control.Title = "+"..tostring(item.level)
            else
                control.Title = ""
            end
        end},
        {"txtStack", "Title", "name", function(control, dataValue, item)
            if item then
                control.Title = tostring(item.stack)
            else
                control.Title = ""
            end
        end},
        {"bg", "Icon", "icon", function(control, dataValue, item)
            control.Icon = "sandboxId://UI/Common/Bg/Bg_Item_SizeM02_Quality_A.png"
        end}
    })

    return true
end

return UIBagItemSlot