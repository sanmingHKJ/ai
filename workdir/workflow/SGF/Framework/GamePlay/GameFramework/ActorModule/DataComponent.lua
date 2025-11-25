local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local EventObject = GFScript("CoreModule.EventObject")
local Database = GFScript("CoreModule.Database")
local Actor = GFScript("ActorModule.Actor")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local CloudService = game:GetService("CloudService")

local DataComponent = Class.New("DataComponent", ActorComponent)

DataComponent.version = "10.0.42"         --正式上线版本号，一定不可修改
DataComponent.debugEnabled = false

DataComponent.disableSave = false
DataComponent.disableLoad = false

--构造
function DataComponent:Constructor()
    self.updateEnabled = true
    self.autoSaveMutableInterval = 60 --自动保存间隔，单位秒
    self.nextAutoSaveMutableTimeEnd = Utils:GetServerTime() + self.autoSaveMutableInterval
    
    self.autoSaveInterval = 120 --自动保存间隔，单位秒
    self.nextAutoSaveTimeEnd = Utils:GetServerTime() + self.autoSaveInterval

    --存储表
    self.tables = {}
    --易变的表，易变表会定期保存
    self.mutableTables = {}

    self.tableName = "table_data" --表名
    self.mutableTableName = "mutable_table_data" --易变表名

    self.tableData = {}
    self.mutableTableData = {}
end

--析构
function DataComponent:Destructor()

end

--启动服务端
function DataComponent:OnStartServer()

end
--更新服务端
function DataComponent:UpdateServer(dt)
    local time = Utils:GetServerTime()
    if time >= self.nextAutoSaveMutableTimeEnd then
        self:SaveMutableTable()
        self.nextAutoSaveMutableTimeEnd = time + self.autoSaveMutableInterval
    end
    if time >= self.nextAutoSaveTimeEnd then
        self:SaveTable()
        self.nextAutoSaveTimeEnd = time + self.autoSaveInterval
    end
end

--注册表
--@param tableName 表名
--@param obj 表对象，对象需要实现接口: GetData() 获取数据，SetData(data) 设置数据, GetPlayerId() 获取玩家id, GetServerId() 获取服务器id
function DataComponent:RegisterTable(tableName, obj, isMutable)
    --判断接口是否实现
    -- if obj.NewData == nil then
    --     Log:Error("RegisterTable Error! obj is not implement NewData()")
    --     return
    -- end
    -- if obj.UpdateData == nil then
    --     Log:Error("RegisterTable Error! obj is not implement UpdateData()")
    --     return
    -- end
    -- if obj.SetData == nil then
    --     Log:Error("RegisterTable Error! obj is not implement SetData()")
    --     return
    -- end
    -- if obj.GetData == nil then
    --     Log:Error("RegisterTable Error! obj is not implement GetData()")
    --     return
    -- end
    if self:GetServerId(obj) == nil then
        Log:Error("RegisterTable Error! obj is not implement GetServerId()")
        return
    end
    if self:GetPlayerId(obj) == nil then
        Log:Error("RegisterTable Error! obj is not implement GetPlayerId()")
        return
    end

    --判断是否注册过
    if obj.__tableName then
        Log:Error("RegisterTable Error! tableName is already register!")
        return
    end
    obj.__tableName = tableName
    obj.__isMutableTable = isMutable
    
    if obj.LoadData ~= nil then
        Log:Error("RegisterTable Error! %s is already implement LoadData() ", obj.__cname)
    end
    if obj.SaveData ~= nil then
        Log:Error("RegisterTable Error! %s is already implement SaveData() ", obj.__cname)
    end

    obj.LoadData = function(callback)
        if obj.__isMutableTable then
            self:LoadMutableTable(callback)
        else
            self:LoadTable(callback)
        end
    end
    obj.SaveData = function()
        if obj:IsReady() then
            if obj.__isMutableTable then
                self:SaveMutableTable()
            else
                self:SaveTable()
            end
        end
    end

    if isMutable then
        table.insert(self.mutableTables, {
            name = tableName,
            obj = obj,
        })
    else
        table.insert(self.tables, {
            name = tableName,
            obj = obj,
        })
    end
