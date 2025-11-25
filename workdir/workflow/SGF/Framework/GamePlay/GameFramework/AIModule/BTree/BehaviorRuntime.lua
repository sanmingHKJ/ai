local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local BehaviorDefines = GFScript("AIModule.BTree.BehaviorDefines")
local BehaviorProcess = GFScript("AIModule.BTree.BehaviorProcess")
local BehaviorTree = GFScript("AIModule.BTree.BehaviorTree")

local EResult = BehaviorDefines.EResult
local EEvent = BehaviorDefines.EEvent

local BehaviorRuntime = Class.New("BehaviorRuntime")

--已经加载的行为树缓存
BehaviorRuntime.LoadedBehaviorTree = {}

--实例化
function BehaviorRuntime:Constructor(owner)
    self.owner = owner
    self.vars = {}
    self.serviceStack = {}
    self.stack = {}
    self.handlers = {}
    self.behaviorTree = nil
    --上下文
    self.ctx = {frame = 0, time = 0, delta = 0}
    --黑板
    self.bb = {}
    --节点状态变量，中断时会清空
    self.nodeStateVars = {}
    --内部变量,不会清空
    self.innerVars = {}
    --步变量,每次root节点执行完毕会清空
    self.stepVars = {}
end

--设置黑板参数
function BehaviorRuntime:LoadBlackboard(bb)
    self.bb = Utils:ShallowCopy(bb)
end
--获取黑板键
function BehaviorRuntime:GetBBKeys(bbKeyGroup)
    local t = self.bb
    if bbKeyGroup then
        for k in string.gmatch(bbKeyGroup, "[^%.]+") do
            t = t[k]
            if not t then
                return self.bb
            end
        end
    end
    return t or self.bb
end
--获取黑板值
function BehaviorRuntime:GetBB(node, BBKey, defaultValue)
    if BBKey == nil or BBKey == "" then
        return defaultValue
    end
    local t = self.bb 
    if node then
        t = self:GetBBKeys(node.bbKeyGroup)
    end
    if BBKey ~= nil then
        local ret = t[BBKey]
        if ret == nil then
            ret = self.bb[BBKey]
        end
        if ret == nil then
            ret = defaultValue
        end
        return ret
    else
        return defaultValue
    end
end
--设置黑板值
function BehaviorRuntime:SetBB(node, BBKey, value)
    local t = self.bb 
    if node then
        t = self:GetBBKeys(node.bbKeyGroup)
    end
    if BBKey ~= nil then
        if t[BBKey] == nil then
            self.bb[BBKey] = value
        else
            t[BBKey] = value
        end
    end
end
--获取黑板向量值
function BehaviorRuntime:GetBBVector(node, BBKey,defaultValue)
    local value = self:GetBB(node, BBKey,defaultValue)
    if type(value) == "table" and #value >= 3 then
        return Vec3.New(value[1],value[2],value[3])
    else
        return Vec3.New(0,0,0)
    end
end
--设置黑板向量值
function BehaviorRuntime:SetBBVector(node, BBKey,value)
    if BBKey ~= nil then
        value = value or Vec3.New(0,0,0)
        self:SetBB(node,BBKey,{value.x,value.y,value.z})
    end
end

--加载行为树
function BehaviorRuntime:LoadBehaviorTree(name, config)
    if BehaviorRuntime.LoadedBehaviorTree[name] then
        self.behaviorTree = BehaviorRuntime.LoadedBehaviorTree[name]
    else
        self.behaviorTree = BehaviorTree.New(name)
        self.behaviorTree:Init(config)
        BehaviorRuntime.LoadedBehaviorTree[name] = self.behaviorTree
    end
end
--更新
function BehaviorRuntime:Update(dt,run)
    self.ctx.frame = self.ctx.frame + 1
    self.ctx.delta = dt
    self.ctx.time = self.ctx.time + dt
    --更新service栈
    if self.behaviorTree then
        for _,serviceNode in ipairs(self.serviceStack) do
            self:UpdateService(serviceNode)
        end
    end

    if run then
        self:Run()
    end
end

--运行
function BehaviorRuntime:Run()
    if self.behaviorTree then
        self.behaviorTree:Run(self)
    end
end

--更新服务
function BehaviorRuntime:UpdateService(serviceNode)
    --判断是否需要更新
    if self.updateFrame then
        if self.updateFrame >= self.ctx.frame then
            self.updateFrame = self.ctx.frame
            return
        end
    end
    local service = serviceNode.service
    --执行服务
    local process = self.behaviorTree.process[service.name] or BehaviorProcess[service.name]
    if not process then
        Log:Error("node %s service %s not found", serviceNode.info, service.name)
        return false
    end
    local func = process.Run
    local ok, errmsg = xpcall(function()
        func(serviceNode,self,service.args)
    end,debug.traceback)
    if not ok then
        Log:Error("node %s service error:%s", serviceNode.info, tostring(errmsg))
        return false
    end
    self.updateFrame = self.ctx.frame
    return true
end

--获取变量
function BehaviorRuntime:GetVar(k)
    return self.vars[k]
end

--设置变量
function BehaviorRuntime:SetVar(k,v)
    if k == "" then return end
    self.vars[k] = v
end

--获取内部变量
function BehaviorRuntime:GetInnerVar(node,k)
    return self.innerVars[k.."_"..node.id]
end

--设置内部变量
function BehaviorRuntime:SetInnerVar(node,k,v)
    self.innerVars[k.."_"..node.id] = v
end

--获取节点状态变量
function BehaviorRuntime:GetNodeStateVar(node,k)
    return self.nodeStateVars[k.."_"..node.id]
end

--设置节点状态变量
function BehaviorRuntime:SetNodeStateVar(node,k,v)
    self.nodeStateVars[k.."_"..node.id] = v
end
--获取步变量
function BehaviorRuntime:GetStepVar(node,k)
    return self.stepVars[k.."_"..node.id]
end

--设置步变量
function BehaviorRuntime:SetStepVar(node,k,v)
    self.stepVars[k.."_"..node.id] = v
end

--压入栈
function BehaviorRuntime:PushStack(node)
    table.insert(self.stack,node)
    if node and node.service then
        self.serviceStack[#self.serviceStack+1] = node
        --立刻更新一次
        self.updateFrame = nil
        self:UpdateService(node)
        --下一帧不更新
        self.updateFrame = self.ctx.frame + 1
    end
end

--弹出栈
function BehaviorRuntime:PopStack()
    local node = self.stack[#self.stack]
    if node and node.service then
        self.serviceStack[#self.serviceStack] = nil
    end
    table.remove(self.stack)
    return node
end

--是否终止
function BehaviorRuntime:IsAbort()
    return self.abort
end

--注册事件
function BehaviorRuntime:On(event,callback)
    local handlers = self.handlers[event]
    if not handlers then
        handlers = {}
        self.handlers[event] = handlers
    end
    handlers[#handlers+1] = callback
end

return BehaviorRuntime