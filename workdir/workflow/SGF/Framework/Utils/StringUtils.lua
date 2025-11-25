--[[
    StringUtils - String manipulation utilities for SGF
    
    Features:
    - String formatting and manipulation
    - Pattern matching and validation
    - Text processing utilities
    - Localization helpers
    - Performance-optimized operations
]]

local StringUtils = {}

-- ===========================================
-- Basic String Operations
-- ===========================================

--[[
    Trim whitespace from both ends of string
    @param str (string) String to trim
    @return (string) Trimmed string
]]
function StringUtils.trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

--[[
    Trim whitespace from left side of string
    @param str (string) String to trim
    @return (string) Left-trimmed string
]]
function StringUtils.ltrim(str)
    return string.match(str, "^%s*(.*)$")
end

--[[
    Trim whitespace from right side of string
    @param str (string) String to trim
    @return (string) Right-trimmed string
]]
function StringUtils.rtrim(str)
    return string.match(str, "^(.-)%s*$")
end

--[[
    Check if string is empty or only whitespace
    @param str (string) String to check
    @return (boolean) True if empty or whitespace
]]
function StringUtils.isEmpty(str)
    return str == nil or StringUtils.trim(str) == ""
end

--[[
    Check if string starts with prefix
    @param str (string) String to check
    @param prefix (string) Prefix to look for
    @return (boolean) True if string starts with prefix
]]
function StringUtils.startsWith(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

--[[
    Check if string ends with suffix
    @param str (string) String to check
    @param suffix (string) Suffix to look for
    @return (boolean) True if string ends with suffix
]]
function StringUtils.endsWith(str, suffix)
    return string.sub(str, -string.len(suffix)) == suffix
end

--[[
    Check if string contains substring
    @param str (string) String to search in
    @param substring (string) Substring to find
    @return (boolean) True if string contains substring
]]
function StringUtils.contains(str, substring)
    return string.find(str, substring, 1, true) ~= nil
end

--[[
    Count occurrences of substring in string
    @param str (string) String to search in
    @param substring (string) Substring to count
    @return (number) Number of occurrences
]]
function StringUtils.count(str, substring)
    local count = 0
    local pos = 1
    
    while true do
        local found = string.find(str, substring, pos, true)
        if not found then
            break
        end
        count = count + 1
        pos = found + 1
    end
    
    return count
end

-- ===========================================
-- String Manipulation
-- ===========================================

--[[
    Split string into array
    @param str (string) String to split
    @param delimiter (string) Delimiter character/string
    @param maxSplits (number) Maximum number of splits (optional)
    @return (table) Array of split strings
]]
function StringUtils.split(str, delimiter, maxSplits)
    delimiter = delimiter or " "
    maxSplits = maxSplits or math.huge
    
    local result = {}
    local splits = 0
    local startPos = 1
    
    while splits < maxSplits do
        local foundPos = string.find(str, delimiter, startPos, true)
        if not foundPos then
            break
        end
        
        table.insert(result, string.sub(str, startPos, foundPos - 1))
        startPos = foundPos + string.len(delimiter)
        splits = splits + 1
    end
    
    -- Add remaining part
    table.insert(result, string.sub(str, startPos))
    
    return result
end

--[[
    Join array of strings with separator
    @param array (table) Array of strings
    @param separator (string) Separator string
    @return (string) Joined string
]]
function StringUtils.join(array, separator)
    separator = separator or ""
    return table.concat(array, separator)
end

--[[
    Replace all occurrences of pattern with replacement
    @param str (string) String to modify
    @param pattern (string) Pattern to replace
    @param replacement (string) Replacement string
    @param usePattern (boolean) Whether to use Lua patterns (default: false, plain text)
    @return (string) Modified string
]]
function StringUtils.replace(str, pattern, replacement, usePattern)
    if usePattern then
        return string.gsub(str, pattern, replacement)
    else
        return string.gsub(str, pattern:gsub("([^%w])", "%%%1"), replacement)
    end
end

--[[
    Replace first occurrence of pattern with replacement
    @param str (string) String to modify
    @param pattern (string) Pattern to replace
    @param replacement (string) Replacement string
    @param usePattern (boolean) Whether to use Lua patterns
    @return (string) Modified string
]]
function StringUtils.replaceFirst(str, pattern, replacement, usePattern)
    if usePattern then
        return string.gsub(str, pattern, replacement, 1)
    else
        local pos = string.find(str, pattern, 1, true)
        if pos then
            return string.sub(str, 1, pos - 1) .. replacement .. string.sub(str, pos + string.len(pattern))
        end
        return str
    end
end

--[[
    Reverse a string
    @param str (string) String to reverse
    @return (string) Reversed string
]]
function StringUtils.reverse(str)
    return string.reverse(str)
end

--[[
    Repeat string n times
    @param str (string) String to repeat
    @param count (number) Number of repetitions
    @param separator (string) Separator between repetitions (optional)
    @return (string) Repeated string
]]
function StringUtils.repeater(str, count, separator)
    separator = separator or ""
    local result = {}
    
    for i = 1, count do
        table.insert(result, str)
    end
    
    return StringUtils.join(result, separator)
end

-- ===========================================
-- Case Manipulation
-- ===========================================

--[[
    Convert string to lowercase
    @param str (string) String to convert
    @return (string) Lowercase string
]]
function StringUtils.lower(str)
    return string.lower(str)
end

--[[
    Convert string to uppercase
    @param str (string) String to convert
    @return (string) Uppercase string
]]
function StringUtils.upper(str)
    return string.upper(str)
end

--[[
    Capitalize first letter of string
    @param str (string) String to capitalize
    @return (string) Capitalized string
]]
function StringUtils.capitalize(str)
    if string.len(str) == 0 then
        return str
    end
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

--[[
    Convert string to title case (capitalize each word)
    @param str (string) String to convert
    @return (string) Title case string
]]
function StringUtils.titleCase(str)
    return string.gsub(str, "(%a)([%w_']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

--[[
    Convert camelCase to snake_case
    @param str (string) CamelCase string
    @return (string) snake_case string
]]
function StringUtils.camelToSnake(str)
    return string.gsub(str, "(%u)", function(c)
        return "_" .. string.lower(c)
    end):gsub("^_", "")
end

--[[
    Convert snake_case to camelCase
    @param str (string) snake_case string
    @return (string) camelCase string
]]
function StringUtils.snakeToCamel(str)
    return string.gsub(str, "_(%a)", function(c)
        return string.upper(c)
    end)
end

--[[
    Convert string to kebab-case
    @param str (string) String to convert
    @return (string) kebab-case string
]]
function StringUtils.toKebabCase(str)
    str = string.gsub(str, "(%u)", function(c)
        return "-" .. string.lower(c)
    end)
    str = string.gsub(str, "_", "-")
    str = string.gsub(str, "%s+", "-")
    return str:gsub("^%-", ""):gsub("%-+", "-")
end

-- ===========================================
-- String Formatting
-- ===========================================

--[[
    Pad string to specified length with character
    @param str (string) String to pad
    @param length (number) Target length
    @param padChar (string) Character to pad with (default: space)
    @param padLeft (boolean) Whether to pad left side (default: right)
    @return (string) Padded string
]]
function StringUtils.pad(str, length, padChar, padLeft)
    padChar = padChar or " "
    local currentLength = string.len(str)
    
    if currentLength >= length then
        return str
    end
    
    local paddingLength = length - currentLength
    local padding = string.rep(padChar, paddingLength)
    
    if padLeft then
        return padding .. str
    else
        return str .. padding
    end
end

--[[
    Center string within specified width
    @param str (string) String to center
    @param width (number) Total width
    @param padChar (string) Character to pad with (default: space)
    @return (string) Centered string
]]
function StringUtils.center(str, width, padChar)
    padChar = padChar or " "
    local currentLength = string.len(str)
    
    if currentLength >= width then
        return str
    end
    
    local totalPadding = width - currentLength
    local leftPadding = math.floor(totalPadding / 2)
    local rightPadding = totalPadding - leftPadding
    
    return string.rep(padChar, leftPadding) .. str .. string.rep(padChar, rightPadding)
end

--[[
    Truncate string to maximum length with ellipsis
    @param str (string) String to truncate
    @param maxLength (number) Maximum length
    @param ellipsis (string) Ellipsis string (default: "...")
    @return (string) Truncated string
]]
function StringUtils.truncate(str, maxLength, ellipsis)
    ellipsis = ellipsis or "..."
    
    if string.len(str) <= maxLength then
        return str
    end
    
    local truncateLength = maxLength - string.len(ellipsis)
    return string.sub(str, 1, truncateLength) .. ellipsis
end

--[[
    Word wrap text to specified line length
    @param text (string) Text to wrap
    @param lineLength (number) Maximum line length
    @return (table) Array of wrapped lines
]]
function StringUtils.wordWrap(text, lineLength)
    local lines = {}
    local currentLine = ""
    local words = StringUtils.split(text, " ")
    
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        
        if string.len(testLine) <= lineLength then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end

-- ===========================================
-- Validation and Pattern Matching
-- ===========================================

--[[
    Check if string matches pattern
    @param str (string) String to test
    @param pattern (string) Lua pattern
    @return (boolean) True if string matches pattern
]]
function StringUtils.matches(str, pattern)
    return string.match(str, pattern) ~= nil
end

--[[
    Check if string is a valid number
    @param str (string) String to test
    @return (boolean) True if string is numeric
]]
function StringUtils.isNumeric(str)
    return tonumber(str) ~= nil
end

--[[
    Check if string is a valid integer
    @param str (string) String to test
    @return (boolean) True if string is an integer
]]
function StringUtils.isInteger(str)
    local num = tonumber(str)
    return num ~= nil and num == math.floor(num)
end

--[[
    Check if string contains only alphabetic characters
    @param str (string) String to test
    @return (boolean) True if string is alphabetic
]]
function StringUtils.isAlpha(str)
    return string.match(str, "^%a+$") ~= nil
end

--[[
    Check if string contains only alphanumeric characters
    @param str (string) String to test
    @return (boolean) True if string is alphanumeric
]]
function StringUtils.isAlphaNumeric(str)
    return string.match(str, "^%w+$") ~= nil
end

--[[
    Check if string is a valid email address (basic validation)
    @param str (string) String to test
    @return (boolean) True if string looks like an email
]]
function StringUtils.isEmail(str)
    return string.match(str, "^[%w%.%-_]+@[%w%.%-_]+%.%a+$") ~= nil
end

--[[
    Check if string is a valid URL (basic validation)
    @param str (string) String to test
    @return (boolean) True if string looks like a URL
]]
function StringUtils.isURL(str)
    return string.match(str, "^https?://[%w%.%-_]+") ~= nil
end

-- ===========================================
-- Text Processing
-- ===========================================

--[[
    Extract all numbers from string
    @param str (string) String to extract from
    @return (table) Array of numbers
]]
function StringUtils.extractNumbers(str)
    local numbers = {}
    for num in string.gmatch(str, "%-?%d+%.?%d*") do
        local value = tonumber(num)
        if value then
            table.insert(numbers, value)
        end
    end
    return numbers
end

--[[
    Extract all words from string
    @param str (string) String to extract from
    @return (table) Array of words
]]
function StringUtils.extractWords(str)
    local words = {}
    for word in string.gmatch(str, "%a+") do
        table.insert(words, word)
    end
    return words
end

--[[
    Remove all non-alphanumeric characters
    @param str (string) String to clean
    @return (string) Cleaned string
]]
function StringUtils.removeNonAlphaNumeric(str)
    return string.gsub(str, "[^%w]", "")
end

--[[
    Remove all numbers from string
    @param str (string) String to modify
    @return (string) String without numbers
]]
function StringUtils.removeNumbers(str)
    return string.gsub(str, "%d", "")
end

--[[
    Normalize whitespace (replace multiple spaces/tabs/newlines with single space)
    @param str (string) String to normalize
    @return (string) Normalized string
]]
function StringUtils.normalizeWhitespace(str)
    return StringUtils.trim(string.gsub(str, "%s+", " "))
end

-- ===========================================
-- Encoding/Escaping
-- ===========================================

--[[
    Escape special characters for Lua patterns
    @param str (string) String to escape
    @return (string) Escaped string
]]
function StringUtils.escapePattern(str)
    return string.gsub(str, "([^%w])", "%%%1")
end

--[[
    Escape HTML characters
    @param str (string) String to escape
    @return (string) HTML-escaped string
]]
function StringUtils.escapeHTML(str)
    local htmlEntities = {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;"
    }
    
    return string.gsub(str, "[&<>\"']", htmlEntities)
end

--[[
    Unescape HTML characters
    @param str (string) HTML-escaped string
    @return (string) Unescaped string
]]
function StringUtils.unescapeHTML(str)
    local htmlEntities = {
        ["&amp;"] = "&",
        ["&lt;"] = "<",
        ["&gt;"] = ">",
        ["&quot;"] = '"',
        ["&#39;"] = "'"
    }
    
    return string.gsub(str, "&[%w#]+;", htmlEntities)
end

-- ===========================================
-- Hash and Encoding
-- ===========================================

--[[
    Simple hash function for strings
    @param str (string) String to hash
    @return (number) Hash value
]]
function StringUtils.simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 33 + string.byte(str, i)) % 0x7FFFFFFF
    end
    return hash
end

--[[
    Convert string to Base64 (basic implementation)
    @param str (string) String to encode
    @return (string) Base64 encoded string
]]
function StringUtils.toBase64(str)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local result = ""
    
    for i = 1, string.len(str), 3 do
        local a, b, c = string.byte(str, i, i + 2)
        b = b or 0
        c = c or 0
        
        local buffer = a * 65536 + b * 256 + c
        
        for j = 18, 0, -6 do
            local index = math.floor(buffer / (2 ^ j)) % 64 + 1
            result = result .. string.sub(alphabet, index, index)
        end
    end
    
    -- Add padding
    local padding = string.len(str) % 3
    if padding > 0 then
        result = string.sub(result, 1, -(4 - padding)) .. string.rep("=", 3 - padding)
    end
    
    return result
end

-- ===========================================
-- Comparison Utilities
-- ===========================================

--[[
    Case-insensitive string comparison
    @param a (string) First string
    @param b (string) Second string
    @return (boolean) True if strings are equal (case-insensitive)
]]
function StringUtils.equalsIgnoreCase(a, b)
    return string.lower(a) == string.lower(b)
end

--[[
    Calculate Levenshtein distance between two strings
    @param a (string) First string
    @param b (string) Second string
    @return (number) Edit distance
]]
function StringUtils.levenshteinDistance(a, b)
    local lenA, lenB = string.len(a), string.len(b)
    
    if lenA == 0 then return lenB end
    if lenB == 0 then return lenA end
    
    local matrix = {}
    
    -- Initialize matrix
    for i = 0, lenA do
        matrix[i] = {[0] = i}
    end
    
    for j = 0, lenB do
        matrix[0][j] = j
    end
    
    -- Fill matrix
    for i = 1, lenA do
        for j = 1, lenB do
            local cost = (string.sub(a, i, i) == string.sub(b, j, j)) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i - 1][j] + 1,      -- deletion
                matrix[i][j - 1] + 1,      -- insertion
                matrix[i - 1][j - 1] + cost -- substitution
            )
        end
    end
    
    return matrix[lenA][lenB]
end

--[[
    Calculate string similarity percentage
    @param a (string) First string
    @param b (string) Second string
    @return (number) Similarity percentage (0-100)
]]
function StringUtils.similarity(a, b)
    local maxLen = math.max(string.len(a), string.len(b))
    if maxLen == 0 then return 100 end
    
    local distance = StringUtils.levenshteinDistance(a, b)
    return ((maxLen - distance) / maxLen) * 100
end

return StringUtils