-- 说明:状态信息控件
-- 日期:2025年3月23日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local UIUtils = GFScript("UIModule.UIUtils")
local Color = GFScript("UIModule.UIMath.Color")
local Vec2 = GFScript("UIModule.UIMath.Vec2")
local UIResource = GFScript("UIModule.UIResource")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local UIStatText = UIClass.New("UIStatText", UIWidget)

function UIStatText:Constructor()
    self.statIconCtrl = nil
    self.statCtrl = nil
    self.valueCtrl = nil
    self.addValueCtrl = nil
    self.isPercent = false
    self.isShowUnit = false
    
    self.statIconColor = Color.New(1, 1, 1, 1)
    self.statColor = Color.New(1, 1, 1, 1)
    self.valueColor = Color.New(1, 1, 1, 1)
    self.addValueColor = Color.New(1, 1, 1, 1)
    self.textColor = Color.New(1, 1, 1, 1)

    self.iconSize = Vector2.New(0, 0)

    self.autoSize = false
    self.padding = 5
    self.spacing = 10

    self.fontSize = 16

    self.addValueText = ""

    self.statIconLoaded = false

    self:SetEventPass(true)
end

--[[
    初始化
    @param bindObj: 绑定的UI对象
]]
function UIStatText:Init(bindObj)
    if not UIStatText.super.Init(self, bindObj) then
        return false
    end

    self:InitControls()

    self:Refresh()

    return true
end

--[[
    初始化控件
]]
function UIStatText:InitControls()
    local createImage = function(name)
        local image = SandboxNode.New("UIImage")
        image.Name = name
        image.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        image.Parent = self.bindObj
        image.Pivot = Vector2.New(0, 0)
        image.Position  = Vector2.New(0, 0)   
        image.Size  = Vector2.New(0, 0)
        image.Visible = false
        return image
    end
    local createText = function(name)
        local text = SandboxNode.New("UITextLabel")
        text.Name = name
        text.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE
        text.Parent = self.bindObj
        text.Pivot = Vector2.New(0, 0)
        text.Position  = Vector2.New(0, 0)   
        text.Size  = Vector2.New(0, 0)
        text.IsAutoSize = Enum.AutoSizeType.BOTH
        text.FontSize = self.fontSize
        return text
    end
    self.statIconCtrl = createImage("StatIcon")
    self.statCtrl = createText("Name")
    self.valueCtrl = createText("Value")
    self.addValueCtrl = createText("AddValue")
end

function UIStatText:SetStat(stat)
    self.stat = stat
    self:Refresh()
end

function UIStatText:SetValue(value)
    self.value = value
    self:Refresh()
end

function UIStatText:SetAddValue(addValue)
    self.addValue = addValue
    self:Refresh()
end

function UIStatText:SetAddValueText(addValueText)
    self.addValueText = addValueText
    self:Refresh()
end

function UIStatText:SetIsPercent(isPercent)
    self.isPercent = isPercent
    self:Refresh()
end

function UIStatText:SetIsShowUnit(isShowUnit)
    self.isShowUnit = isShowUnit
    self:Refresh()
end

function UIStatText:SetStatColor(statColor)
    self.statColor = statColor
    self:Refresh()
end

function UIStatText:SetValueColor(valueColor)
    self.valueColor = valueColor
    self:Refresh()
end

function UIStatText:SetAddValueColor(addValueColor)
    self.addValueColor = addValueColor
    self:Refresh()
end

function UIStatText:SetTextColor(color)
    self.textColor = color
    self:Refresh()
end

function UIStatText:SetFontSize(fontSize)
    self.fontSize = fontSize
    self:Refresh()
end

function UIStatText:SetAutoSize(autoSize)
    self.autoSize = autoSize
    self:Refresh()
end

--[[
    设置状态图标
    @param statIcon: 状态图标
    @param iconSize: 图标大小
]]
function UIStatText:SetStatIcon(statIcon, iconSize)
    UIUtils:LoadImage(self.statIconCtrl, statIcon, function(success, control, res)
        self.statIconLoaded = success
        if success then
            UIUtils:SetColor(self.statIconCtrl, self.statIconColor)
            -- SetNativeSize 取不到
            -- UIUtils:SetNativeSize(self.statIconCtrl)
            self.statIconCtrl.Size = Vector2.New(iconSize.x, iconSize.y)
        end
        self.statIconCtrl.Visible = success
        
        -- self:Refresh()
    end)
