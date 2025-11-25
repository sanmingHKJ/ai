-- 游戏状态逻辑
local gameStateBase = {}
GameState = {}

function gameStateBase.Define(name)
    local ret = {}
    ret.name = name
    GameState[name] = ret
    setmetatable(ret, { __index = gameStateBase })
    return ret
end

function gameStateBase:Start()
    self.isEnd = false
    self.isInit = true
    
    if self.OnStart ~= nil then
        self:OnStart()
    end
end

function gameStateBase:Update(dt)
    if self.isEnd or not self.isInit then
        return
    end

    if self.OnUpdate ~= nil then
        self:OnUpdate(dt)
    end
end

function gameStateBase:End()
    if self.isEnd then
        return
    end

    self.isEnd = true
    self.isInit = false

    if self.OnEnd ~= nil then
        self:OnEnd()
    end
end

function gameStateBase:Switch(name)
    if MS.RunService:IsServer() then
        MSServer.SGameManager:SwitchGameState(name)
    else
        MSClient.CGameManager:SwitchGameState(name)
    end
end

return gameStateBase
