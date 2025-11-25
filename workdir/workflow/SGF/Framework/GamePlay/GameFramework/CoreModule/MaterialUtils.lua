
local MaterialUtils = {}

function MaterialUtils:GetMaterialInstance(model, nodeName, isSkinMesh, materialIdx)
    local model = WorkSpace.Model
    local name = nodeName
    local isSkinMesh = false
    local materialIdx = 0
    local matInst = model:GetMaterialByNameOrIndex(name , true, isSkinMesh , materialIdx)
end

return MaterialUtils