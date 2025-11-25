-- 说明:UILog类
-- 日期:2024年2月20日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.
local UILog = {}

-- 日志等级
UILog.UILogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- 当前日志等级，默认为DEBUG
UILog.currentLevel = UILog.UILogLevel.ERROR
UILog.logTag = nil

UILog.errorCallback = nil

-- 打印日志
function UILog:Print(level, levelTag, message)
    if level >= UILog.currentLevel then
        if UILog.logTag then
            print("["..UILog.logTag.."]".."["..levelTag.."] "..message)
        else
            print("["..levelTag.."] "..message)
        end
    end
end

-- 设置日志等级
function UILog:SetUILogLevel(level)
    UILog.currentLevel = level
end
-- 设置日志标签
function UILog:SetUILogTag(tag)
    UILog.logTag = tag
end
--设置错误打印回调
function UILog:SetErrorCallback(callback)
    UILog.errorCallback = callback
end
--输出错误
function UILog:Error(...)
    local msg = self:FormatString(...)
    self:Print(UILog.UILogLevel.ERROR,"ERROR", msg)
    if UILog.errorCallback then
        UILog.errorCallback(msg)
    end
end
--输出警告
function UILog:Warn(...)
    local msg = self:FormatString(...)
    self:Print(UILog.UILogLevel.WARN,"WARN", msg)
end
--输出调试
function UILog:Debug(...)
    local msg = self:FormatString(...)
    self:Print(UILog.UILogLevel.DEBUG,"DEBUG", msg)
end
--输出信息
function UILog:Info(...)
    local msg = self:FormatString(...)
    self:Print(UILog.UILogLevel.INFO,"INFO", msg)
end

--格式化参数字符串
function UILog:FormatString(...)
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
function UILog:Debug2(...)
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

return UILog
