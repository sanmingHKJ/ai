local Utils = GFScript("CoreModule.Utils")
local Log = {}

-- 日志等级
Log.LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- 当前日志等级，默认为DEBUG
Log.currentLevel = Log.LogLevel.ERROR
Log.logTag = nil

Log.errorCallback = nil

--记录错误的日记
function Log:StartRecordError()
    self.recordError = true
    self.errorLog = {}
end

--停止记录错误的日记
function Log:StopRecordError()
    self.recordError = false
    local resultString = nil
    if #self.errorLog > 0 then
        resultString = ""
        for i, v in ipairs(self.errorLog) do
            resultString = resultString .. v .. "\n"
        end
    end
    self.errorLog = nil
    return resultString
end

-- 打印日志
function Log:Print(level, levelTag, message)
    if level >= Log.currentLevel then
        --判断message是不是表
        if type(message) == "table" then
            message = Utils:T2S(message)
        end
        local text = nil
        if Log.logTag then
            text = "["..Log.logTag.."]".."["..levelTag.."] "..message
        else
            text = "["..levelTag.."] "..message
        end
        print(text)
    end
end

-- 设置日志等级
function Log:SetLogLevel(level)
    Log.currentLevel = level
end
-- 设置日志标签
function Log:SetLogTag(tag)
    Log.logTag = tag
end
--设置错误打印回调
function Log:SetErrorCallback(callback)
    Log.errorCallback = callback
end
--输出错误
function Log:Error(...)
    local msg = self:FormatString(...)
    self:Print(Log.LogLevel.ERROR,"ERROR", msg)
    if Log.errorCallback then
        Log.errorCallback(msg)
    end
    if self.recordError then
        table.insert(self.errorLog, msg)
    end
end
--输出警告
function Log:Warn(...)
    local msg = self:FormatString(...)
    self:Print(Log.LogLevel.WARN,"WARN", msg)
end
--输出调试
function Log:Debug(...)
    local msg = self:FormatString(...)
    self:Print(Log.LogLevel.DEBUG,"DEBUG", msg)
end
--输出信息
function Log:Info(...)
    local msg = self:FormatString(...)
    self:Print(Log.LogLevel.INFO,"INFO", msg)
end

--格式化参数字符串
function Log:FormatString(...)
    --获取参数
    local args = {...}
    --获取参数个数
    local argCount = #args
    if argCount > 1 then
        return string.format(...)
    end
    return tostring(args[1])
end



-- lua-table 转字符串（打印日志使用）(有最大10层的层数保护，可以避免循环互相引用)
local function table2str(tbl, level_, visited)
    level_ = level_ or 0
    if  level_ >= 10 then
        print( 'ERROR table2str level>=10' )
        return  ''  --层数保护
    end

    visited = visited or {}    --防止两个table互相引用，互相循环

    local tab = { '{' }
    for k, v in pairs(tbl) do
        if  type(v) == 'table' then
            if  visited[ v ] then
                tab[#tab+1] = tostring(v)
            else
                visited[ v ] = true      --table作为key等同于tostring(v)
                tab[#tab+1] = tostring(k) .. '=' .. table2str(v, level_+1, visited )
            end
        elseif  type(v) == 'function' or type(v) == 'userdata' or type(v) == 'thread' then
            -- 忽略不打印
        else
            tab[#tab+1] = tostring(k) .. '=' .. tostring(v)
        end
    end

    tab[#tab+1] = '}'
    return table.concat(tab,' ')
end


-- lua-table 转字符串（打印日志使用）(有最大10层的层数保护，可以避免循环互相引用)
local function table2strDebug(tbl, level_, visited, path_)
    level_ = level_ or 0
    if  level_ >= 10 then
        --for kk_, vv_ in pairs(tbl) do
            --print(  "ERROR kk===" .. tostring(kk_) )
        --end
        print( 'ERROR table2str level>=10', path_, debug.traceback() )
        return  ''  --层数保护
    end

    visited = visited or {}    --防止两个table互相引用，互相循环

    --path_ = path_ or ''

    local tab = { '{' }
    for k, v in pairs(tbl) do
        if  type(v) == 'table' then
            if  visited[ v ] then
                tab[#tab+1] = tostring(v)
            else
                visited[ v ] = true      --table作为key等同于tostring(v)
                local path1_ = (path_ or '') .. '.(' .. level_ .. ')=' .. tostring(k) .. ''
                tab[#tab+1] = tostring(k) .. '=' .. table2str(v, level_+1, visited, path1_ )
            end
        elseif  type(v) == 'function' or type(v) == 'userdata' or type(v) == 'thread' then
            -- 忽略不打印
        else
            tab[#tab+1] = tostring(k) .. '=' .. tostring(v)
        end
    end

    tab[#tab+1] = '}'
    return table.concat(tab,' ')
end



--打印日志使用(可以打印table)
function Log:Debug2(...)
    ----[[   --屏蔽Debug2日志 haima test
    local args = {...}
    local tab = {}
    for i, v in ipairs(args) do
        if  type(v) == 'table' then
            tab[i] = table2str(v)
        else
            tab[i] = tostring(v)
        end
    end

    local str_ = table.concat(tab,' ')
    if  #str_ > 2048 then
        print( 'ERROR print_log too long:', #str_, debug.traceback() )
    end
    print( string.sub( str_, 1, 2048 ) )
    --]]
end

return Log
