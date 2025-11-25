-- 说明:UI输入系统
-- 日期:2025年3月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local Color = GFScript("UIModule.UIMath.Color")
local UIView = GFScript("UIModule.UIView")
local UIDefines = GFScript("UIModule.UIDefines")
local UIUtils = GFScript("UIModule.UIUtils")
local UISettings = GFScript("UIModule.UISettings")
local SuperImage = GFScript("UIModule.UIWidget.SuperImage")
local CheckCallback = GFScript("CoreModule.CheckCallback")
local UserInputService = game:GetService("UserInputService")
local MouseService = game:GetService("MouseService")

local UIInputSystem = UIView.Extend("UIInputSystem")

UIInputSystem.Style = UIDefines.EViewStyle.Normal
UIInputSystem.Layer = UIDefines.EViewLayer.Top

UIInputSystem.Persistent = true

function UIInputSystem:Constructor()
    self:InitInputEvent()
end

function UIInputSystem:Destructor()
    self:FinitInputEvent()
end

--初始化控件
function UIInputSystem:InitControls()
    -- local inputCtrl = SandboxNode.New("UIButton")
    -- inputCtrl.Name = "InputSystem"
    -- inputCtrl.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
    -- inputCtrl.ClickPass = true
    -- inputCtrl.Parent = self.rootNode

    -- self.inputWidget = SuperImage.New()
    -- self.inputWidget:Init(inputCtrl)
    -- self.inputWidget:SetSprite(UIUtils:FullSpritePath(UISettings:GetGenericWhiteSprite()))
    -- self.inputWidget:SetPivot(Vector2.New(0, 0))
    -- self.inputWidget:SetFullScreenSize()
    -- self.inputWidget:SetColor(Color.New(0, 0, 0))
    -- self.inputWidget:SetAlpha(0)
    -- self.inputWidget:SetEventEnabled(true)
    -- self.inputWidget:SetEventPass(true)

    
    -- -- inputCtrl.ClickPass = true
    

    -- self.inputWidget:TouchBeginCallback(
    --     function(ctrl, touchPos, touchId)
    --         self.isTouching = true
    --         self:OnTouchStarted(touchPos.x,touchPos.y,touchId)
    --     end
    -- )
    -- self.inputWidget:TouchMoveCallback(
    --     function(ctrl, touchPos, touchId)
    --         self.currentMousePos.x = touchPos.x
    --         self.currentMousePos.y = touchPos.y
    --         self:OnTouchMoved(touchPos.x,touchPos.y,touchId)
    --     end
    -- )
    -- self.inputWidget:TouchEndCallback(
    --     function(ctrl, touchPos, touchId)
    --         self.isTouching = false
    --         self:OnTouchEnded(touchPos.x,touchPos.y,touchId)
    --     end
    -- )
    
end

--初始化
function UIInputSystem:InitInputEvent()
    
    -- 触摸事件相关变量
    self.TouchStartedEvent = nil
    self.TouchEndedEvent = nil
    self.TouchMovedEvent = nil
    self.InputBeganEvent = nil
    self.InputEndedEvent = nil
    self.InputChangedEvent = nil
    
    -- 触摸状态变量
    self.isTouching = false
    self.touchId = nil
    self.touchMoveId = nil
    self.touchMoving = false
    
    -- 触摸位置变量
    self.touchBeginPos = Vec2.zero()
    self.lastTouchPos = Vec2.zero()
    self.currentTouchPos = Vec2.zero()
    self.currentMousePos = Vec2.zero()

    if UserInputService.TouchEnabled then -- 触摸
        self.TouchStartedEvent = UserInputService.TouchStarted:Connect(function(inputObj, gameprocessed)
            -- self.isTouching = true
            -- self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)

        self.TouchMovedEvent = UserInputService.TouchMoved:Connect(function(inputObj, gameprocessed)
            -- if self.isTouching then
            --     self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            -- end
        end)

        self.TouchEndedEvent = UserInputService.TouchEnded:Connect(function(inputObj, gameprocessed)
            -- self.isTouching = false
            -- self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
        end)
    elseif UserInputService.MouseEnabled then -- 鼠标
        self.InputBeganEvent = UserInputService.InputBegan:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                -- self.isTouching = true
                -- self:OnTouchStarted(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
            
            if inputObj.UserInputType == Enum.UserInputType.Keyboard.Value then
                self:OnKeyPressed(inputObj.KeyCode)
            end
        end)
        self.InputChangedEvent = UserInputService.InputChanged:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseWheel.Value then
                self:OnWheel(inputObj.Delta.y)
            end
            -- local IsSight = MouseService:IsSight()
            -- if IsSight then
            --     if self.canSightTouch and (self.touchId == nil) then
            --         self.canSightTouch = false
            --     end
            --     local dx = 0
            --     local dy = 0

            --     self.canSightTouch = false
            --     self:OnTouchMoved(self.currentTouchPos.x + dx, self.currentTouchPos.y + dy,self.touchId)
            -- elseif self.isTouching then
            --     self.currentMousePos.x = inputObj.Position.x
            --     self.currentMousePos.y = inputObj.Position.y
            --     self:OnTouchMoved(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            -- end
        end)
        self.InputEndedEvent = UserInputService.InputEnded:Connect(function(inputObj, gameprocessed)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton2.Value or
                inputObj.UserInputType == Enum.UserInputType.MouseButton3.Value
            then
                -- self.isTouching = false
                -- self:OnTouchEnded(inputObj.Position.x,inputObj.Position.y,inputObj.TouchId)
            end
        end)
    end
