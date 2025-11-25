local Utils = GFScript("CoreModule.Utils")

local UIWidgetCreator = {}

function UIWidgetCreator:RegisterCreator(target, widgetNode, prefix)
    local typeName = widgetNode.Name
    if not Utils:IsNullOrEmpty(prefix) then
        if Utils:StartWith(typeName, prefix) then
            --移除前缀
            typeName = Utils:RemovePrefix(typeName, prefix)
        end
    end

    local createName = "Create" .. typeName
    local findName = "Find" .. typeName

    if not target[createName] then
        target[createName] = function(target, control)
            local widgetClass = require(widgetNode)
            return target:CreateWidget(widgetClass, control)   
        end
    end

    if not target[findName] then
        target[findName] = function(target, name, parent)
            local widgetClass = require(widgetNode)
            return target:FindWidget(widgetClass, name, parent)
        end
    end
end


--加载视图类
function UIWidgetCreator:LoadWidgetClass(target, rootNode, prefix)
    for _, widgetNode in ipairs(rootNode.Children) do
        if widgetNode.ClassType == 'ModuleScript' then
            self:RegisterCreator(target, widgetNode, prefix)
        end
        self:LoadWidgetClass(target, widgetNode, prefix)
    end
end

function UIWidgetCreator:RegisterAllCreators(target)
    local rootNode = script.Parent.UIWidget
    self:LoadWidgetClass(target, rootNode, "Super")
end

return UIWidgetCreator