end

--加载全部
function DataComponent:LoadAll(callback,resetData)

    if self.actor:GetServerId() == 0 then
        if callback then callback(false, "Fail") end
        return
    end
    resetData = resetData or false
    if DataComponent.version == "0.0.0" then
        resetData = true
    end
    local loadTableCount = 0
    local function checkCallback(ret)
        loadTableCount = loadTableCount + 1
        if loadTableCount == 2 then
            if callback then callback(ret) end
        end
    end

    if resetData then
        self:ClearData(self.tableName)
        self:ClearData(self.mutableTableName)
    end

    self:LoadTable(checkCallback)
    self:LoadMutableTable(checkCallback)
end
--保存全部
function DataComponent:SaveAll(callback)
    if self.actor:GetServerId() == 0 then
        if callback then callback(false, "Fail") end
        return
    end
    local saveTableCount = 0
    local function checkCallback(ret)
        saveTableCount = saveTableCount + 1
        if saveTableCount == 2 then
            if callback then callback(ret) end
        end
    end
    self:SaveTable(checkCallback)
    self:SaveMutableTable(checkCallback)
end

--加载表
function DataComponent:LoadTable(callback)
    self:LoadImpl(self.tableName, function(ret,data)
        if self.disableLoad then
            for k, v in ipairs(self.tables) do
                if v.obj.NewData then
                    v.obj:NewData()
                end
            end
            if callback then callback(true, data) end
            return
        end
        if ret then
            self.tableData = data
            self:LoadTableData(data)
        else
            for k, v in ipairs(self.tables) do
                if v.obj.NewData then
                    v.obj:NewData()
                end
            end
        end
        if callback then callback(ret,data) end
    end)
end

--保存表
function DataComponent:SaveTable(callback)
    if self.disableSave then
        if callback then callback(true) end
        return
    end
    self.tableData = self:CollectTableData()
    self:SaveImpl(self.tableName, self.tableData, function(ret)
        if callback then callback(ret) end
    end)
end

--加载易变表
function DataComponent:LoadMutableTable(callback)
    self:LoadImpl(self.mutableTableName, function(ret,data)
        if self.disableLoad then
            for k, v in ipairs(self.mutableTables) do
                if v.obj.NewData then
                    v.obj:NewData()
                end
            end
            if callback then callback(true, data) end
            return
        end
        if ret then
            self.mutableTableData = data
            self:LoadMutableTableData(data)
        else
            for k, v in ipairs(self.mutableTables) do
                if v.obj.NewData then
                    v.obj:NewData()
                end
            end
        end
        if callback then callback(ret,data) end
    end)
end

--保存易变表
function DataComponent:SaveMutableTable(callback)
    if self.disableSave then
        if callback then callback(true) end
        return
    end
    self.mutableTableData = self:CollectMutableTableData()
    self:SaveImpl(self.mutableTableName, self.mutableTableData, function(ret)
        if callback then callback(ret) end
    end)
end

--收集表数据
function DataComponent:CollectTableData()
    local data = {}
    for k, v in ipairs(self.tables) do
        if v.obj.GetData then
            data[v.name] = v.obj:GetData()
        end
    end
    return data
end

--收集易变表数据
function DataComponent:CollectMutableTableData()
    local data = {}
    for k, v in ipairs(self.mutableTables) do
        if v.obj.GetData then
            data[v.name] = v.obj:GetData()
        end
    end
    return data
end

--加载表数据
function DataComponent:LoadTableData(data)
    if not data then
        return
    end
    for k, v in ipairs(self.tables) do
        if data[v.name] then
            v.obj:SetData(data[v.name])
        else
            v.obj:NewData()
        end
    end
end

