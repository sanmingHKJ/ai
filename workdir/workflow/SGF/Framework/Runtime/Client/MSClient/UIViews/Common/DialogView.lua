--brief 对话框视图
--Date:2025年6月19日
--Author:郝文丽
--Copyright (c) 2025 迷你创想. All rights reserved.
local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local UIView = GFScript("UIModule.UIView")
local UIDefines = GFScript("UIModule.UIDefines")
local UIUtils = GFScript("UIModule.UIUtils")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local DialogView = Class.New("DialogView", UIView)

DialogView.UIRoot = "Common.DialogView"

DialogView.Style = UIDefines.EViewStyle.Master

--初始化控件
function DialogView:InitControls()
    self.btnClose = self:FindButton("btnClose")
    self.txtTitle = self:FindText("txtTitle")

    self.content = self:FindControl("content")
end

--销毁控件
function DialogView:FinitControls()

end

--初始化事件
function DialogView:InitEvents()
    --监听关闭按钮点击事件
    self.btnClose:ClickedCallback(function()
        self:Close()
    end)
end

function DialogView:FinitEvents()
    self.btnClose:ClickedCallback(nil)
end

--进入
function DialogView:Enter()
    
end

--离开
function DialogView:Leave()
    
end

--设置标题
function DialogView:SetTitle(title)
    self.txtTitle:SetText(title)
end

return DialogView
