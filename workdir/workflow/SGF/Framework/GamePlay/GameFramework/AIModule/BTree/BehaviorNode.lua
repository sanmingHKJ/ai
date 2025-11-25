local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local BehaviorProcess = GFScript("AIModule.BTree.BehaviorProcess")
local EResult = BehaviorDefines.EResult
local EEvent = BehaviorDefines.EEvent

local BehaviorNode = Class.New("BehaviorNode")
--实例化
function BehaviorNode:Constructor(parent, data,tree)
    self.parent = parent
    self:Init(data,tree)
end

--初始化
function BehaviorNode:Init(data,tree)
    self.name = data.name
    self.tree = tree
    --id只用于标记节点
    if data.id then
        self.id = data.id
    else
        --走自动id分配
        self.id = tree:GetUniqueId()
    end
    --参数列表
    self.args = data.args or {}
    --允许打断
    self.canInterrupt = (self.args.canInterrupt == nil) and true or self.args.canInterrupt 
    if self.canInterrupt and self.parent and not self.parent.canInterrupt then
        self.canInterrupt = false
    end
    --是否永远返回成功
    self.alwaysSuccess = (data.alwaysSuccess == nil) and false or data.alwaysSuccess 
    --bbkey组
    if self.parent then
        self.bbKeyGroup = Utils:IsNullOrEmpty(data.bbKeyGroup) and self.parent.bbKeyGroup or data.bbKeyGroup
    else
        self.bbKeyGroup = data.bbKeyGroup
    end
    --信息
    self.info = string.format('node %s.%s %s %s', tree.name, self.id, self.name, self.args and tostring(self.args.note) or "")
    --装饰器
    self.decorators = {}
    --服务
    self.service = nil
    --子节点
    self.children = {}
    self.hasCooldown = false
    --加载装饰器
    for _, decorator_data in ipairs(data.decorators or {}) do
        local decorator = {
            name = decorator_data.name,
            args = decorator_data.args,
        }
        if decorator.name == "Cooldown" then
            self.hasCooldown = true
        end
        table.insert(self.decorators, decorator)
    end
    --加载服务
    if data.service then
        local service = {
            name = data.service.name,
            args = data.service.args,
        }
        self.service = service
    end
    --加载子节点
    for _, child_data in ipairs(data.children or {}) do
        if not child_data.disabled then
            local child = BehaviorNode.New(self,child_data, tree)
            table.insert(self.children, child)
        end
    end
end

--进入
function BehaviorNode:Enter(runtime)
    runtime:PushStack(self)
end
--退出
function BehaviorNode:Exit(runtime)
    runtime:PopStack()
end

--开始冷却
function BehaviorNode:StartCooldown(runtime)
    if self.hasCooldown then
        for i = 1, #self.decorators do
            local decorator = self.decorators[i]
            if decorator.name == "Cooldown" then
                local cooldown = runtime:GetBB(self, decorator.args.cooldownBBKey, decorator.args.cooldown)
                runtime:SetInnerVar(self, "COOLDOWN", Utils:GetServerTime() + cooldown)
                runtime:SetStepVar(self, "COOLDOWN", true)
            end
        end
    end
end

--进行装饰器的判断
function BehaviorNode:CheckDecorator(runtime, firstRun)
    local decoratorRet = EResult.SUCCESS
    for i = 1, #self.decorators do
        local decorator = self.decorators[i]
        local process = self.tree.process[decorator.name] or BehaviorProcess[decorator.name]
        if not process then
            Log:Error("node %s decorator %s not found", self.info, decorator.name)
            return EResult.FAIL
        end
        local ret = EResult.SUCCESS
        local func = process.Run
        local ok, errmsg = xpcall(function()
            ret = func(self,runtime,decorator.args, firstRun)
            if decorator.args and decorator.args.invert then
                if ret == EResult.SUCCESS then
                    ret = EResult.FAIL
                else
                    ret = EResult.SUCCESS
                end
            end
        end,debug.traceback)
        if not ok then
            Log:Error("node %s decorator %s Run error:%s", self.info, decorator.name, tostring(errmsg))
        end
        --只有失败才会退出循环，其他情况都按成功来处理
        if ret == EResult.FAIL then
            decoratorRet = EResult.FAIL
        end
        if decoratorRet == EResult.FAIL then
            break
        end
    end
    return decoratorRet
