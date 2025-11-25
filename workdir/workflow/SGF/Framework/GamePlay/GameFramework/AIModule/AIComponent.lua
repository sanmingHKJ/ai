local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local ConfigManager = GFScript("CoreModule.ConfigManager")
local GenericTree = GFScript("AIModule.Generic.GenericTree")
local GenericRuntime = GFScript("AIModule.Generic.GenericRuntime")

local AIComponent = Class.New("AIComponent", ActorComponent)

--实例化
function AIComponent:Constructor()
    self.fixedUpdateInterval = 0.2
    --行为树
    self.behaviorRuntime = nil
    --是否启用AI
    self.aiEnabled = true
    --是否服务端ai
    self.isServerAI = true
end
--启动服务端
function AIComponent:OnStartServer()

end

function AIComponent:OnActorSet(actor)
    AIComponent.super.OnActorSet(self, actor)
    if actor then
        actor.AIComponent = self
    end
end

--设置AI启用
function AIComponent:SetAIEnabled(enabled)
    self.aiEnabled = enabled
end

--更新服务端
function AIComponent:FixedUpdateServer(dt)
    if self.isServerAI and self.behaviorRuntime then
        self.behaviorRuntime:Update(dt)
        if self.aiEnabled then
            self.behaviorRuntime:Run()
        end
    end
end
--更新客户端
function AIComponent:FixedUpdateClient(dt)
    if not self.isServerAI and self.behaviorRuntime then
        self.behaviorRuntime:Update(dt, self.aiEnabled)
    end
end

--设置bb信息
function AIComponent:SetupBehavior()
end

function AIComponent:GetBlackboard()
    if not self.behaviorRuntime then
        return nil
    end
    return self.behaviorRuntime.bb
end

function AIComponent:SetBlackboardValue(key, value)
    if not self.behaviorRuntime then
        return
    end
    self.behaviorRuntime:SetBB(nil, key, value)
end

-----------------------------------------------------------------
--从配置加载
function AIComponent:LoadConfig(config)
    if self.behaviorRuntime then
        self.behaviorRuntime:Destroy()
    end
    self.behaviorRuntime = GenericRuntime.New(self.actor)
    self.behaviorRuntime:LoadBlackboard(config.bb)
    self.behaviorRuntime:LoadBehaviorTree(self.tid, config.behavior)
    self:SetupBehavior()
end
--从tid加载数据
function AIComponent:LoadConfigFromTid(tid)
    local config = ConfigManager:GetConfig("AIConfig",tid)
    if config == nil then
        Log:Error("AIComponent:LoadConfigFromTid failed, tid = %d",tid)
        return
    end
    self.tid = tid
    self:LoadConfig(config)
end

return AIComponent