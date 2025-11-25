local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local Profiler = GFScript("CoreModule.Profiler")
local EventObject = Class.New("EventObject")
--自动事件id
EventObject.autoEventId = 0

EventObject.profilerEnabled = false

function EventObject:Constructor()
    --事件列表
    self.events = {}
    --是否屏蔽事件
    self.blockEvent = false

    --正在触发事件中
     self.triggeringEvent = false
     self.addListenerTemp = {}
     self.removeListenerTemp = {}
     self.eventDebug = false
end

function EventObject:Destructor()
    self.events = {}
    self.blockEvent = false
    self.triggeringEvent = false
    self.addListenerTemp = {}
    self.removeListenerTemp = {}
end

function EventObject:GetAutoEventId()
    self.autoEventId = self.autoEventId + 1
    return self.autoEventId
end

function EventObject:Init()
end

--屏蔽事件
function EventObject:BlockEvent(block)
    self.blockEvent = block
end

--注册事件
function EventObject:AddListener(eventName, callback, eventId)
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
function EventObject:SetListener(eventName, callback)
    self:RemoveListener(eventName, callback)
    self:AddListener(eventName, callback)
end

--做一个简易封装
function EventObject:On(eventName, callback)
    return self:AddListener(eventName, callback)
end

--服务端触发事件
function EventObject:OnServerEvent(eventName, callback)
    return self:AddListener("Server"..eventName, callback)
end

--客户端触发事件
function EventObject:OnClientEvent(eventName, callback)
    return self:AddListener(eventName, callback)
end

--移除事件
function EventObject:RemoveListener(eventName, callback)
    if self.triggeringEvent then
        if not self.removeListenerTemp then
            self.removeListenerTemp = {}
        end
        table.insert( self.removeListenerTemp, {callback = callback, eventName = eventName} )
        return true
    end
    if self.events == nil then
        self.events = {}
        return true
    end
    if self.events[eventName] == nil then
        return true
    end
    -- 倒序遍历以避免删除元素时的索引问题
    for k = #self.events[eventName], 1, -1 do
        local v = self.events[eventName][k]
        if v and v.callback == callback then
            table.remove(self.events[eventName], k)
            return true
        end
    end
    return false
end

--移除事件
function EventObject:RemoveByEventId(eventId)
    if self.triggeringEvent then
        if not self.removeListenerTemp then
            self.removeListenerTemp = {}
        end
        table.insert( self.removeListenerTemp, {eventId = eventId} )
        return true
    end
    for k,v in pairs(self.events) do
        -- 倒序遍历以避免删除元素时的索引问题
        for kk = #v, 1, -1 do
            local vv = v[kk]
            if vv and vv.eventId == eventId then
                table.remove(self.events[k], kk)
                return true
            end
        end
    end
    return false
end

--移除事件
function EventObject:Off(eventName, callback)
    if type(eventName) == "table" then
        for _,v in ipairs(eventName) do
            self:Off(v, callback)
        end
        return
    end
    if type(eventName) == "number" then
        return self:RemoveByEventId(eventName)
    else
        return self:RemoveListener(eventName, callback)
    end
end

--移除所有事件
function EventObject:OffAll()
    self.events = {}
end

--简易封装
function EventObject:OffServer(eventName, callback)
    if type(eventName) == "number" then
        return self:RemoveByEventId(eventName)
    else
        return self:RemoveListener("Server"..eventName, callback)
    end
end

--简易封装
function EventObject:OffClient(eventName, callback)
    if type(eventName) == "number" then
        return self:RemoveByEventId(eventName)
    else
        return self:RemoveListener(eventName, callback)
    end
end

function EventObject:OnEventDebug(eventName, ...)
    Log:Error("EventObject:FireEventImpl %s %s", self.__cname, eventName)
end


--触发事件
function EventObject:FireEventImpl(eventName, ...)
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
    if self.eventDebug then
        self:OnEventDebug(eventName, ...)
    end
    if EventObject.profilerEnabled then
        Profiler:Start("FireEventImpl: "..eventName,0.1)
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
    if EventObject.profilerEnabled then
        Profiler:Stop()
    end
end

--服务端触发事件
function EventObject:FireServer(eventName, ...)
    self:FireEventImpl("Server"..eventName, ...)
end

--客户端触发事件
function EventObject:FireClient(eventName, ...)
    self:FireEventImpl(eventName, ...)
end

--触发事件
function EventObject:Fire(isServer, eventName, ...)
    if isServer then
        self:FireServer(eventName, ...)
    else
        self:FireClient(eventName, ...)
    end
end


return EventObject