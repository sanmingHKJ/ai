local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local GmManager = GFScript("GmModule.GmManager")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local GmComponent = Class.New("GmComponent", ActorComponent)

GmComponent.version = 1

--实例化
function GmComponent:Constructor()

end

--启动服务端
function GmComponent:OnStartServer()

end

--启动客户端
function GmComponent:OnStartClient()

end

function GmComponent:OnActorSet(actor)
    GmComponent.super.OnActorSet(self, actor)
    if not self:IsPlayer() then
        Log:Error("GmComponent is not a player")
    end
end


-- 执行GM命令
-- @param cmdString 完整的命令字符串，格式：命令 参数1 参数2 参数3...
function GmComponent:ExecuteCommand(cmdString)
    return GmManager:ExecuteCommand(self.actor, cmdString)
end

-- 执行GM命令
function GmComponent:CmdExecuteCommand(cmdString)
    return self:ExecuteCommand(cmdString)
end

-- 发送GM命令
function GmComponent:SendGmCommand(cmdString)
    if not self:IsPlayer() then
        Log:Warning("GmComponent is not a player")
        return false
    end
    if GmManager:IsServerCommand(cmdString) then
        self:CmdExecuteCommand(cmdString)
    else
        self:ExecuteCommand(cmdString)
    end
    return true
end  

-- 获取所有命令列表
-- @return 按分类排序的命令列表
function GmComponent:GetCommandList()
    return GmManager:GetCommandList()
end

--获取所有分类
function GmComponent:CmdGetCategories()
    local categories = GmManager:GetOrderedCategories()
    self:TRpcGetCategories(categories)
end

function GmComponent:TRpcGetCategories(categories)
    self:FireClient("ReceiveCategories", categories)
end

--获取分类命令
function GmComponent:CmdGetCommandListByCategory(category)
    local commands = GmManager:GetCommandListByCategory(category)
    self:TRpcGetCommandListByCategory(commands)
end

function GmComponent:TRpcGetCommandListByCategory(commands)
    self:FireClient("ReceiveCommandList", commands)
end


return GmComponent