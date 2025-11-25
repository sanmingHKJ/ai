-- 说明:Action管理器
-- 日期:2024年6月1日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UILog = GFScript("UIModule.UILog")
local UIClass = GFScript("UIModule.UIClass")

local UIActionRunner = UIClass.New("UIActionRunner")

--actorState列表
UIActionRunner.actionStates = {}

--初始化
function UIActionRunner:Init()
    --缓存的添加和移除操作
    self.cachedFuncCalls = {}
end

--更新
function UIActionRunner:Update(dt)
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
    self.cachedFuncCalls = {}
end

--运行动作
function UIActionRunner:RunAction(actor, action)
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
function UIActionRunner:GetActionByTag(actor, tag)
    for k,v in ipairs(self.actionStates) do
        if v.actor == actor and v.action.tag == tag then
            return v
        end
    end
    return nil
end

--根据Tag停止动作
function UIActionRunner:StopActionByTag(actor, tag)
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
function UIActionRunner:CountActionByTag(actor, tag)
    local count = 0
    for k,v in ipairs(self.actionStates) do
        if v.actor == actor and v.action.tag == tag then
            count = count + 1
        end
    end
    return count
end

--停止所有动作
function UIActionRunner:StopAllActions(actor)
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
function UIActionRunner:Clear()
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


return UIActionRunner