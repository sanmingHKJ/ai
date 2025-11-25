local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local ActorNetProto = GFScript("ActorModule.ActorNetProto")
local Class = GFScript("CoreModule.Class")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")

local ActionManager = Class.New("ActionManager", EventObject)

--actorState列表
ActionManager.actionStates = {}

--初始化
function ActionManager:Init()
    self.cachedFuncCalls = {}
end

--更新
function ActionManager:Update(dt)
    self.updating = true
    for i=#self.actionStates,1,-1 do
        local actionState = self.actionStates[i]
        actionState.action:Update(dt)
        if actionState.action:IsDone() then
            table.remove(self.actionStates, i)
            if actionState.action.target then
                actionState.action:Stop()
            end
        end
    end
    self.updating = false
    for _, v in ipairs(self.cachedFuncCalls) do
        local func = self[v[1]]
        if func then
            func(self, v[2], v[3])
        end
    end
end

--运行动作
function ActionManager:RunAction(actor, action)
    if not actor or not action then
        return
    end
    if self.updating then
        table.insert(self.cachedFuncCalls, {"RunAction",actor, action})
        return
    end
    action:StartWith(actor)
    table.insert(self.actionStates, {actor = actor, action = action})
end

--根据Tag获取动作
function ActionManager:GetActionByTag(actor, tag)
    for k,v in ipairs(self.actionStates) do
        if v.actor == actor and v.action.tag == tag then
            return v
        end
    end
    return nil
end

--根据Tag停止动作
function ActionManager:StopActionByTag(actor, tag)
    if self.updating then
        table.insert(self.cachedFuncCalls, {"StopActionByTag",actor, tag})
        return
    end
    for i = #self.actionStates, 1, -1 do
        local v = self.actionStates[i]
        if v.actor == actor and v.action.tag == tag then
            if v.action.target then
                v.action:Stop()
            end
            table.remove(self.actionStates, i)
        end
    end
end

--根据Tag获取Action的数量
function ActionManager:CountActionByTag(actor, tag)
    local count = 0
    for k,v in ipairs(self.actionStates) do
        if v.actor == actor and v.action.tag == tag then
            count = count + 1
        end
    end
    return count
end

--停止所有动作
function ActionManager:StopAllActions(actor)
    if self.updating then
        table.insert(self.cachedFuncCalls, {"StopAllActions",actor})
        return
    end
    for i = #self.actionStates, 1, -1 do
        local v = self.actionStates[i]
        if v.actor == actor then    
            if v.action.target then
                v.action:Stop()
            end
            table.remove(self.actionStates, i)
        end
    end
end

--清理所有动作
function ActionManager:Clear()
    if self.updating then
        table.insert(self.cachedFuncCalls, {"Clear"})
        return
    end 
    for _, v in ipairs(self.actionStates) do    
        if v.action.target then
            v.action:Stop()
        end
    end
    self.actionStates = {}
end


return ActionManager