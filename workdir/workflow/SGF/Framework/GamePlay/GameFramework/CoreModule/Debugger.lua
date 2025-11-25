local ActorManager = GFScript("ActorModule.ActorManager")
local Json = GFScript("CoreModule.Json")
local WorkSpace = game:GetService("WorkSpace")

local Debugger = {}

--初始化
function Debugger:Init()
    self.debugFrames = {}
end

--更新
function Debugger:Update(dt)
    for _, frame in pairs(self.debugFrames) do
        frame.duration = frame.duration - dt
        if frame.duration <= 0 then
            frame.frame:Destroy()
            table.remove(self.debugFrames, _)
        end
    end
end

function Debugger:GetCurrentWorkSpace()
    return game.WorkSpace
end

--绘制调试框
function Debugger:DrawBox(pos, orient, extSize, color, duration)
    local model = SandboxNode.New('Model', self:GetCurrentWorkSpace())
    model.ModelId = "SandboxId://StandardModel/StandardCube.prefab"
    model.Position = Vector3.New(pos.x,pos.y,pos.z)
    model.Rotation = Quaternion.New(orient.x,orient.y,orient.z,orient.w)
    model.LocalScale = Vector3.New(extSize.x * 0.02,extSize.y * 0.02,extSize.z * 0.02)
    model.EnablePhysics = false
    model.CanCollide = false
    model.CanTouch = false

    local mat = model:GetMaterialInstance({0}, 0)
    if mat then
        mat:SetRGB32("g_RimColor", Vector3.New(color.r, color.g, color.b))
    end
    table.insert(self.debugFrames,{frame = model,duration = duration})
end
--绘制圆形
function Debugger:DrawSphere(pos, extSize, color, duration)
    local model = SandboxNode.New('Model', self:GetCurrentWorkSpace())
    model.ModelId = "SandboxId://StandardModel/StandardSphere.prefab"
    model.Position = Vector3.New(pos.x,pos.y,pos.z)
    model.LocalScale = Vector3.New(extSize.x * 0.02,extSize.y * 0.02,extSize.z * 0.02)
    model.EnablePhysics = false
    model.CanCollide = false
    model.CanTouch = false
    local mat = model:GetMaterialInstance({0}, 0)
    if mat then
        mat:SetRGB32("g_RimColor", Vector3.New(color.r, color.g, color.b))
    end
    table.insert(self.debugFrames,{frame = model,duration = duration})
end
--绘制圆形
function Debugger:DrawCylinder(pos, extSize, color, duration)
    local model = SandboxNode.New('Model', self:GetCurrentWorkSpace())
    model.ModelId = "SandboxId://StandardModel/StandardCylinder.prefab"
    model.Position = Vector3.New(pos.x,pos.y,pos.z)
    model.LocalScale = Vector3.New(extSize.x * 0.02,extSize.y * 0.02,extSize.z * 0.02)
    model.EnablePhysics = false
    model.CanCollide = false
    model.CanTouch = false
    local mat = model:GetMaterialInstance({0}, 0)
    if mat then
        mat:SetRGB32("g_RimColor", Vector3.New(color.r, color.g, color.b))
    end
    table.insert(self.debugFrames,{frame = model,duration = duration})
end

return Debugger