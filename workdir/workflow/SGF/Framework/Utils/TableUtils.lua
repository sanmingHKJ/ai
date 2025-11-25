--[[
    TableUtils - SGF框架级表操作工具库

    这是框架级的通用表工具库，提供完整的表操作功能。

    ⚠️ 注意：
    GameFramework内部有自己的TableUtils（CoreModule.TableUtils），
    提供了特定的业务功能（分页、循环遍历、格式化输出等）。

    如果你在GameFramework内部开发，可以使用：
    local TableUtils = GFScript("CoreModule.TableUtils")

    如果你在框架级开发或需要通用功能，使用本工具：
    local TableUtils = require(Utils:WaitForChild("TableUtils"))

    Features:
    - Deep copying and merging (支持循环引用)
    - Array operations (map, filter, reduce, forEach)
    - Table querying and filtering (find, findAll, some, every)
    - Serialization helpers
    - Performance-optimized operations (对象池)

    使用方式：
    local copy = TableUtils.deepCopy(original)
    local merged = TableUtils.deepMerge(target, source)
    local filtered = TableUtils.filter(array, function(item) return item.active end)
]]

local TableUtils = {}

-- ===========================================
-- Basic Table Operations
-- ===========================================

--[[
    Deep copy a table
    @param original (table) Table to copy
    @param seen (table) Internal tracking for circular references
    @return (table) Deep copy of the table
]]
function TableUtils.deepCopy(original, seen)
    seen = seen or {}
    
    if type(original) ~= "table" then
        return original
    end
    
    if seen[original] then
        return seen[original]  -- Handle circular references
    end
    
    local copy = {}
    seen[original] = copy
    
    for key, value in pairs(original) do
        copy[TableUtils.deepCopy(key, seen)] = TableUtils.deepCopy(value, seen)
    end
    
    return setmetatable(copy, TableUtils.deepCopy(getmetatable(original), seen))
end

--[[
    Shallow copy a table
    @param original (table) Table to copy
    @return (table) Shallow copy of the table
]]
function TableUtils.shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

--[[
    Deep merge two tables
    @param target (table) Target table
    @param source (table) Source table to merge from
    @return (table) Merged table
]]
function TableUtils.deepMerge(target, source)
    target = target or {}
    
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            TableUtils.deepMerge(target[key], value)
        else
            target[key] = TableUtils.deepCopy(value)
        end
    end
    
    return target
end

--[[
    Check if table is empty
    @param tbl (table) Table to check
    @return (boolean) True if table is empty
]]
function TableUtils.isEmpty(tbl)
    return next(tbl) == nil
end

--[[
    Get number of elements in table (including non-array elements)
    @param tbl (table) Table to count
    @return (number) Number of elements
]]
function TableUtils.count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

--[[
    Get all keys from a table
    @param tbl (table) Table to get keys from
    @return (table) Array of keys
]]
function TableUtils.keys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

--[[
    Get all values from a table
    @param tbl (table) Table to get values from
    @return (table) Array of values
]]
function TableUtils.values(tbl)
    local values = {}
    for _, value in pairs(tbl) do
        table.insert(values, value)
    end
    return values
end

--[[
    Invert a table (keys become values, values become keys)
    @param tbl (table) Table to invert
    @return (table) Inverted table
]]
function TableUtils.invert(tbl)
    local inverted = {}
    for key, value in pairs(tbl) do
        inverted[value] = key
    end
    return inverted
end

-- ===========================================
-- Array Operations
-- ===========================================

--[[
    Check if table is an array (has sequential numeric indices)
    @param tbl (table) Table to check
    @return (boolean) True if table is an array
]]
function TableUtils.isArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    
    local count = 0
    for key, _ in pairs(tbl) do
        count = count + 1
        if type(key) ~= "number" or key ~= count then
            return false
        end
    end
    
    return true
end

--[[
    Find element in array
    @param array (table) Array to search
    @param element (any) Element to find
    @return (number) Index of element or nil
]]
function TableUtils.indexOf(array, element)
    for i, value in ipairs(array) do
        if value == element then
            return i
        end
    end
    return nil
end

--[[
    Check if array contains element
    @param array (table) Array to search
    @param element (any) Element to find
    @return (boolean) True if element exists
]]
function TableUtils.contains(array, element)
    return TableUtils.indexOf(array, element) ~= nil
end

--[[
    Remove element from array by value
    @param array (table) Array to modify
    @param element (any) Element to remove
    @return (boolean) True if element was removed
]]
function TableUtils.removeElement(array, element)
    local index = TableUtils.indexOf(array, element)
    if index then
        table.remove(array, index)
        return true
    end
    return false
end

