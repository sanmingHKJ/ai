-- 说明:插槽控件基类
-- 日期:2025年3月23日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local UIWidget = GFScript("UIModule.UIWidget")
local SuperSlotBase = UIClass.New("SuperSlotBase", UIWidget)

function SuperSlotBase:Constructor()
    self.frame = nil
    self.icon = nil
    self.bg = nil
    self.name = nil
    self.lv = nil
    self.num = nil

    self.controls = {}

    --绑定信息, {controlName = control, controlProperty = property, dataProperty = dataProperty, customFunction = customFunction}
    self.binds = {}

end

function SuperSlotBase:Destructor()
    self.binds = nil
end

--[[    
    添加绑定
    @param controlName: 控件名称
    @param controlProperty: 控件属性
    @param dataProperty: 数据属性
    @param customFunction: 自定义函数
]]
function SuperSlotBase:AddBind(controlName, controlProperty, dataProperty, customFunction)

    local control = self.controls[controlName]
    if not control then
        control = self:FindControl(controlName)
        if control then
            self.controls[controlName] = control
        else
            self.controls[controlName] = "nil"
        end
    end

    if not control or control == "nil" then
        return
    end

    table.insert(self.binds, {
        controlName = controlName,
        controlProperty = controlProperty,
        dataProperty = dataProperty,
        customFunction = customFunction
    })
end

--[[
    添加绑定
    @param binds: 绑定信息, {controlName = control, controlProperty = property, dataProperty = dataProperty, customFunction = customFunction}
]]
function SuperSlotBase:AddBinds(binds)
    for i, bind in ipairs(binds) do
        self:AddBind(bind[1], bind[2], bind[3], bind[4])
    end
end

--[[
    移除绑定
    @param controlName: 控件名称
]]
function SuperSlotBase:RemoveBind(controlName, controlProperty)
    for i, bind in ipairs(self.binds) do
        if bind.controlName == controlName and bind.controlProperty == controlProperty then
            table.remove(self.binds, i)
            break
        end
    end
end

--[[
    移除所有绑定
]]
function SuperSlotBase:RemoveAllBind()
    self.binds = {}
end

--[[
    更新绑定
]]
function SuperSlotBase:UpdateBinds()
    for i, bind in ipairs(self.binds) do
        local control = self.controls[bind.controlName]
        if control then
            local data = self.data
            if type(data) ~= "table" then
                data = nil
            end
            local dataProperty = bind.dataProperty
            if dataProperty then
                local dataValue = nil
                if data then
                    dataValue = data[dataProperty]
                end
                if not dataValue or bind.lastValue ~= dataValue then
                    if bind.customFunction then
                        bind.customFunction(control, dataValue, data)
                    else
                        if dataValue then
                            control[bind.controlProperty] = dataValue
                        end
                    end
                    bind.lastValue = dataValue
                end
            end
        end
    end
end

--[[
    初始化
    @param bindObj: 绑定的UI对象
    @param managedBindObj: 是否管理绑定的UI对象
]]
function SuperSlotBase:Init(bindObj, managedBindObj)
    if not SuperSlotBase.super.Init(self, bindObj, managedBindObj) then
        return false
    end

    self:Refresh()

    return true
end

--[[
    设置数据
    @param data: 数据
]]
function SuperSlotBase:SetData(data)
    self.data = data
    self:Refresh()
end

--[[
    获取数据
    @return: 数据
]]
function SuperSlotBase:GetData()
    return self.data
end

--[[
    重绘
]]
function SuperSlotBase:OnRefresh()
    self:UpdateBinds()
end
return SuperSlotBase
