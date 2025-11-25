local Log = GFScript("CoreModule.Log")
local Class = GFScript("CoreModule.Class")
local EventObject = GFScript("CoreModule.EventObject")
local Utils = GFScript("CoreModule.Utils")

local GlobalEvent = Class.New("GlobalEvent", EventObject)

--已经处理过的类不用重新处理
GlobalEvent.eventCaches = {}

--注册全部处理函数
local function RegisterAllHandlers(evtTable, saveTable)
    
    -- 先收集所有需要处理的事件
    local signalEvents = {}
    
    for k, v in pairs(evtTable) do
        if type(v) == "function" then
            if Utils:StartWith(k,"Emit_") and not saveTable["__Emit__"..k] then
                signalEvents[k] = v
            end
        end
    end
    
    for k, v in pairs(signalEvents) do
        local evtName = k:sub(6)
        saveTable[k] = function(obj, ...)
            GlobalEvent:FireClient(evtName, ...)
        end
        saveTable["__Emit__"..k] = true
    end

    if evtTable.super then
        RegisterAllHandlers(evtTable.super, saveTable)
    end
end

local function RegisterAllListener(evtObj,evtTable)
    if not evtObj.globalListenerIds then
        evtObj.globalListenerIds = {}
    end
    
    -- 先收集所有需要处理的事件
    local slotEvents = {}
    
    for k, v in pairs(evtTable) do
        if type(v) == "function" then
            if Utils:StartWith(k,"Slot_") then
                slotEvents[k] = v
            end
        end
    end
    
    -- 分别处理收集到的事件
    for k, v in pairs(slotEvents) do
        local evtName = k:sub(6)
        local listenerId = GlobalEvent:On(evtName, function(...)
            --判断是否进入休眠
            if evtObj.isGlobalEventSleep then
                return
            end
            v(evtObj, ...)
        end)
        table.insert(evtObj.globalListenerIds, listenerId)
    end
    
    if evtTable.super then
        RegisterAllListener(evtObj, evtTable.super)
    end
end

--安装全局事件功能
function GlobalEvent:Setup(evtObj)
    local tempClass = evtObj.class or evtObj
    local key = tempClass.__cname
    if not self.eventCaches[key] then
        RegisterAllHandlers(tempClass,tempClass)
        self.eventCaches[key] = true
    end

    RegisterAllListener(evtObj,tempClass)

    --重写evtObj的 OnDestructor
    local oldOnDelete = evtObj.OnDestructor
    evtObj.OnDestructor = function()
        if oldOnDelete then
            oldOnDelete(evtObj)
        end
        --清理事件
        if evtObj.globalListenerIds then
            for _, listenerId in pairs(evtObj.globalListenerIds) do
                GlobalEvent:Off(listenerId)
            end
            evtObj.globalListenerIds = nil
        end
    end
end

GlobalEvent:Init()

return GlobalEvent  