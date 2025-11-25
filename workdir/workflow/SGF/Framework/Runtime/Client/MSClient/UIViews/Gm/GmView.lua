local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local SuperGridView = GFScript("UIModule.UIWidget.SuperGridView")
local SuperImage = GFScript("UIModule.UIWidget.SuperImage")
local UIView = GFScript("UIModule.UIView")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Vec3 = GFScript("UIModule.UIMath.Vec3")
local Color = GFScript("UIModule.UIMath.Color")
local UIHelper = GFScript("UIModule.UIHelper")
local UITweenUtils = GFScript("UIModule.UITweenUtils")
local UISettings = GFScript("UIModule.UISettings")
local ActorManager = GFScript("ActorModule.ActorManager")
local RedDotManager = GFScript("UIModule.UIRedDot.RedDotManager")
local UIDefines = GFScript("UIModule.UIDefines")
local UIManager = GFScript("UIModule.UIManager")
local SuperToggle = GFScript("UIModule.UIWidget.SuperToggle")
local Resource = GFScript("CoreModule.Resource")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local UIUtils = GFScript("UIModule.UIUtils")
local Profiler = GFScript("CoreModule.Profiler")
local GmView = Class.New("GmView", UIView)

GmView.UIRoot = "Gm.GmView"

GmView.Style = UIDefines.EViewStyle.FullScreen
GmView.Persistent = true
GmView.CacheSuport = false
--层级
GmView.Layer = UIDefines.EViewLayer.Dialog

GmView.Master = "DialogView"

--当设置主视图
function GmView:OnSetupMasterView(masterView)
    masterView:SetTitle("GM面板")
end

--初始化控件
function GmView:InitControls()
    self.dialog = self:FindImage("dialog")

    self:InitGmPanel()
end

--销毁控件
function GmView:FinitControls()
    if self.categorySV then
        self.categorySV:Destroy()
        self.categorySV = nil
    end

    if self.gmSV then
        self.gmSV:Destroy()
        self.gmSV = nil
    end
end

--初始化事件
function GmView:InitEvents()

end

--初始化gm面板
function GmView:InitGmPanel()

    self.gmCategories = self:FindGridView("gmCategories")
    self.gmList = self:FindGridView("gmList")
    self.input = self:FindInput("input")
    self.btnSend = self:FindButton("btnSend")

    self.gmCategories:SetItemSize(200, 30)
    self.gmCategories:SetItemTemplate(self:FindControl("categoryItem"))
    self.gmCategories:SetLayoutOptions("TopLeft", "Vertical", false)
    self.gmCategories:SetScrollDirection("Vertical")
    self.gmCategories:SetSpacing(0, 10)

    self.gmList:SetItemSize(200, 30)
    self.gmList:SetItemTemplate(self:FindControl("gmItem"))
    self.gmList:SetLayoutOptions("TopLeft", "Vertical", false)
    self.gmList:SetScrollDirection("Vertical")
    self.gmList:SetSpacing(10, 10)
    self.gmList:SetLineCount(3)
    

    self.gmCategories:ItemEnterCallback(function(sv, item)
        item.bindObj.name.Title = item.data

        item:ClickedCallback(function()
            local localPlayer = ActorManager:GetLocalPlayer()
            if localPlayer and localPlayer.GmComponent then
                localPlayer.GmComponent:CmdGetCommandListByCategory(item.data)
            end
        end)
    end)

    self.gmCategories:ItemLeaveCallback(function(sv, item)
        item:ClickedCallback(nil)
    end)

    self.gmList:ItemEnterCallback(function(sv, item)
        item.bindObj.name.Title = item.data.name
        item:ClickedCallback(function()
            self.input:SetText(item.data.example)
        end)
    end)

    self.gmList:ItemLeaveCallback(function(sv, item)
        item:ClickedCallback(nil)
    end)

    self.btnSend:ClickedCallback(function()
        local localPlayer = ActorManager:GetLocalPlayer()
        if localPlayer then
            local cmdText = self.input:GetText()
            if cmdText and cmdText ~= "" then
                localPlayer.GmComponent:SendGmCommand(cmdText)
                --发送成功
                Log:Info("Gm指令: "..cmdText.." 发送成功")
            end
        end
    end)
end
--加载Gm数据
function GmView:LoadGmData()
    local localPlayer = ActorManager:GetLocalPlayer()
    if localPlayer and localPlayer.GmComponent then
        localPlayer.GmComponent:SetListener("ReceiveCategories", function(categories)
            self.gmCategories:SetDataList(categories, "name")
        end)

        localPlayer.GmComponent:SetListener("ReceiveCommandList", function(commands)
            self.gmList:SetDataList(commands, "name")
        end)

        
        localPlayer.GmComponent:CmdGetCategories()
    end
end

--进入  
function GmView:Enter()
    self:LoadGmData()
end

--离开
function GmView:Leave()

end

return GmView
