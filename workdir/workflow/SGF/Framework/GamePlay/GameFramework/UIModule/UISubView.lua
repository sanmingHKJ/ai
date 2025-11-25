-- 说明:UI子视图
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIView = GFScript("UIModule.UIView")

local UISubView = UIClass.New("UISubView", UIView)

function UISubView:Constructor()
    self.parentView = nil
end

function UISubView:Destructor()
    self.parentView = nil
end

function UISubView:SetParentView(parentView)
    self.parentView = parentView
end

function UISubView:GetParentView()
    return self.parentView
end

function UISubView:Enter()
    UISubView.super.Enter(self)
    -- Additional enter logic for UISubView
end

function UISubView:Leave()
    UISubView.super.Leave(self)
    -- Additional leave logic for UISubView
end

function UISubView:Load(sync, callback)
    UISubView.super.Load(self, sync, callback)
end

function UISubView:Unload()
    UISubView.super.Unload(self)
end

function UISubView:Update(dt)
    UISubView.super.Update(self, dt)
    -- Additional update logic for UISubView
end

return UISubView