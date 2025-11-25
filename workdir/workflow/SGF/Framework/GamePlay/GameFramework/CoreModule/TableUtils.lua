--[[
    TableUtils - GameFramework专用表工具类

    ⚠️ 重要说明：
    这是GameFramework内部使用的表工具，提供了特定的业务功能。
    如果你需要通用的表操作（如深拷贝、深度合并、map/reduce等），
    请使用 Framework/Utils/TableUtils.lua

    本工具的特色功能：
    - RemoveAll: 批量移除符合条件的元素
    - GetPageData: 分页数据获取
    - ToString: 复杂的格式化输出（支持循环引用检测）
    - GetNext/GetPrevious: 支持循环的列表遍历
    - InsertUnique: 去重插入

    使用方式：
    local TableUtils = GFScript("CoreModule.TableUtils")
    TableUtils:RemoveAll(list, function(item) return item.id == targetId end)

    Date: 2024年9月11日
    Author: 揭育龙
    Copyright (c) 2024 迷你创想. All rights reserved.
]]
local Json = GFScript("CoreModule.Json")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Bit = GFScript("CoreModule.Bit")

local TableUtils = {}

--移除列表中的所有元素
function TableUtils:RemoveAll(t, func)
    local i = 1
    while i <= #t do
        if func(t[i]) then
            table.remove(t, i)
        else
            i = i + 1
        end
    end
end

--获取分页数据
function TableUtils:GetPageData(array, currentPage, pageSize)
    if not array or #array == 0 then
        return {}
    end
    
    -- 参数验证和默认值
    currentPage = currentPage or 1
    pageSize = pageSize or 10
    
    -- 确保页码从1开始
    if currentPage < 1 then
        currentPage = 1
    end
    
    -- 计算总页数
    local totalItems = #array
    local totalPages = math.ceil(totalItems / pageSize)
    
    -- 如果当前页超出总页数，返回空数组
    if currentPage > totalPages then
        return {}
    end
    
    -- 计算起始和结束索引
    local startIndex = (currentPage - 1) * pageSize + 1
    local endIndex = math.min(currentPage * pageSize, totalItems)
    
    -- 提取当前页的数据
    local pageData = {}
    for i = startIndex, endIndex do
        table.insert(pageData, array[i])
    end
    
    return pageData
end

--获取列表中符合条件的元素
function TableUtils:FindAll(t, func)
    local result = {}
    for i = 1, #t do
        if func(t[i]) then
            table.insert(result, t[i])
        end
    end
    return result
end
--获取列表中符合条件的元素索引
function TableUtils:IndexOf(t, value)
    for i = 1, #t do
        if t[i] == value then
            return i
        end
    end
    return -1
end

--插入元素，去重
function TableUtils:InsertUnique(t, value)
    if self:IndexOf(t, value) == -1 then
        table.insert(t, value)
    end
end

--2024-12-29 18:35 TODO : 字符串拼接耗时 
function TableUtils:ToString(value, indent, vmap)
    --{{{
    local str = ''
    indent = indent or ''
    vmap = vmap or {}

    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            
            if string.byte(value,1) == 91 then 
                str = string.format("'%s'", value)
            else
                if value:match('%[') then 
                    str = string.format('"%s"', value)
                else
                    str = string.format("[[%s]]", value)
                end 
            end 

        else
            str = tostring(value)
        end
    else
        if type(vmap) == 'table' then
            if vmap[value] then return '('..tostring(value)..')' end
            vmap[value] = true
        end
        local auxTable = {}
        local iauxTable = {}
        local iiauxTable = {}
        for i, v in pairs(value) do
            if type(i) == 'number' then
                if i == 0 then
                    table.insert(iiauxTable, i)
                else
                    table.insert(iauxTable, i)
                end
            else
                table.insert(auxTable, i)
            end
        end 

        table.sort(iauxTable)

        str = str..'{\n'
        local separator = ""
        local entry = "\n"
        local barray = true
        local kk,vv
        for i, k in ipairs (iauxTable) do 
            if i == k and barray then
                entry = self:ToString(value[k], indent..'    ', vmap)
                str = str..separator..indent..'    '..entry
                separator = ", \n"
            else
                barray = false
                table.insert(iiauxTable, k)
            end
        end 
        for i, fieldName in ipairs (iiauxTable) do 
            kk = tostring(fieldName)
            if type(fieldName) == "number" then kk = '['..kk.."]" end 
            if type(fieldName) == "string" and (fieldName:match("%.") or fieldName:match("-")) then kk = '["'..kk..'"]' end 
            entry = kk .. " = " .. self:ToString(value[fieldName],indent..'    ',vmap)

            str = str..separator..indent..'    '..entry
            separator = ", \n"
        end 
        for i, fieldName in ipairs (auxTable) do 
            kk = tostring(fieldName)
            if type(fieldName) == "number" then kk = '['..kk.."]" end 
            if type(fieldName) == "string" and (fieldName:match("%.") or fieldName:match("-"))then kk = '["'..kk..'"]' end 

            vv = value[fieldName]
            entry = kk .. " = " .. self:ToString(value[fieldName],indent..'    ',vmap)


            str = str..separator..indent..'    '..entry
            separator = ", \n"
        end 
        str = str..'\n'..indent..'}'
    end
    return str
    --}}}
end

--过滤表
function TableUtils:Filter(t, func)
    local result = {}
    for i = 1, #t do
        if func(t[i]) then
            table.insert(result, t[i])
        end
    end
    return result
end

function TableUtils:Contains(t, value)
    for i = 1, #t do
        if t[i] == value then
            return true
        end
    end
    return false
end

function TableUtils:GetNext(t, currentIndex, loop)
    if loop then
        if currentIndex >= #t then
            return t[1], 1, true
        end
        return t[currentIndex + 1], currentIndex + 1
    else
        if currentIndex >= #t then
            return nil, 0, true
        end
        return t[currentIndex + 1], currentIndex + 1
    end
end

function TableUtils:GetPrevious(t, currentIndex, loop)
    if loop then
        if currentIndex <= 1 then
            return t[#t], #t, true
        end
        return t[currentIndex - 1], currentIndex - 1
    else
        if currentIndex <= 1 then
            return nil, 0, true 
        end
        return t[currentIndex - 1], currentIndex - 1
    end
end


return TableUtils