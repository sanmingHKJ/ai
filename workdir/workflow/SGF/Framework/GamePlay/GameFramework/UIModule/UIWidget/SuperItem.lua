-- 说明:滚动控件子项
-- 日期:2025年2月13日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperItem = UIClass.New("SuperItem", UIWidget)

function SuperItem:Constructor()
    self.data = nil
    self.dataIndex = 0
end

function SuperItem:Destructor()
    self.data = nil
    self.dataIndex = 0
end

function SuperItem:Init(bindObj, managedBindObj)
    if not SuperItem.super.Init(self, bindObj, managedBindObj) then
        return false
    end
    return true
end

function SuperItem:SetData(data)
    self.data = data
end

function SuperItem:GetData()
    return self.data
end

function SuperItem:SetDataIndex(dataIndex)
    self.dataIndex = dataIndex
end

function SuperItem:GetDataIndex()
    return self.dataIndex
end

return SuperItem
