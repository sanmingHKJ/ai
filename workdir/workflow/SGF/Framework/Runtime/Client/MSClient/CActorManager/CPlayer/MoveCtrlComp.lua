-- 角色移动组件
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Utils = GFScript("CoreModule.Utils")

local MoveCtrlComp = {}

function MoveCtrlComp.New(player)
    local o = {}
    setmetatable(o, {__index = MoveCtrlComp})
    o:Init(player)
    return o
end

function MoveCtrlComp:Init(player)
    self.player = player
    self.MoveCtrl = {}
    self.LeftRightValue = 0 --左右
	self.ForwardBackValue = 0 --前后

    -- Windows平台不使用摇杆控件
    if MS.CUR_PLATFORM ~= Enum.EnumDeviceType.WIN then
        -- 摇杆控件
        local UIManager = GFScript("UIModule.UIManager")
        local HudLBView = UIManager:GetView("HudLBView")
        if HudLBView then
            self.RockerView = HudLBView:GetRockerView()
        end
    end
end

-- 绑定动作
function MoveCtrlComp:BindContextActions()

    self.MoveCtrl[Enum.KeyCode.W.Value] = 0
    self.MoveCtrl[Enum.KeyCode.S.Value] = 0
    self.MoveCtrl[Enum.KeyCode.A.Value] = 0
    self.MoveCtrl[Enum.KeyCode.D.Value] = 0

    if MS.CUR_PLATFORM == Enum.EnumDeviceType.WIN then
        -- W
        MS.ContextActionService:BindAction( "player_moveForwardAction", function(actionName, inputState, inputObj)
            self:HandleMoveForward(actionName, inputState, inputObj)
        end, Enum.ContextActionType.KeyBoard.Value, Enum.KeyCode.W.Value )
        -- S
        MS.ContextActionService:BindAction( "player_moveBackwardAction", function(actionName, inputState, inputObj)
            self:HandleMoveBacward(actionName, inputState, inputObj)
        end, Enum.ContextActionType.KeyBoard.Value, Enum.KeyCode.S.Value )
        -- A
        MS.ContextActionService:BindAction( "player_moveLeftAction", function(actionName, inputState, inputObj)
            self:HandleMoveLeft(actionName, inputState, inputObj)
        end, Enum.ContextActionType.KeyBoard.Value, Enum.KeyCode.A.Value )
        -- D
        MS.ContextActionService:BindAction( "player_moveRightAction", function(actionName, inputState, inputObj)
            self:HandleMoveRight(actionName, inputState, inputObj)
        end, Enum.ContextActionType.KeyBoard.Value, Enum.KeyCode.D.Value )
    end
end

-- 前进
function MoveCtrlComp:HandleMoveForward(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.InputBegin.Value then
        self.MoveCtrl[Enum.KeyCode.W.Value] = 1
    
    else
        self.MoveCtrl[Enum.KeyCode.W.Value] = 0
        MS.Events:emit(tostring(MS.EventID.KeyCodeW), 0)
    end
    --MS.Events:emit(tostring(MS.EventID.KeyCodeW), self.MoveCtrl[Enum.KeyCode.W.Value])
    self.ForwardBackValue = self.MoveCtrl[Enum.KeyCode.W.Value] + self.MoveCtrl[Enum.KeyCode.S.Value]

end

-- 后退
function MoveCtrlComp:HandleMoveBacward(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.InputBegin.Value then
        self.MoveCtrl[Enum.KeyCode.S.Value] = -1
    else
        self.MoveCtrl[Enum.KeyCode.S.Value] = 0
    end
    self.ForwardBackValue = self.MoveCtrl[Enum.KeyCode.W.Value] + self.MoveCtrl[Enum.KeyCode.S.Value]
end

-- 左
function MoveCtrlComp:HandleMoveLeft(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.InputBegin.Value then
        self.MoveCtrl[Enum.KeyCode.A.Value] = -1
    else
        self.MoveCtrl[Enum.KeyCode.A.Value] = 0
    end
    self.LeftRightValue = self.MoveCtrl[Enum.KeyCode.A.Value] + self.MoveCtrl[Enum.KeyCode.D.Value]
end

-- 右
function MoveCtrlComp:HandleMoveRight(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.InputBegin.Value then
        self.MoveCtrl[Enum.KeyCode.D.Value] = 1
    else
        self.MoveCtrl[Enum.KeyCode.D.Value] = 0
    end
    self.LeftRightValue = self.MoveCtrl[Enum.KeyCode.A.Value] + self.MoveCtrl[Enum.KeyCode.D.Value]
end

function MoveCtrlComp:Update()
    if MS.CUR_PLATFORM ~= Enum.EnumDeviceType.WIN then
        -- 摇杆控件
        if self.RockerView then
            self.LeftRightValue = self.RockerView.LeftRightValue
            self.ForwardBackValue = self.RockerView.ForwardBackValue
        end
    end
    local dir = Vec3.New(self.LeftRightValue, 0, self.ForwardBackValue)
    self.player.AvatarComponent:InputMovement(dir, true)
end

-- 解除绑定动作
function MoveCtrlComp:UnBindContextActions()
    if MS.CUR_PLATFORM == Enum.EnumDeviceType.WIN then
        MS.ContextActionService:UnbindAction("player_moveForwardAction")
        MS.ContextActionService:UnbindAction("player_moveBackwardAction")
        MS.ContextActionService:UnbindAction("player_moveLeftAction")
        MS.ContextActionService:UnbindAction("player_moveRightAction")
    end

    -- 键盘
    self.MoveCtrl[Enum.KeyCode.A.Value] = 0
    self.MoveCtrl[Enum.KeyCode.D.Value] = 0
    self.MoveCtrl[Enum.KeyCode.W.Value] = 0
    self.MoveCtrl[Enum.KeyCode.S.Value] = 0
    self.LeftRightValue = 0
    self.ForwardBackValue = 0

    -- 摇杆控件
    if self.RockerView then
        self.RockerView:Unregister()
        self.RockerView = nil
    end
end

return MoveCtrlComp