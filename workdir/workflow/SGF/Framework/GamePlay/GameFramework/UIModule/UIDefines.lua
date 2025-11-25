-- 说明:UI定义
-- 日期:2025年1月20日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIDefines = {}

--进度条类型
UIDefines.EProgressType = {
    Horizontal = "Horizontal",
    Vertical = "Vertical",
    Circle = "Circle",
}

--布局起点
UIDefines.ELayoutOrigin = {
    LeftTop = "LeftTop", --左上，水平布局时，从左到右，垂直布局时，从上到下
    CenterTop = "CenterTop", --中上，水平布局时，从左到右，垂直布局时，从上到下
    RightTop = "RightTop", --右上，水平布局时，从右到左，垂直布局时，从上到下
    LeftMiddle = "LeftMiddle", --左中，水平布局时，从左到右，垂直布局时，从上到下
    CenterMiddle = "CenterMiddle", --中中，水平布局时，从左到右，垂直布局时，从上到下
    RightMiddle = "RightMiddle", --右中，水平布局时，从右到左，垂直布局时，从上到下
    LeftBottom = "LeftBottom", --左下，水平布局时，从左到右，垂直布局时，从下到上
    CenterBottom = "CenterBottom", --中下，水平布局时，从左到右，垂直布局时，从下到上
    RightBottom = "RightBottom", --右下，水平布局时，从右到左，垂直布局时，从下到上 
}

--布局方向
UIDefines.ELayoutDirection = {
    Horizontal = "Horizontal",
    Vertical = "Vertical",
}


--视图风格
UIDefines.EViewStyle = {
    --普通视图
    Normal = "Normal", --普通视图
    --模态视图
    Modal = "Modal", --点击空白区域不会关闭
    --弹窗
    Popup = "Popup", --点击空白区域会关闭
    --全屏
    FullScreen = "FullScreen", --全屏，会关闭其他所有窗口非常驻窗口，会禁用场景部分功能
    --主视图
    Master = "Master", --主视图，会关闭其他所有窗口非常驻窗口，会禁用场景部分功能
}
--视图层级
UIDefines.EViewLayer = {
    --背景
    Background = "Background",
    --普通
    Normal = "Normal",
    --对话框
    Dialog = "Dialog",
    --弹出
    Popup = "Popup",
    --顶部
    Top = "Top",
}

--锚点预设
UIDefines.EAnchorPreset = {
    LeftTop = "LeftTop",
    CenterTop = "CenterTop",
    RightTop = "RightTop",
    LeftMiddle = "LeftMiddle",
    CenterMiddle = "CenterMiddle",
    RightMiddle = "RightMiddle",
    LeftBottom = "LeftBottom",
    CenterBottom = "CenterBottom",
    RightBottom = "RightBottom",
}

--按钮状态
UIDefines.EButtonState = {
    Normal = "Normal", --正常
    Pressed = "Pressed", --按下
    Selected = "Selected", --选中
    Disabled = "Disabled", --禁用
}

-- 缩放模式 
UIDefines.ESpriteScaleMode = {
    None = "None",
    Width = "Width",
    Height = "Height",
    Max = "Max",
    Min = "Min",
}

return UIDefines
