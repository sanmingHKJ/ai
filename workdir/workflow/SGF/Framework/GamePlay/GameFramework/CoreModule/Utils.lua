local Json = GFScript("CoreModule.Json")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Path = GFScript("CoreModule.Math.Path")
local Quat = GFScript("CoreModule.Math.Quat")
local Bit = GFScript("CoreModule.Bit")
local ActorDefines = GFScript("ActorModule.ActorDefines")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local WorldService = game:GetService("WorldService")
local UtilService = game:GetService("UtilService")
local Utils = {}

--将表转换为字符串
function Utils:T2S(value)
	return Json.encode(value)
end
--深拷贝
function Utils:DeepCopy(orig, customCopy)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils:DeepCopy(orig_key)] = Utils:DeepCopy(orig_value)
        end
        setmetatable(copy, Utils:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        if customCopy then
            copy = customCopy(orig)
        else
            copy = orig
        end
    end
    return copy
end
--浅拷贝
function Utils:ShallowCopy(orig, customCopy)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = Utils:ShallowCopy(orig_value,customCopy)
        end
    else -- number, string, boolean, etc
        if customCopy then
            copy = customCopy(orig)
        else
            copy = orig
        end
    end
    return copy
end

--分割字符串
function Utils:Split(str,char)
    local res = {}
    local pos
    for str in (str..char):gmatch("(.-)"..char) do
        res[#res+1] = str
    end
    return res
end
--分割成数字
function Utils:SplitToNumber(str,char)
    local res = {}
    local pos
    for str in (str..char):gmatch("(.-)"..char) do
        res[#res+1] = tonumber(str)
    end
    return res
end

--通过.号分割字符串
function Utils:SplitByDot(str)
    local result = {}
    local regex = ("([^%s]+)"):format(".")
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

--根据自定义属性节点合并数据到配置
function Utils:MergeConfig(config,data)
    --通过.号分割scriptName
    local function split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    return Utils:ShallowCopy(config,
    function(value)
        if type(value) == "string" then
            if Utils:StartWith(value,"@") then
                local name = string.sub(value,2)
                local nameList = split(name, ".")
                local dataRef = data
                if dataRef then
                    for _, n in ipairs(nameList) do
                        dataRef = dataRef[n]
                        if dataRef == nil then
                            -- print("Can not find AttrName : "..n)
                            break
                        end
                    end
                end
                return dataRef
            else
                return value
            end
            
        else
            return value
        end
    end)
end
-- --参数示例
-- local Params = {
--     "CastCost" = {
--         type = "float",
--         default = 0,
--         range = {
--             min = 0,
--             max = 100
--         },
--         value = 1,
--     },
--     "Cooldown" = {
--         type = "float",
--         default = 0,
--         range = {
--             min = 0,
--             max = 100
--         }
--         value = 1,
--     },
-- }
--应用参数到配置
function Utils:ApplyParams(config,params)
    --通过.号分割scriptName
    local function split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    return Utils:ShallowCopy(config,
    function(value)
        if type(value) == "string" then
            if Utils:StartWith(value,"#") then
                local name = string.sub(value,2)
                local nameList = split(name, ".")
                local dataRef = params
                if dataRef then
                    for _, n in ipairs(nameList) do
                        dataRef = dataRef[n]
                        if dataRef == nil then
                            -- print("Can not find AttrName : "..n)
                            break
                        end
                    end
                end
                return dataRef
            else
                return value
            end
            
        else
            return value
        end
    end)
end

--获取当前模块
function Utils:GetModule()
    return require(script.Parent.Parent)
end
--是否客户端
function Utils:IsClient()
    return RunService:IsClient()
end
--是否服务端
function Utils:IsServer()
    return RunService:IsServer()
end
--是否主机
function Utils:IsHost()
    return RunService:IsClient() and RunService:IsServer()
end

--是否仅是客户端
function Utils:IsClientOnly()
    return RunService:IsClient() and not RunService:IsServer()
end

--是否仅是服务端
function Utils:IsServerOnly()
    return RunService:IsServer() and not RunService:IsClient()
end

--获取本地玩家
function Utils:GetLocalPlayer()
    if RunService:IsClient() then
        return Players.LocalPlayer
    end
    return nil
end

--获取本地玩家id
function Utils:GetLocalPlayerId()
    if RunService:IsClient() then
        return Players.LocalPlayer.UserId
    end
    return nil
end

--根据id获取玩家
function Utils:GetOwnerPlayer(playerId)
    return Players:GetPlayerByUserId(playerId)
end

--获取系统时间，单位秒
function Utils:GetSystemTime()
    -- return os.time()
    return RunService:CurrentSteadyTimeStampMS() / 1000
end

--获取当前服务器时间，单位秒
function Utils:GetServerTime()
    if self:IsClientOnly() then
        local localTime = self:GetLocalTime()
        if self.serverTimeOffset then
            return localTime + self.serverTimeOffset
        end
        return localTime
    end
    return self:GetSystemTime()
end

--获取当前时间是周几
function Utils:GetDayOfWeek()
    local time = os.date("*t")
    return time.wday
end

--获取当前时间是当天的第几小时
function Utils:GetHourOfDay()
    local time = os.date("*t")
    return time.hour
end

function Utils:SetServerTimeOffset(timeOffset)
    if self.serverTimeOffset == nil then
        --初始化
        self.serverTimeOffset = timeOffset
    elseif timeOffset > 0 and self.serverTimeOffset < 0 or timeOffset < 0 and self.serverTimeOffset > 0 then
        --不同符号
        self.serverTimeOffset = timeOffset
    elseif math.abs(timeOffset) < math.abs(self.serverTimeOffset) then
        --同符号
        self.serverTimeOffset = timeOffset
    end
end

--获取本地时间，单位秒
function Utils:GetLocalTime()
    return self:GetSystemTime()
end

--计算字符串哈希值
function Utils:HashString(input)
    local hash = 0
    for i = 1, #input do
        hash = (hash * 33 + string.byte(input, i)) % 0x7FFFFFFF
    end
    return hash
end

--移动数组元素
function Utils:MoveArrayElement(arr, fromIndex, toIndex)
    if fromIndex == toIndex then return arr end
    local element = table.remove(arr, fromIndex)
    table.insert(arr, toIndex, element)
    return arr
end

--唯一id信息记录
local last_time = 0
local counter = 0
--生成唯一id
function Utils:GenerateUniqueId()
    -- local current_time = self:GetDaySeconds()
    -- if current_time ~= last_time then
    --     counter = 0 -- 每秒重置计数器
    -- end
    -- last_time = current_time
    -- counter = counter + 1
    -- return current_time * 1000000 + counter
    return self:HashString(UtilService:GetGlobalUniqueID())
end

--生成唯一token
function Utils:GenerateToken(prefix)
    prefix = prefix or ""
    local id = UtilService:GetGlobalUniqueID()
    local token = string.format("%s_%s", prefix, id)
    return token
end

--生成hash token
function Utils:GenerateHashToken(prefix)
    local token = self:GenerateToken(prefix)
    local hash = self:HashString(token)
    return hash
end

--获取当前是当天的第几秒
function Utils:GetDaySeconds()
    local time = os.date("*t")
    return time.hour * 3600 + time.min * 60 + time.sec
end

-- 秒数 格式化输出为 xD xx:xx:xx
function Utils:Time2string(time)
    if time < 0 then
        return "00:00:00"
    end
    local hour = math.floor((time / 3600) % 24)
    local minute = math.fmod(math.floor(time / 60), 60)
    local second = math.fmod(time, 60)

    local str = "" -- string.format("%02d:%02d:%02d",hour,minute,second)

    if time >= 3600 * 24 then
        local day = math.floor(time / (3600 * 24))
        local hour = math.floor((time / 3600) % 24)
        local minute = math.fmod(math.floor(time / 60), 60)
        local second = math.fmod(time, 60)
        if hour == 0 and minute == 0 and second == 0 then
            str = day .. "D "
        else
            str = day .. "D " .. str
        end
    elseif time > 3600 then
        str = string.format("%02d:%02d:%02d", hour, minute, second)
    else
        str = string.format("%02d:%02d", minute, second)
    end

    return str
end

--判断字符串是否以某个字符串开头
function Utils:StartWith(str,startStr)
    return str:sub(1, #startStr) == startStr
end
--判断字符串是否以某个字符串结尾
function Utils:EndWith(str, endStr)
    return str:sub(-#endStr) == endStr
end

function Utils:RemovePrefix(str, prefix)
    return str:sub(#prefix + 1)
end

function Utils:GetNode(path, rootNode)
    --通过.号分割path
    local function split(str, sep)
        local result = {}
        local regex = ("([^%s]+)"):format(sep)
        for each in str:gmatch(regex) do
            table.insert(result, each)
        end
        return result
    end
    local nodeNameList = split(path, ".")
    if #nodeNameList == 0 then
        return nil
    end
    local node = rootNode
    if node then
        for _, name in ipairs(nodeNameList) do
            node = node[name]
            if node == nil then
                print("Can not find node : "..name)
                break
            end
        end
    end
    return node
end
--根据路径获取MainStorage下的节点
function Utils:GetMainStorageNode(path)
    local MainStorage = game:GetService("MainStorage")
    return self:GetNode(path, MainStorage)
end

--根据路径获取ServerStorage下的节点
function Utils:GetServerStorageNode(path)
    local ServerStorage = game:GetService("ServerStorage")
    return self:GetNode(path, ServerStorage)
end

--获取UI节点
function Utils:GetUINode(path)
    local Players = game:GetService("Players")
    return self:GetNode(path, Players.LocalPlayer.PlayerGui)
end

--根据路径获取ConfigGroup下的节点
function Utils:GetConfigGroupNode(path)
    local nodeNameList = self:SplitByDot(path)
    if #nodeNameList == 0 then
        print("Can not find path : "..path)
        return nil
    end
    --自定义节点
    local CustomConfigService = game:GetService("CustomConfigService")
    if CustomConfigService then
        local node = CustomConfigService.ConfigGroup
        if node then
            for _, name in ipairs(nodeNameList) do
                node = node[name]
                if node == nil then
                    print("Can not find node : "..name)
                    break
                end
            end
            return node
        end
        return nil
    end
    return nil
end

--获取地面物体
function Utils:GetHitObject(pos,dir, distance)
    local result = WorldService:RaycastClosest(Vector3.New(pos.x,pos.y,pos.z), Vector3.New(dir.x,dir.y,dir.z),distance,true,ActorDefines.ObstacleCollisionGroup)
    if result.isHit then
        return result.obj
    end
    return nil
end

--取某个坐标的地面位置
function Utils:GetGroundPosition(pos)
    local heightOffset = 100
    local result = WorldService:RaycastClosest(Vector3.New(pos.x,pos.y + heightOffset,pos.z), Vector3.New(0,-1,0),10000,true,ActorDefines.ObstacleCollisionGroup)
    if result.isHit then
        --+5是为了防止掉下去
        return Vec3.New(result.position.x,result.position.y + 5,result.position.z)
    end
    return pos
end
--取某个坐标的地面位置
function Utils:GetValidPosition(orginPos,targetPos)
    local heightOffset = 100
    local moveStep = targetPos - orginPos
    local distance = moveStep:Magnitude()
    local dir = moveStep:Normalized()
    local result = WorldService:RaycastClosest(Vector3.New(orginPos.x,orginPos.y + heightOffset,orginPos.z), Vector3.New(dir.x,dir.y,dir.z),distance,true,ActorDefines.ObstacleCollisionGroup)
    local resultPos = nil
    local isSafe = false
    if result.isHit then
        resultPos = Vec3.New(result.position.x,result.position.y,result.position.z)
        --往后退一点，避免出现意外
        resultPos = resultPos - dir * 50
    else
        resultPos = targetPos
        isSafe = true
    end
    return Utils:GetGroundPosition(resultPos), isSafe
end

--获取水平方向上的合法位置
function Utils:GetValidHorizontalPosition(orginPos,targetPos)
    local heightOffset = 100
    local moveStep = targetPos - orginPos
    local distance = moveStep:Magnitude()
    local dir = moveStep:Normalized()
    local result = WorldService:RaycastClosest(Vector3.New(orginPos.x,orginPos.y + heightOffset,orginPos.z), Vector3.New(dir.x,dir.y,dir.z),distance,true,ActorDefines.ObstacleCollisionGroup)
    local resultPos = nil
    local isSafe = false
    if result.isHit then
        resultPos = Vec3.New(result.position.x,result.position.y,result.position.z)
        --往后退一点，避免出现意外
        resultPos = resultPos - dir * 50
    else
        resultPos = targetPos
        isSafe = true
    end
    local groundPos = Utils:GetGroundPosition(resultPos)
    if groundPos.y > resultPos.y then
        return groundPos, false
    end
    resultPos.y = targetPos.y
    return resultPos, isSafe
end

--获取脚步信息,返回位置和tag
function Utils:GetFootstepInfo(pos)
    local heightOffset = 50
    local distance = 100
    local result = WorldService:RaycastClosest(Vector3.New(pos.x,pos.y + heightOffset,pos.z), Vector3.New(0,-1,0),distance,true,ActorDefines.FootStepCollisionGroup)
    if result.isHit then
        return true, Vec3.New(result.position.x,result.position.y,result.position.z), result.obj.Tag
    end
    return false
end
--计算一个位置到另外一个位置的滑墙距离
function Utils:CalcSlidePosition(pos1, pos2, radius)
    local dir = pos2 - pos1
    local distance = dir:Magnitude()
    dir:Normalize()

    local orginPos = Vector3.New(pos1.x,pos1.y,pos1.z)
    local direction = Vector3.New(dir.x,dir.y,dir.z)
    --{isHit ,normal ,position , distance ,obj}
    local ret = WorldService:SweepSphere(radius, orginPos, direction, distance,true,ActorDefines.ObstacleCollisionGroup)
    if ret.isHit then
        if ret.distance < distance then
            local hitNormal = Vec3(ret.normal.x,ret.normal.y,ret.normal.z)
            --计算新方向
            local newDir = hitNormal:Cross(Vec3(0,1,0))
            if newDir:Magnitude() > 0.01 then
                newDir:Normalize()
                return pos1 + newDir * distance
            end
            --继续递归
            return self:CalcSlidePosition(ret.position, ret.position, radius)
        else
            return ret.position
        end
    end
    return pos2
end
--传送
function Utils:TeleportTo(character, pos)
    local TeleportService = game:GetService('TeleportService')
    TeleportService:Teleport(character, Vector3.New(pos.x,pos.y,pos.z))
end
--判断一个值是否在某个table中
function Utils:IsInTable(table,value)
    if table == nil then
        return false
    end
    for _,v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end
--运动圆监测，返回是否碰撞，碰撞点，碰撞方向
function Utils:SweepSphere(pos,dir,distance, collisionGroup, radius)
    collisionGroup = collisionGroup or ActorDefines.ObstacleCollisionGroup
	radius = radius or 50
    local result = WorldService:SweepSphere(radius, Vector3.New(pos.x,pos.y,pos.z), 
                                                Vector3.New(dir.x,dir.y,dir.z),distance,true,collisionGroup)

    if result.isHit then
        local normal = Vec3.New(result.normal.x,result.normal.y,result.normal.z)
        local quat = Quat.New()
        quat:FromLookRotation(normal,Vec3.New(0,1,0))
        return true, result.position, Quaternion.New(quat.x,quat.y,quat.z,quat.w)
    end
    return false
end
--圆形检测
function Utils:RayObj(obj, pos,dir,distance, collisionGroup)
    collisionGroup = collisionGroup or ActorDefines.ObstacleCollisionGroup
    local results = WorldService:RaycastAll(Vector3.New(pos.x,pos.y,pos.z), 
                                                Vector3.New(dir.x,dir.y,dir.z),distance,true,collisionGroup)
    for _,v in pairs(results) do
        if v.obj == obj then
            local normal = Vec3.New(v.normal.x,v.normal.y,v.normal.z)
            local quat = Quat.New()
            quat:FromLookRotation(normal,Vec3.New(0,1,0))
            return true, v.position, Quaternion.New(quat.x,quat.y,quat.z,quat.w)
        end
    end
    return false
end


--查找路径
function Utils:FindNavigatePath(startPos, targetPos)
    local radius = 50
    local height = 200
    local stepOffset = 50
    local slopLimit = 45
    local pos1 = Vector3.New(startPos.x,startPos.y,startPos.z)
    local pos2 = Vector3.New(targetPos.x,targetPos.y,targetPos.z)
    local WorldService = game:GetService("WorldService")
    local character = self:GetCharacter()
    local param = { 
        Radius = radius, 
        Heigh = height, 
        StepOffset = stepOffset, 
        SlopLimit = slopLimit, 
        CollideGroupID = 1
    }
    local path = WorldService:CreatePath(param)
    path:GeneratePathsAsync(pos1, pos2)
    local paths = path:GetPaths()
    if paths == nil or #paths == 0 then
        return nil
    else
        local p = Path.New()
        for i=1,#paths do
            local point = paths[i]
            p:Add(Vec3.New(point.x,point.y,point.z))
        end
        return p
    end
end
--判断字符串是否为空
function Utils:IsNullOrEmpty(str)
    return str == nil or str == ""
end
--判断值是否为空或0
function Utils:IsNullOrZero(value)
    return value == nil or value == 0
end
--添加flag
function Utils:AddFlag(flag, value)
    return Bit:_or(flag, value)
end
--移除flag
function Utils:RemoveFlag(flag, value)
    return Bit:_and(flag, Bit:_not(value))
end
--判断flag
function Utils:HasFlag(flag, value)
    return Bit:_and(flag, value) == value
end
Utils.maxSubNetId = 10000000
Utils.autoIdIndex = 0
Utils.autoSubNetIdIndex = 0
--生成ActorId
function Utils:GenerateActorId(preName, obj)
    -- return obj.Name
    self.autoIdIndex = self.autoIdIndex + 1
    return preName .. tostring(self.autoIdIndex), self.autoIdIndex
end
--生成子网络id
function Utils:GenerateSubNetId()
    self.autoSubNetIdIndex = self.autoSubNetIdIndex + 1
    if self.autoSubNetIdIndex > Utils.maxSubNetId then
        self.autoSubNetIdIndex = 1
    end
    return self.autoSubNetIdIndex
end

--判断是否是玩家id
function Utils:IsPlayerId(actorId)
    return self:StartWith(actorId, 'Player')
end

--获取ActorId
function Utils:GetActorId(obj)
    if not obj then
        return nil
    end
    if type(obj) == "number" then
        return obj
    end
    if type(obj) == "string" then
        return obj
    end
    if obj.Character then
        local actorId = obj.Character:GetAttribute("ActorId")
        return actorId
    end
    local actorId = obj:GetAttribute("ActorId")
    return actorId
end
--设置ActorId
function Utils:SetActorId(obj, actorId)
    if not obj then
        return
    end
    if obj.Character then
        obj.Character:SetAttribute("ActorId", tostring(actorId))
        return
    end
    obj:SetAttribute("ActorId", tostring(actorId))
end

--可读格式
function Utils:ReadableFormat(n)
    -- 一万到一亿减一
    if n >= 10000 and n < 100000000 then
        local thousand =  math.floor(n / 1000)
        local digit = thousand / 10
        return tostring(digit) .. "万"
    end
    
    if n >= 100000000 then
        local tm = math.floor(n / 10000000)
        local digit = tm / 10
        return tostring(digit) .. "亿"
    end

    return tostring(n)
end

--安全调用
function Utils:PCall(func)
    local ok, errmsg = xpcall(function()
        func()
    end,debug.traceback)
    if not ok then
        print("Lua Error: "..tostring(errmsg))
    end
    return ok, errmsg
end

--将"2015.05.20 12:00:00"转换为时间戳
function Utils:ConvertToTimestamp(timeStr)
    return os.time(timeStr)
end

--将时间戳转换为"2015.05.20 12:00:00"
function Utils:ConvertToTimeStr(timestamp)
    return os.date("%Y.%m.%d %H:%M:%S", timestamp)
end

--获取当前时间戳
function Utils:GetCurrentTimestamp()
    return os.time()
end

--判断时间是否在某个时间段内
function Utils:IsInTimeRange(timestamp, startTime, endTime)
    return timestamp >= startTime and timestamp <= endTime
end

--查找子节点
function Utils:FindChild(control, controlName, recursive)
    recursive = (recursive == nil and true or recursive)
    local childControl = control[controlName]
    if childControl then
        return childControl
    end
    if recursive then
        for _, child in ipairs(control.Children) do
            local result = self:FindChild(child, controlName, recursive)
            if result then
                return result
            end
        end
    end
    return nil
end

--格式化数字为指定小数位
function Utils:FormatNumber(value, decimals)
    if type(value) ~= "number" then
        return tostring(value)
    end
    decimals = decimals or 0
    local str = string.format("%." .. decimals .. "f", value)
    --如果有小数点
    if string.find(str, "%.") then
        --去掉小数点后末尾的0
        str = str:gsub("0+$", "")
        --如果去掉0后只剩下小数点，也去掉小数点
        str = str:gsub("%.$", "")
    end
    return str
end

--格式化数字为百分比
function Utils:FormatPercentage(value, decimals)
    if type(value) ~= "number" then
        return tostring(value)
    end
    decimals = decimals or 2
    return self:FormatNumber(value * 100, decimals) .. "%"
end

--格式化时间
--@param value 时间值
--@param formatValue 格式化值 h2s,m2s,s, h2m,m,s2m,h
--@return 格式化后的时间字符串
function Utils:FormatTime(value, formatValue)
    local ret = value
    if formatValue == "h2s" then
        ret = value * 3600
    elseif formatValue == "m2s" then
        ret = value * 60
    elseif formatValue == "s" then
        ret = value
    elseif formatValue == "h2m" then
        ret = value * 60
    elseif formatValue == "m" then
        ret = value
    elseif formatValue == "s2m" then
        ret = value / 60
    elseif formatValue == "h" then
        ret = value
    end
    --保留两位小数点
    ret = string.format("%.2f", ret)
    --返回数字
    return tonumber(ret)
end

--格式化长度
function Utils:FormatLength(value, formatValue)
    if formatValue == "c2m" then--从厘米到米
        return self:FormatNumber(value / 100, 2) 
    elseif formatValue == "m2c" then--从米到厘米
        return self:FormatNumber(value * 100, 2)
    end
    return value 
end

--生成描述
function Utils:GenerateDesc(desc, paramsGetter)
    return desc:gsub("{%s*([^}:]+)%s*:?([^}:]*)%s*:?([^}]*)}", function(param, formatType, formatValue)
        local value = paramsGetter(param)
        if value == nil then
            return ""
        end
        
        -- 如果没有格式定义，直接返回字符串
        if formatType == "" then
            return tostring(value)
        end
        
        -- 解析格式值
        local decimals = tonumber(formatValue)
        
        -- 应用格式化
        if formatType == "float" then
            return self:FormatNumber(value, decimals)
        elseif formatType == "int" then
            return tostring(math.floor(value))
        elseif formatType == "time" then    
            return self:FormatTime(value, formatValue)
        elseif formatType == "length" then    
            return self:FormatLength(value, formatValue)
        elseif formatType == "growup" then
            return self:FormatNumber(1 + value, decimals)
        elseif formatType == "percentage" then
            return self:FormatPercentage(value, decimals)
        elseif formatType == "growupPer" then
            return self:FormatPercentage(1 + value, decimals)
        else
            -- 未知格式类型，返回原始值
            return tostring(value)
        end
    end)
end


--获取衍生值
function Utils:GetDerivedParamsValue(name, factor, params)
    if not params then
        return nil
    end
    if params.growUp and type(params[name]) == "number" and type(params.growUp[name]) == "number" then
        return params[name] + params.growUp[name] * factor
    end
    return params[name]
end

return Utils