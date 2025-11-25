local Class = GFScript("CoreModule.Class")
local APet = GFScript("PetModule.APet")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local ActorDefines = GFScript("ActorModule.ActorDefines")

-- 服务端怪物
local SNpc = Class.New("SNpc", APet)

function SNpc:InitServer()
    SNpc.super.InitServer(self)

        
    -- 状态改变
    self:OnServerEvent("StateChanged", 
        function(oldState, newState)
            if oldState == ActorDefines.EActorState.Moving and newState == ActorDefines.EActorState.Idle then
                -- Log:Debug("oldState: %s newState: %s",tostring(oldState), tostring(newState))
            end
        end)

    self:OnServerEvent("Dead",
        function()
            
        end)
end

function SNpc:Update(dt)
    SNpc.super.Update(self, dt)
    
    if self:IsServer() then
        local character = self:GetCharacter()
        local state = character:GetCurMoveState()
        -- Log:Error("@@@@@@@@@@@@@ state "..tostring(state))
    end
end
--更新
function SNpc:LaterUpdate(dt)
    SNpc.super.LaterUpdate(self, dt)
end

--加载配置
function SNpc:OnLoadConfig(config)
    SNpc.super.OnLoadConfig(self, config)
    self.isProtect = config.isProtect ~= false
    self.deadBuffs = config.deadBuffs
end

-----------------------------------技能事件-----------------------------------
function SNpc:SkillEvent_ApplyDamage(params)
end

return SNpc