--[[
    Remove elements from array by predicate
    @param array (table) Array to modify
    @param predicate (function) Function that returns true for elements to remove
    @return (number) Number of elements removed
]]
function TableUtils.removeIf(array, predicate)
    local removed = 0
    for i = #array, 1, -1 do
        if predicate(array[i], i) then
            table.remove(array, i)
            removed = removed + 1
        end
    end
    return removed
end

--[[
    Filter array by predicate
    @param array (table) Array to filter
    @param predicate (function) Function that returns true for elements to keep
    @return (table) New filtered array
]]
function TableUtils.filter(array, predicate)
    local filtered = {}
    for i, value in ipairs(array) do
        if predicate(value, i) then
            table.insert(filtered, value)
        end
    end
    return filtered
end

--[[
    Map array elements to new values
    @param array (table) Array to map
    @param mapper (function) Function to transform elements
    @return (table) New mapped array
]]
function TableUtils.map(array, mapper)
    local mapped = {}
    for i, value in ipairs(array) do
        table.insert(mapped, mapper(value, i))
    end
    return mapped
end

--[[
    Reduce array to single value
    @param array (table) Array to reduce
    @param reducer (function) Function(accumulator, value, index) -> new accumulator
    @param initialValue (any) Initial accumulator value
    @return (any) Final accumulator value
]]
function TableUtils.reduce(array, reducer, initialValue)
    local accumulator = initialValue
    for i, value in ipairs(array) do
        accumulator = reducer(accumulator, value, i)
    end
    return accumulator
end

--[[
    Find first element matching predicate
    @param array (table) Array to search
    @param predicate (function) Function that returns true for target element
    @return (any) First matching element or nil
]]
function TableUtils.find(array, predicate)
    for i, value in ipairs(array) do
        if predicate(value, i) then
            return value
        end
    end
    return nil
end

--[[
    Check if any element matches predicate
    @param array (table) Array to test
    @param predicate (function) Function to test elements
    @return (boolean) True if any element matches
]]
function TableUtils.some(array, predicate)
    for i, value in ipairs(array) do
        if predicate(value, i) then
            return true
        end
    end
    return false
end

--[[
    Check if all elements match predicate
    @param array (table) Array to test
    @param predicate (function) Function to test elements
    @return (boolean) True if all elements match
]]
function TableUtils.every(array, predicate)
    for i, value in ipairs(array) do
        if not predicate(value, i) then
            return false
        end
    end
    return true
end

--[[
    Reverse array in place
    @param array (table) Array to reverse
    @return (table) Reversed array (same instance)
]]
function TableUtils.reverse(array)
    local length = #array
    for i = 1, math.floor(length / 2) do
        local temp = array[i]
        array[i] = array[length - i + 1]
        array[length - i + 1] = temp
    end
    return array
end

--[[
    Sort array by custom comparator
    @param array (table) Array to sort
    @param comparator (function) Comparison function (optional)
    @return (table) Sorted array (same instance)
]]
function TableUtils.sort(array, comparator)
    table.sort(array, comparator)
    return array
end

--[[
    Concatenate multiple arrays
    @param ... (table) Arrays to concatenate
    @return (table) New concatenated array
]]
function TableUtils.concat(...)
    local result = {}
    local arrays = {...}
    
    for _, array in ipairs(arrays) do
        for _, value in ipairs(array) do
            table.insert(result, value)
        end
    end
    
    return result
end

--[[
    Get unique elements from array
    @param array (table) Array to process
    @return (table) New array with unique elements
]]
function TableUtils.unique(array)
    local seen = {}
    local unique = {}
    
    for _, value in ipairs(array) do
        if not seen[value] then
            seen[value] = true
            table.insert(unique, value)
        end
    end
    
    return unique
end

--[[
    Flatten nested arrays
    @param array (table) Array to flatten
    @param depth (number) Maximum depth to flatten (optional, default = 1)
    @return (table) Flattened array
]]
function TableUtils.flatten(array, depth)
    depth = depth or 1
    local flattened = {}
    
    for _, value in ipairs(array) do
        if type(value) == "table" and TableUtils.isArray(value) and depth > 0 then
            local subFlattened = TableUtils.flatten(value, depth - 1)
            for _, subValue in ipairs(subFlattened) do
                table.insert(flattened, subValue)
            end
        else
            table.insert(flattened, value)
        end
    end
    
    return flattened
end

--[[
    Chunk array into smaller arrays
    @param array (table) Array to chunk
    @param size (number) Size of each chunk
    @return (table) Array of chunks
]]
function TableUtils.chunk(array, size)
    local chunks = {}
    local currentChunk = {}
    
    for i, value in ipairs(array) do
        table.insert(currentChunk, value)
        
        if #currentChunk == size or i == #array then
            table.insert(chunks, currentChunk)
            currentChunk = {}
        end
    end
    
    return chunks