end

--运行
function BehaviorNode:Run(runtime, args)
    local ret = self:OnRun(runtime, args)
    return ret
end

--运行
function BehaviorNode:OnRun(runtime, args)
    local firstRun = false
    if runtime.__lastNode ~= self then
        runtime.__lastNode = self
        firstRun = true
    end
    if runtime:IsAbort() then
        return EResult.RUNNING
    end
    
    if runtime:GetNodeStateVar(self, "YIELD") == nil then
        self:Enter(runtime)
    end

    if runtime.lastRet == EResult.RUNNING then
        --往上判断是否装饰器仍然成立
        local stack = runtime.stack
        for i = #stack, 1, -1 do
            local node = stack[i]
            --如果不允许打断，直接退出
            if not node.canInterrupt then
                break
            end
            local ret = node:CheckDecorator(runtime, false)
            if ret == EResult.FAIL then
                local process = self.tree.process[self.name] or BehaviorProcess[self.name]
                local func = process.Abort
                if func ~= nil then
                    ret = func(self, runtime, self.args)
                end
                runtime.abort = true
                return EResult.RUNNING
            end
        end
    else
        --执行装饰器
        local decoratorRet = self:CheckDecorator(runtime, firstRun)
        if decoratorRet == EResult.FAIL then
            self:Exit(runtime)
            if self.alwaysSuccess then
                runtime.lastRet = EResult.SUCCESS
                return EResult.SUCCESS
            else
                runtime.lastRet = EResult.FAIL
                return EResult.FAIL
            end
        end
    end

    --执行节点过程
    local ret = EResult.SUCCESS
    local process = self.tree.process[self.name] or BehaviorProcess[self.name]
    if not process then
        Log:Error("node %s process not found", self.info)
        self:Exit(runtime)
        runtime.lastRet = EResult.FAIL
        return EResult.FAIL
    end
    local func = process.Run
    local ok, errmsg = xpcall(function()
        ret = func(self, runtime, self.args)
    end,debug.traceback)
    if not ok then
        Log:Error("node %s Run error:%s", self.info, tostring(errmsg))
    end

    if ret == EResult.ABORT then
        runtime.abort = true
        --安全退出
        return EResult.RUNNING
    end

    if ret ~= EResult.RUNNING then
        runtime:SetNodeStateVar(self, "YIELD", nil)
        self:Exit(runtime)
        --开始冷却
        self:StartCooldown(runtime)
    elseif runtime:GetNodeStateVar(self, "YIELD") == nil then
        runtime:SetNodeStateVar(self, "YIELD", true)
    end

    if ret == EResult.FAIL and self.alwaysSuccess then
        ret = EResult.SUCCESS
    end
    
    runtime.lastRet = ret

    if self.debug then
        local debugger = function(node, runtime, ret)
            Log:Debug(node:GetDebugInfo(runtime, ret))
        end
        debugger(self, runtime, ret)
    end

    return ret
end

function BehaviorNode:Yield(runtime, arg)
    runtime:SetNodeStateVar(self, "YIELD", arg or true)
    return EResult.RUNNING
end

function BehaviorNode:Resume(runtime)
    return runtime:GetNodeStateVar(self, "YIELD"), runtime.lastRet
end

function BehaviorNode:GetDebugInfo(runtime, ret)
    local var_str = ''
    for k, v in pairs(runtime.vars) do
        var_str = var_str .. string.format("[%s]=%s,", k, v)
    end
    return string.format("BTree:%s, ret:%s vars:{%s}", self.info, ret, var_str)
end

return BehaviorNode