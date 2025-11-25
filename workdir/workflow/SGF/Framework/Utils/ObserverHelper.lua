--[[
    ObserverHelper.lua - SGF框架观察者模式辅助类
    位置: framework/utils/ObserverHelper.lua
    
    功能：
    1. 为对象添加观察者模式能力
    2. 提供订阅、取消订阅、广播功能
    3. 轻量级的事件系统实现
    
    Version: 4.0.0 (SGF框架)
    原始版本: xplants/ServiceNodes/MainStorage/Scripts/ObserverHelper.lua
    
    变更：
    - 移除对GFScript的依赖
    - 使用SGF框架的日志服务
    - 优化错误处理
]]

local ObserverHelper = {}

--[[
    为对象注册观察者能力
    @param observer 要注册的对象
    @param sgf SGF框架实例（可选，用于日志）
]]
function ObserverHelper:RegisterObserver(observer, sgf)
    if not observer then
        if sgf and sgf.log then
            sgf.log:error("ObserverHelper: observer is nil")
        else
            print("❌ ObserverHelper: observer is nil")
        end
        return
    end

    if observer.__registerObserver then
        if sgf and sgf.log then
            sgf.log:warning("ObserverHelper: observer has been registered")
        end
        return
    end
    
    observer.__registerObserver = true
    observer.__subscribers = {}

    -- 订阅事件
    if not observer.SubscribeObserver then   
        observer.SubscribeObserver = function(self, eventName, owner, handler)
            if self.__subscribers[eventName] == nil then
                self.__subscribers[eventName] = {}
            end
            self.__subscribers[eventName][owner] = handler
        end
    end
    
    -- 取消订阅事件
    if not observer.UnsubscribeObserver then
        observer.UnsubscribeObserver = function(self, eventName, owner)
            local handlers = self.__subscribers[eventName]
            if handlers ~= nil then
                handlers[owner] = nil
            end
        end
    end
    
    -- 广播事件
    if not observer.BroadcastObservers then
        observer.BroadcastObservers = function(self, eventName, ...)
            local handlers = self.__subscribers[eventName]
            if handlers ~= nil then
                for owner, handler in pairs(handlers) do
                    if (owner ~= nil) and (handler ~= nil) then
                        -- 使用pcall保护调用，防止单个处理器错误影响其他处理器
                        local success, err = pcall(handler, owner, ...)
                        if not success then
                            if sgf and sgf.log then
                                sgf.log:error("ObserverHelper: Error in event handler for " .. eventName .. ": " .. tostring(err))
                            else
                                print("❌ ObserverHelper: Error in event handler for " .. eventName .. ": " .. tostring(err))
                            end
                        end
                    end
                end
            end
        end
    end
end

--[[
    取消对象的观察者能力
    @param observer 要取消注册的对象
]]
function ObserverHelper:UnregisterObserver(observer)
    if not observer or not observer.__registerObserver then
        return
    end

    observer.__registerObserver = false
    observer.__subscribers = nil
    observer.SubscribeObserver = nil
    observer.UnsubscribeObserver = nil
    observer.BroadcastObservers = nil
end

return ObserverHelper

