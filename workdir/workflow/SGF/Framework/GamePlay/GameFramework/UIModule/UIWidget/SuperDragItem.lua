-- 说明:拖拽控件子项
-- 日期:2025年5月27日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local SuperImage = GFScript("UIModule.UIWidget.SuperImage")
local SuperDragItem = UIClass.New("SuperDragItem", SuperImage)

function SuperDragItem:Constructor()
    self.data = nil
    self.dragBeginPos = nil
    self.dragEndPos = nil
    self.touchPos = Vec2.New(0, 0)
end

function SuperDragItem:Destructor()
    self.data = nil
    self.dragBeginPos = nil
    self.dragEndPos = nil
end

function SuperDragItem:Init(bindObj, managedBindObj)
    if not SuperDragItem.super.Init(self, bindObj, managedBindObj) then
        return false
    end
    return true
end

function SuperDragItem:SetData(data)
    self.data = data
end

function SuperDragItem:GetData()
    return self.data
end

function SuperDragItem:SetTouchPos(touchPos)
    self.touchPos = touchPos
    local dragItemSize = self:GetSize()
    self:SetScreenPosition(self.touchPos - Vec2.New(dragItemSize.x / 2, dragItemSize.y / 2))
end

function SuperDragItem:GetTouchPos()
    return self.touchPos
end

return SuperDragItem