--加载易变表数据
function DataComponent:LoadMutableTableData(data)
    if not data then
        return
    end
    for k, v in ipairs(self.mutableTables) do
        if data[v.name] then
            v.obj:SetData(data[v.name])
        else
            v.obj:NewData()
        end
    end
end

--加载某个表
function DataComponent:LoadImpl(tableName, callback)
    if not self.actor:IsPlayer() then
        Log:Error("Load Error! actor is not player!")
        return
    end
    --判断是否已经选服，如果没有则不读取
    if self.actor:GetServerId() == 0 then
        if callback then callback(false, "Fail") end
        return
    end

    local keyStr = self:GetTableName(tableName)
    CloudService:GetTableAsync(keyStr, function(status, data)
        -- Utils:PCall(function()
            if not status then
                print("Load Error! tableName = "..tableName)
                if callback then callback(false, "New") end
                return
            end

            --判断data是否是空表
            if not data or not next(data) then
                if callback then callback(false, "New") end
                return
            end

            if data and data.version ~= self.version then
                if callback then callback(false, "Update") end
                return
            end
            if self.debugEnabled then
                Log:Debug("%s:SetData : %s", tableName, Utils:T2S(data))
            end
            if callback then callback(true, data) end
        -- end)
    end)
end

--保存数据的实现
function DataComponent:SaveImpl(tableName, data, callback)
    if not self.actor:IsPlayer() then
        Log:Error("SaveImpl Error! actor is not player!")
        return false
    end

    if not data then
        return false
    end
    local keyStr = self:GetTableName(tableName)

    if self.debugEnabled then
        Log:Debug("%s:GetData : %s", tableName, Utils:T2S(data))
    end
    data.version = self.version or 0
    CloudService:SetTableAsync(keyStr, data, function(status)
        if not status then
            --暂时不打印，据说都是成功的
            Log:Error("SaveImpl Error! tableName = "..tableName)
        end
        if callback then callback(true) end
    end)
    return true
end

--打印每一个表的数据
function DataComponent:PrintAllDatas()
    Log:Info("DataTable %s: %s", self.tableName, Utils:T2S(self.tableData))
    Log:Info("DataTable %s: %s", self.mutableTableName, Utils:T2S(self.mutableTableData))
end

--清理数据
function DataComponent:ClearData(tableName)
    local keyStr = self:GetTableName(tableName)
    local data = {}
    if self.debugEnabled then
        Log:Debug("%s:ClearData : %s", tableName, Utils:T2S(data))
    end
    CloudService:SetTabAsync(keyStr, data, function(status)
    end)
end

--清理所有数据
function DataComponent:ClearAllData()
    self:ClearData(self.tableName)
    self:ClearData(self.mutableTableName)
end

--获取表对象
function DataComponent:GetTable(tableName)
    for k, v in ipairs(self.tables) do
        if v.name == tableName then
            return v
        end
    end
end

--获取易变表对象
function DataComponent:GetMutableTable(tableName)
    for k, v in ipairs(self.mutableTables) do
        if v.name == tableName then
            return v
        end
    end
end
--获取表名
function DataComponent:GetTableName(tableName)
    local serverId = self:GetServerId(self.actor) or 0
    local playerId = self:GetPlayerId(self.actor) or 0
    local keyStr = self.version..".".. playerId .. "." .. serverId .. "." .. tableName
    return keyStr
end

--获取服务器Id
function DataComponent:GetServerId(obj)
    local serverId = nil
    if obj.GetServerId then
        serverId = obj:GetServerId()
    end
    if serverId == nil and obj.actor then
        serverId = obj.actor:GetServerId()
    end
    return serverId
end
--获取玩家Id
function DataComponent:GetPlayerId(obj)
    local playerId = nil
    if obj.GetPlayerId then
        playerId = obj:GetPlayerId()
    end
    if playerId == nil and obj.actor then
        playerId = obj.actor:GetPlayerId()
    end
    return playerId
end


return DataComponent