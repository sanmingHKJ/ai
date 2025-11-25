local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local Profiler = GFScript("CoreModule.Profiler")
local ActorManager = GFScript("ActorModule.ActorManager")

local NetworkPacker = {}

NetworkPacker.profilerEnabled = false

--序列化处理器列表
NetworkPacker.serializer = {}
--解包为对象
function NetworkPacker:UnpackActor(body, isServer) 
    if body.nid then
        local identity = isServer and ActorManager:GetServerNetActor(body.nid) or ActorManager:GetClientNetActor(body.nid)
        return identity
    end
    return nil
end
function NetworkPacker:UnpackObj(body, isServer) 
    local obj = self:UnpackActor(body, isServer)
    if obj then
        if body.snid then
            return obj:GetSubNetObject(body.snid)
        else
            return obj
        end
    end
    return nil
end
--序列化
function NetworkPacker:Serialize(data)
    local dataType = type(data)
    if dataType == "table" and data.NetDataType then
        local serializer = self.serializer[data.NetDataType]
        if serializer and serializer.Serialize then
            local packData = nil
            if serializer.Obj then
                packData = serializer.Serialize(serializer.Obj, data)
            else
                packData = serializer.Serialize(data)
            end
            packData.nt = data.NetDataType
            return packData
        else
            Log:Error("NetworkPacker:Serialize data.NetDataType = %s", tostring(data.NetDataType))
            return nil
        end
    end
    return data
end

--反序列化
function NetworkPacker:Deserialize(data, isServer)
    local dataType = type(data)
    if dataType == "table" and data.nt then
        local serializer = self.serializer[data.nt]
        if serializer and serializer.Deserialize then
            local obj = nil
            if serializer.Obj then
                obj = serializer.Deserialize(serializer.Obj, data, isServer)
            else
                obj = serializer.Deserialize(data, isServer)
            end
            return obj
        end
    end
    return data
end

--递归序列化
function NetworkPacker:RecursiveSerialize(data)
    if type(data) == "table" and not data.NetDataType then
        local newData = {}
        for k,v in pairs(data) do
            newData[k] = self:RecursiveSerialize(v)
        end
        return newData
    else
        return self:Serialize(data)
    end
end

--递归反序列化
function NetworkPacker:RecursiveDeserialize(data,isServer)
    if type(data) == "table" and not data.nt then
        local newData = {}
        for k,v in pairs(data) do
            newData[k] = self:RecursiveDeserialize(v,isServer)
        end
        return newData
    else
        return self:Deserialize(data,isServer)
    end
end

--注册序列化处理器
function NetworkPacker:RegisterSerializer(NetDataType, serialize, deserialize)
    self.serializer[NetDataType] = {Serialize = serialize, Deserialize = deserialize}
end

--注册序列化处理器
function NetworkPacker:Setup(NetDataType, obj)
    obj.NetDataType = NetDataType
    self.serializer[NetDataType] = {Obj = obj, Serialize = obj.NetSerialize, Deserialize = obj.NetDeserialize}
end

--根据给定内容进行打包
function NetworkPacker:Pack(rpc, data)
    if NetworkPacker.profilerEnabled then
        local name = data.rpcName or data.cmdName
        Profiler:Start("Pack: "..tostring(name),0.1)
    end
    local packData = {
        rpc = rpc, 
        data = self:RecursiveSerialize(data)
    }
    if NetworkPacker.profilerEnabled then
        Profiler:Stop()
    end
    return packData
end

--根据给定内容进行解包,返回rpc, data, comp
function NetworkPacker:Unpack(body, isServer)
    if NetworkPacker.profilerEnabled then
        local name = body.rpcName or body.cmdName
        Profiler:Start("Unpack: "..tostring(name),0.1)
    end
    local data = self:RecursiveDeserialize(body.data,isServer)
    if NetworkPacker.profilerEnabled then
        Profiler:Stop()
    end
    return body.rpc, data
end

--压缩名称映射
local nameToHash = {}
--压缩名称反向映射
local hashToName = {}

--压缩
function NetworkPacker:Compress(srcData)
    if type(srcData) == "string" then
        if not nameToHash[srcData] then
            local hash = Utils:HashString(srcData)
            nameToHash[srcData] = hash
            hashToName[hash] = srcData
        end
        return nameToHash[srcData]
    end
    return srcData
end

--解压缩
function NetworkPacker:Decompress(srcData)
    if type(srcData) == "integer" then
        return hashToName[srcData] or srcData
    end
    return srcData
end

--递归压缩
function NetworkPacker:RecursiveCompress(srcData)
    if type(srcData) ~= "table" then
        return self:Compress(srcData)
    end
    
    local dstData = {}
    for k, v in pairs(srcData) do
        local compressedKey = self:Compress(k)
        dstData[compressedKey] = self:RecursiveCompress(v)
    end
    return dstData
end

--递归解压缩
function NetworkPacker:RecursiveDecompress(srcData)
    if type(srcData) ~= "table" then
        return self:Decompress(srcData)
    end
    
    local dstData = {}
    for k, v in pairs(srcData) do
        local decompressedKey = self:Decompress(k)
        dstData[decompressedKey] = self:RecursiveDecompress(v)
    end
    return dstData
end

return NetworkPacker