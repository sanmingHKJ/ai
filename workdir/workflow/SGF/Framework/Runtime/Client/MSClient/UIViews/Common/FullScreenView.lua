--brief 全屏视图
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
local FullScreenView = Class.New("FullScreenView", UIView)

FullScreenView.UIRoot = "Common.FullScreenView"

FullScreenView.Style = UIDefines.EViewStyle.Master

--初始化控件
function FullScreenView:InitControls()
    self.btnClose = self:FindButton("btnClose")
    self.txtTitle = self:FindText("txtTitle")

    self.content = self:FindControl("content")
end

--销毁控件
function FullScreenView:FinitControls()

end

--初始化事件
function FullScreenView:InitEvents()
    --监听关闭按钮点击事件
    self.btnClose:ClickedCallback(function()
        if self.closeClickedCallback then
            self.CloseClickedCallback()
        else
            self:Close()
        end
    end)
end

function FullScreenView:FinitEvents()
    self.btnClose:ClickedCallback(nil)
    self.closeClickedCallback = nil
end

--进入
function FullScreenView:Enter()
    
end

--离开
function FullScreenView:Leave()
    
end

--设置标题
function FullScreenView:SetTitle(title)
    self.txtTitle:SetText(title)
end

--设置关闭回调
function FullScreenView:CloseClickedCallback(callback)
    self.closeClickedCallback = callback
end

return FullScreenView