end

function UIInputSystem:FinitInputEvent()
    if self.TouchStartedEvent then
        self.TouchStartedEvent:Disconnect()
        self.TouchStartedEvent = nil
    end
    if self.TouchEndedEvent then
        self.TouchEndedEvent:Disconnect()
        self.TouchEndedEvent = nil
    end
    if self.TouchMovedEvent then
        self.TouchMovedEvent:Disconnect()
        self.TouchMovedEvent = nil
    end
    
    if self.InputBeganEvent then
        self.InputBeganEvent:Disconnect()
        self.InputBeganEvent = nil
    end
    if self.InputEndedEvent then
        self.InputEndedEvent:Disconnect()
        self.InputEndedEvent = nil
    end

    if self.InputChangedEvent then
        self.InputChangedEvent:Disconnect()
        self.InputChangedEvent = nil
    end
end

function UIInputSystem:OnTouchStarted(x,y,touchId)
    if self.touchId and self.touchId ~= touchId then
        return
    end
    
    self.touchId = touchId
    self.touchBeginPos.x = x
    self.touchBeginPos.y = y
    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    self.canSightTouch = false

    self:InputBegin(x, y)
end

function UIInputSystem:OnTouchMoved(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end

    self.touchMoving = true
    self.currentTouchPos.x = x
    self.currentTouchPos.y = y
    
    local delta = self.currentTouchPos - self.lastTouchPos

    self:InputMove(delta.x,delta.y)

    self.lastTouchPos.x = x
    self.lastTouchPos.y = y
end

function UIInputSystem:OnTouchEnded(x,y,touchId)
    if self.touchId ~= touchId then
        return
    end
    
    self.touchMoving = false
    self.touchMoveId = nil
    self.touchId = nil

    self:InputEnd(x, y)
end

function UIInputSystem:OnWheel(delta)
    self:InputWheel(delta)
end

function UIInputSystem:InputBegin(x, y)

end

--鼠标移动
function UIInputSystem:InputMove(deltaX, deltaY)

    UILog:Error("InputMove %d %d", deltaX, deltaY)
end


function UIInputSystem:InputEnd(x, y)

end


--鼠标滚轮
function UIInputSystem:InputWheel(delta)

end

function UIInputSystem:OnKeyPressed(key)
    local RunService = game:GetService("RunService")
    if not RunService:IsStudio() then
        return
    end
    local UIManager = GFScript("UIModule.UIManager")
    local SoundManager = GFScript("CoreModule.Sound.SoundManager")
    local TimerManager = GFScript("CoreModule.TimerManager")
    local SoundPlaylist = GFScript("CoreModule.Sound.SoundPlaylist")    
    local ActorManager = GFScript("ActorModule.ActorManager")
    local MaterialInstance = GFScript("AvatarModule.MaterialInstance")
    local Vec2 = GFScript("CoreModule.Math.Vec2")
    local Vec3 = GFScript("CoreModule.Math.Vec3")
    local Vec4 = GFScript("CoreModule.Math.Vec4")
    local Color = GFScript("CoreModule.Math.Color")
    local workspace = game:GetService("workspace")
    local ActionManager = GFScript("ActorModule.ActionManager")
    local ValueTo = GFScript("ActorModule.Action.ValueTo")
    local Sequence = GFScript("ActorModule.Action.Sequence")
    local RepeatForever = GFScript("ActorModule.Action.RepeatForever")
    

    if key == 287 then --F6
        -- UIManager:ToggleView("InventoryView")
        -- SoundManager:PlaySound("Music", "sandboxId://audio/buysuccess.mp3", nil, function(node)
        --     SoundManager:StopSound("Music", "sandboxId://audio/buysuccess.mp3")
        --     TimerManager:DelayCall(function()
        --      SoundManager:PlaySound("Music", "m2.mp3")
        --     end, 5)
        -- end)

        -- local playlist = SoundPlaylist.New("Music")
        -- playlist:SetPlayMode("Random")
        -- playlist:SetPlayInterval(3, 10)
        -- playlist:SetLoop(true)
        -- playlist:AddSound("m1.mp3")
        -- playlist:AddSound("m2.mp3")
        -- playlist:Play()
        
    elseif key == 288 then --F7
        -- local function DelayTest()
        --     local interval = math.random(1, 10)
        --     TimerManager:DelayCall(function(interval)
        --         DelayTest()
        --         UILog:Error("@@@@@@@@@@@@@@@ DelayTest "..interval)
        --     end, interval)
        -- end
        -- DelayTest()
        
    elseif key == 289 then --F8
        UIManager:ToggleView("GmView")
    elseif key == 290 then --F9
    elseif key == 291 then --F10
    elseif key == 292 then --F11
    elseif key == 293 then --F12
    end
end

return UIInputSystem

