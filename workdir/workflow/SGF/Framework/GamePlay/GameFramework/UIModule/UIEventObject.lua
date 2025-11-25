-- 说明:UI事件对象
-- 日期:2025年4月17日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UILog = GFScript("UIModule.UILog")
local UIClass = GFScript("UIModule.UIClass")

local UIEventObject = UIClass.New("UIEventObject")
--自动事件id
UIEventObject.autoEventId = 0

function UIEventObject:Constructor()
    --事件列表
    self.events = {}
    --是否屏蔽事件
    self.blockEvent = false

    --正在触发事件中
     self.triggeringEvent = false
     self.addListenerTemp = {}
     self.removeListenerTemp = {}
end

function UIEventObject:Destructor()
    self.events = {}
    self.blockEvent = false
    self.triggeringEvent = false
    self.addListenerTemp = {}
    self.removeListenerTemp = {}
end

function UIEventObject:GetAutoEventId()
    self.autoEventId = self.autoEventId + 1
    return self.autoEventId
end

function UIEventObject:Init()
end

--屏蔽事件
function UIEventObject:BlockEvent(block)
    self.blockEvent = block
end

--注册事件
function UIEventObject:AddListener(eventName, callback, eventId)
    if self.triggeringEvent then
        if not self.addListenerTemp then
            self.addListenerTemp = {}
        end
        local eventId = eventId or self:GetAutoEventId()
        table.insert( self.addListenerTemp, {callback = callback, eventName = eventName, eventId = eventId} )
        return eventId
    end
    self:RemoveListener(eventName, callback)
    if self.events == nil then
        self.events = {}
    end
    if self.events[eventName] == nil then
        self.events[eventName] = {}
    end
    local eventId = eventId or self:GetAutoEventId()
    table.insert(self.events[eventName], {callback = callback, eventId = eventId})
    return eventId
end

--设置事件
function UIEventObject:SetListener(eventName, callback)
    self:RemoveListener(eventName, callback)
    self:AddListener(eventName, callback)
end

--做一个简易封装
function UIEventObject:On(eventName, callback)
    return self:AddListener(eventName, callback)
end

--服务端触发事件
function UIEventObject:OnServerEvent(eventName, callback)
    return self:AddListener("Server"..eventName, callback)
end

--客户端触发事件
function UIEventObject:OnClientEvent(eventName, callback)
    return self:AddListener(eventName, callback)
end

--移除事件
function UIEventObject:RemoveListener(eventName, callback)
    if self.triggeringEvent then
        if not self.removeListenerTemp then
            self.removeListenerTemp = {}
        end
        table.insert( self.removeListenerTemp, {callback = callback, eventName = eventName} )
        return
    end
    if self.events == nil then
        self.events = {}
        return
    end
    if self.events[eventName] == nil then
        return
    end
    -- 倒序遍历以避免删除元素时的索引问题
    for k = #self.events[eventName], 1, -1 do
        local v = self.events[eventName][k]
        if v and v.callback == callback then
            table.remove(self.events[eventName], k)
            return
        end
    end
end

--移除事件
function UIEventObject:RemoveByEventId(eventId)
    if self.triggeringEvent then
        if not self.removeListenerTemp then
            self.removeListenerTemp = {}
        end
        table.insert( self.removeListenerTemp, {eventId = eventId} )
        return
    end
    for k,v in pairs(self.events) do
        -- 倒序遍历以避免删除元素时的索引问题
        for kk = #v, 1, -1 do
            local vv = v[kk]
            if vv and vv.eventId == eventId then
                table.remove(self.events[k], kk)
                return
            end
        end
    end
end
--简易封装
function UIEventObject:Off(eventName, callback)
    if type(eventName) == "number" then
        self:RemoveByEventId(eventName)
    else
        self:RemoveListener(eventName, callback)
    end
end

--简易封装
function UIEventObject:OffServer(eventName, callback)
    if type(eventName) == "number" then
        self:RemoveByEventId(eventName)
    else
        self:RemoveListener("Server"..eventName, callback)
    end
end

--简易封装
function UIEventObject:OffClient(eventName, callback)
    if type(eventName) == "number" then
        self:RemoveByEventId(eventName)
    else
        self:RemoveListener(eventName, callback)
    end
end


--触发事件
function UIEventObject:FireEventImpl(eventName, ...)
    if self.blockEvent then
        return
    end
    if self.events == nil then
        self.events = {}
        return
    end
    if self.events[eventName] == nil then
        return
    end
    self.triggeringEvent = true
    local needRemove = {}
    for k,v in pairs(self.events[eventName]) do
        local args = {...}
        local result
        PCall(function()
            result = v.callback(unpack(args))
        end)
        -- 如果回调返回 true，将其添加到待移除列表
        if result == true then
            table.insert(needRemove, v.eventId)
        end
    end
    self.triggeringEvent = false
    
    -- 处理需要移除的监听器
    for _, eventId in ipairs(needRemove) do
        self:RemoveByEventId(eventId)
    end

    if self.addListenerTemp then
        for _,v in ipairs(self.addListenerTemp) do
            self:AddListener(v.eventName, v.callback, v.eventId)
        end
        self.addListenerTemp = {}
    end

    if self.removeListenerTemp then
        for _,v in ipairs(self.removeListenerTemp) do
            if v.eventId then
                self:RemoveByEventId(v.eventId)
            else
                self:RemoveListener(v.eventName, v.callback)
            end
        end
        self.removeListenerTemp = {}
    end
end

--服务端触发事件
function UIEventObject:FireServer(eventName, ...)
    self:FireEventImpl("Server"..eventName, ...)
end

--客户端触发事件
function UIEventObject:FireClient(eventName, ...)
    self:FireEventImpl(eventName, ...)
end


return UIEventObject