end

-- ===========================================
-- Table Querying
-- ===========================================

--[[
    Get nested value using dot notation
    @param tbl (table) Table to query
    @param path (string) Path like "a.b.c"
    @param defaultValue (any) Default value if path doesn't exist
    @return (any) Value at path or default
]]
function TableUtils.getNestedValue(tbl, path, defaultValue)
    local keys = TableUtils.split(path, ".")
    local current = tbl
    
    for _, key in ipairs(keys) do
        if type(current) == "table" and current[key] ~= nil then
            current = current[key]
        else
            return defaultValue
        end
    end
    
    return current
end

--[[
    Set nested value using dot notation
    @param tbl (table) Table to modify
    @param path (string) Path like "a.b.c"
    @param value (any) Value to set
]]
function TableUtils.setNestedValue(tbl, path, value)
    local keys = TableUtils.split(path, ".")
    local current = tbl
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

--[[
    Check if nested path exists
    @param tbl (table) Table to check
    @param path (string) Path like "a.b.c"
    @return (boolean) True if path exists
]]
function TableUtils.hasNestedValue(tbl, path)
    local keys = TableUtils.split(path, ".")
    local current = tbl
    
    for _, key in ipairs(keys) do
        if type(current) ~= "table" or current[key] == nil then
            return false
        end
        current = current[key]
    end
    
    return true
end

-- ===========================================
-- String/Table Utilities
-- ===========================================

--[[
    Split string into array
    @param str (string) String to split
    @param delimiter (string) Delimiter character
    @return (table) Array of split strings
]]
function TableUtils.split(str, delimiter)
    delimiter = delimiter or " "
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    
    return result
end

--[[
    Join array elements into string
    @param array (table) Array to join
    @param separator (string) Separator string
    @return (string) Joined string
]]
function TableUtils.join(array, separator)
    separator = separator or ","
    return table.concat(array, separator)
end

-- ===========================================
-- Table Comparison
-- ===========================================

--[[
    Deep equality check between two tables
    @param a (table) First table
    @param b (table) Second table
    @return (boolean) True if tables are deeply equal
]]
function TableUtils.deepEquals(a, b)
    if a == b then
        return true
    end
    
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    
    -- Check if both tables have same keys and values
    for key, value in pairs(a) do
        if not TableUtils.deepEquals(value, b[key]) then
            return false
        end
    end
    
    for key, _ in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    
    return true
end

-- ===========================================
-- Serialization Helpers
-- ===========================================

--[[
    Convert table to JSON-like string (basic implementation)
    @param tbl (table) Table to serialize
    @param indent (string) Indentation string (optional)
    @return (string) Serialized table
]]
function TableUtils.serialize(tbl, indent)
    indent = indent or ""
    local nextIndent = indent .. "  "
    local result = "{\n"
    
    for key, value in pairs(tbl) do
        local keyStr = type(key) == "string" and string.format('"%s"', key) or tostring(key)
        result = result .. nextIndent .. keyStr .. ": "
        
        if type(value) == "table" then
            result = result .. TableUtils.serialize(value, nextIndent)
        elseif type(value) == "string" then
            result = result .. string.format('"%s"', value)
        else
            result = result .. tostring(value)
        end
        
        result = result .. ",\n"
    end
    
    result = result .. indent .. "}"
    return result
end

--[[
    Convert table to compact string representation
    @param tbl (table) Table to convert
    @return (string) Compact string representation
]]
function TableUtils.toString(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    
    local parts = {}
    for key, value in pairs(tbl) do
        local keyStr = type(key) == "string" and key or string.format("[%s]", tostring(key))
        local valueStr = type(value) == "table" and TableUtils.toString(value) or tostring(value)
        table.insert(parts, keyStr .. "=" .. valueStr)
    end
    
    return "{" .. table.concat(parts, ", ") .. "}"
end

-- ===========================================
-- Performance Utilities
-- ===========================================

--[[
    Clear table efficiently
    @param tbl (table) Table to clear
]]
function TableUtils.clear(tbl)
    for key, _ in pairs(tbl) do
        tbl[key] = nil
    end
end

--[[
    Pool table for reuse (basic object pooling)
    @param tbl (table) Table to pool
    @param pool (table) Pool to add table to
]]
function TableUtils.returnToPool(tbl, pool)
    TableUtils.clear(tbl)
    table.insert(pool, tbl)
end

--[[
    Get table from pool or create new one
    @param pool (table) Pool to get table from
    @return (table) Table from pool or new table
]]
function TableUtils.getFromPool(pool)
    if #pool > 0 then
        return table.remove(pool)
    else
        return {}
    end
end

return TableUtils