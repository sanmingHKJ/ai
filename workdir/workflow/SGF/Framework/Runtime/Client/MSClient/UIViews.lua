_G.GFViews = {}
_G.ViewScript = function(scriptName)
    if _G.GFViews[scriptName] then
        return _G.GFViews[scriptName]
    end
    --通过.号分割scriptName
    local function split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    local scriptNameList = split(scriptName, ".")
    local module = script.Parent.UIViews
    if module then
        for _, name in ipairs(scriptNameList) do
            module = module[name]
            if module == nil then
                print("Can not find scriptNode : "..scriptName)
                break
            end
        end
    end
    if module then
        local m = require(module)
        _G.GFViews[scriptName] = m
        return m
    end
end


local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local UIManager = GFScript("UIModule.UIManager")
local UIView = GFScript("UIModule.UIView")
local UIWidget = GFScript("UIModule.UIWidget")
local UIDefines = GFScript("UIModule.UIDefines")
local UISettings = GFScript("UIModule.UISettings")
local UIWidgetCreator = GFScript("UIModule.UIWidgetCreator")


UISettings:SetRedDotSprite("UI/Common/Img/Icon_New.png")
UISettings:SetGenericWhiteSprite("SimpleUI/Sprites/Shapes/Square/Square.png")

--注册layer
UIManager:AddLayer(UIDefines.EViewLayer.Background, Utils:GetUINode("UI_Background"))
UIManager:AddLayer(UIDefines.EViewLayer.Normal, Utils:GetUINode("UI_Normal"))
UIManager:AddLayer(UIDefines.EViewLayer.Popup, Utils:GetUINode("UI_Popup"))
UIManager:AddLayer(UIDefines.EViewLayer.Dialog, Utils:GetUINode("UI_Dialog"))
UIManager:AddLayer(UIDefines.EViewLayer.Top, Utils:GetUINode("UI_Top"))

UIManager:SetTemplateRootNode(Utils:GetUINode("UI_Template"))
UIManager:SetNodePoolNode(Utils:GetUINode("UI_NodePool"))
UIManager:SetItemTemplate(Utils:GetUINode("UI_Template.temp"))

local UIExtendWidget = Utils:GetMainStorageNode("Scripts.GamePlay.UIExtendModule.UIExtendWidget")
if UIExtendWidget then
    UIWidgetCreator:LoadWidgetClass(UIView, UIExtendWidget)
    UIWidgetCreator:LoadWidgetClass(UIWidget, UIExtendWidget)
end


UIManager:LoadViewClass(script)


--打开背包主界面
-- UIManager:OpenView("BagMainView")