local Class = GFScript("CoreModule.Class")
local Log = GFScript("CoreModule.Log")
local Utils = GFScript("CoreModule.Utils")
local EventObject = GFScript("CoreModule.EventObject")

local Grid2D = Class.New("Grid2D")
--格子最大大小
Grid2D.maxSize = 1024
--相邻方向偏移
Grid2D.neighbourOffsets = {
    {0,1},
    {-1,1},
    {1,1},
    {-1,0},
    {0,0},
    {1,0},
    {0,-1},
    {-1,-1},
    {1,-1},
}
--初始化
function Grid2D:Init()
    self.grids = {}
end

--坐标转id
function Grid2D:ToId(x, y)
    return y * self.maxSize + x
end

--id转坐标
function Grid2D:ToPosition(id)
    return math.fmod(id, self.maxSize), math.floor(id / self.maxSize)
end

--添加
function Grid2D:Add(x, y, value)
    local id = self:ToId(x, y)
    if not self.grids[id] then
        self.grids[id] = {}
    end
    table.insert(self.grids[id], value)
end

--获取
function Grid2D:Get(x, y, rets)
    local id = self:ToId(x, y)
    local grid = self.grids[id]
    if not grid then
        return
    end
    for i, v in ipairs(grid) do
        table.insert(rets, v)
    end
end

--获取周边对象列表
function Grid2D:GetWithNeighbours(x, y, rets)
    for i = 1, #Grid2D.neighbourOffsets do
        local offset = Grid2D.neighbourOffsets[i]
        local x1 = x + offset[1]
        local y1 = y + offset[2]
        self:Get(x1, y1, rets)
    end
end

--清理全部
function Grid2D:ClearAll()
    self.grids = {}
end


return Grid2D