end

--[[
    刷新
]]
function UIStatText:OnRefresh()
    self:UpdateIconSizeAndScale()
    self:UpdateTextColor()
    self:UpdateText()
    self:UpdateTextLayout()
end

--[[
    更新文本颜色
]]
function UIStatText:UpdateTextColor()
    if self.statColor then
        UIUtils:SetColor(self.statCtrl, self.statColor * self.textColor)
    end
    if self.valueColor then
        UIUtils:SetColor(self.valueCtrl, self.valueColor * self.textColor)
    end
    if self.addValueColor then
        UIUtils:SetColor(self.addValueCtrl, self.addValueColor * self.textColor)
    end
end

--[[
    更新文本布局
]]
function UIStatText:UpdateTextLayout()
    self:SetChildrenNativeSize(true)

    local controls = {self.bindObj, self.statCtrl, self.valueCtrl}
    if self.statIconLoaded then
        controls = {self.bindObj, self.statIconCtrl, self.statCtrl, self.valueCtrl}
    end
    UIUtils:AlignChain(controls, Vec2.New(0, 0.5), Vec2.New(self.padding, 0), Vec2.New(0, 0.5), 
        Vec2.New(0, 0.5), Vec2.New(self.spacing, 0), Vec2.New(1, 0.5))

    UIUtils:Align(self.addValueCtrl, self.bindObj, Vec2.New(1, 0.5), Vec2.New(-self.padding, 0), Vec2.New(1, 0.5))
    if self.autoSize then
        self:FitSize(self.padding, self.padding)
    end
end

--[[
    更新文本
]]
function UIStatText:UpdateText()
    local unitText = ""
    if self.stat then
        local statConfig = ConfigManager:GetConfig("stat_tbstat", self.stat)
        if statConfig then
            self.statCtrl.Title = statConfig.name
        else
            self.statCtrl.Title = self.stat
        end
        self.statCtrl.FontSize = self.fontSize
        if statConfig then
            UIUtils:SetColor(self.statCtrl, statConfig.color)
            UIUtils:SetColor(self.valueCtrl, statConfig.color)
            unitText = statConfig.unit or ""
        end
    end
    if self.value then
        local valueString = tostring(self.value)
        local valueText = self:FormatStatText(valueString, self.isPercent, "", false)   
        if self.isShowUnit and unitText ~= "" then
            valueText = valueText .. unitText
        end
        self.valueCtrl.Title = valueText
        self.valueCtrl.FontSize = self.fontSize
    end
    if self.addValue then
        local addValueString = tostring(self.addValue)
        self.addValueCtrl.Title = self:FormatStatText(addValueString, self.isPercent, self.addValueText, true)
        self.addValueCtrl.FontSize = self.fontSize
    end
end

function UIStatText:UpdateIconSizeAndScale()
    if not self.statIconCtrl or self.iconSize.X == 0 or self.iconSize.Y == 0 then
        return
    end
    self.statIconCtrl.Size = Vector2.New(self.iconSize.X, self.iconSize.Y)
end

--[[
    格式化文本
    @param text: 文本
    @param isPercent: 是否是百分比
    @param addSymbol: 增加的符号(如"+"、"-"等)
    @param addBrackets: 是否增加括号
    @return: 格式化后的文本
]]
function UIStatText:FormatStatText(text, isPercent, addSymbol, addBrackets)
    local result = text
    
    -- 添加百分比符号
    if isPercent then
        --保留两位小数
        result = string.format("%.2f", result) .. "%"
    end
    
    -- 添加增加符号（如果有）
    if addSymbol and addSymbol ~= "" then
        result = addSymbol .. result
    end
    
    -- 添加括号（如果需要）
    if addBrackets then
        result = "(" .. result .. ")"
    end
    
    return result
end

return UIStatText
