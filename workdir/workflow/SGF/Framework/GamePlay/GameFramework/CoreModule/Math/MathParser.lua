local Log = GFScript("CoreModule.Log")
local MathParser = {}

-- 添加新的节点类型定义
local NodeType = {
    NUMBER = "number",
    SSTAT = "sstat",
    TSTAT = "tstat",
    BINARY_OP = "binary_op",
    FUNCTION = "function"
}

local cache = {}
local useCache = true

local functionHandlers = {
    min = function(args)
        local minVal = args[1] or 0
        for i = 2, #args do
            minVal = math.min(minVal, args[i])
        end
        return minVal
    end,
    
    max = function(args)
        local maxVal = args[1] or 0
        for i = 2, #args do
            maxVal = math.max(maxVal, args[i])
        end
        return maxVal
    end,
    
    random = function(args)
        local min = args[1] or 0
        local max = args[2] or 1
        -- Ensure min is less than max
        if min > max then
            min, max = max, min
        end
        return min + math.random() * (max - min)
    end
}

-- 创建AST节点的辅助函数
function MathParser:CreateNode(nodeType, value, left, right)
    return {
        type = nodeType,
        value = value,
        left = left,
        right = right
    }
end

function MathParser:Tokenizer(input)
    local position = 1
    local tokens = {}
    local patterns = {
        {pattern = "%s+", type = "whitespace"},
        {pattern = "S%.%w+", type = "sstat"},
        {pattern = "T%.%w+", type = "tstat"},
        {pattern = "[%-%−]?[%d%.]+", type = "number"},
        {pattern = "[*]", type = "multiply"},
        {pattern = "[/]", type = "divide"},
        {pattern = "[%+]", type = "add"},
        {pattern = "[%-%−](?!%d)(?<![%+%-*/])", type = "subtract"},
        {pattern = "[(]", type = "left_paren"},
        {pattern = "[)]", type = "right_paren"},
        {pattern = "[,]", type = "comma"}
    }
    
    for funcName, _ in pairs(functionHandlers) do
        table.insert(patterns, {pattern = funcName, type = "function"})
    end
    
    while position <= #input do
        local matched = false
        for _, patternInfo in ipairs(patterns) do
            local pattern, tokenType = patternInfo.pattern, patternInfo.type
            local start, finish = input:find("^" .. pattern, position)
            if start then
                if tokenType ~= "whitespace" then
                    table.insert(tokens, {type = tokenType, value = input:sub(start, finish)})
                end
                position = finish + 1
                matched = true
                break
            end
        end
        if not matched then
            Log:Error("Invalid input at position " .. position)
            break
        end
    end
    
    return tokens
end

function MathParser:Consume(tokenType, tokens, current)
    if current > #tokens then return nil, current end
    if tokens[current].type == tokenType then
        current = current + 1
        return tokens[current - 1], current
    else
        return nil, current
    end
end

function MathParser:GetSStat(name)
    return 0
end
function MathParser:GetTStat(name)
    return 0
end

function MathParser:Primary(tokens, current)
    local token
    token, current = self:Consume("function", tokens, current)
    if token then
        local funcName = token.value
        local args = {}
        
        token, current = self:Consume("left_paren", tokens, current)
        if not token then
            Log:Error("Expected '(' after function name")
            return nil, current
        end
        
        -- 检查是否立即遇到右括号（空参数列表）
        local rightParen
        rightParen, _ = self:Consume("right_paren", tokens, current)
        if rightParen then
            return self:CreateNode(NodeType.FUNCTION, funcName, args), current + 1
        end
        
        while true do
            local arg
            arg, current = self:Expression(tokens, current)
            if not arg then 
                Log:Error("Expected expression as function argument")
                return nil, current
            end
            table.insert(args, arg)
            
            token, current = self:Consume("comma", tokens, current)
            if not token then break end
            
            -- 检查逗号后面是否直接跟着右括号（缺少参数）
            rightParen, _ = self:Consume("right_paren", tokens, current)
            if rightParen then
                Log:Error("Expected expression after comma in function arguments")
                return nil, current
            end
        end
        
        token, current = self:Consume("right_paren", tokens, current)
        if not token then
            Log:Error("Expected ')' after function arguments")
            return nil, current
        end
        
        return self:CreateNode(NodeType.FUNCTION, funcName, args), current
    end

    token, current = self:Consume("number", tokens, current)
    if token then
        return self:CreateNode(NodeType.NUMBER, tonumber(token.value)), current
    end

    token, current = self:Consume("sstat", tokens, current)
    if token then
        local statName = string.sub(token.value,3)
        return self:CreateNode(NodeType.SSTAT, statName), current
    end

    token, current = self:Consume("tstat", tokens, current)
    if token then
        local statName = string.sub(token.value,3)
        return self:CreateNode(NodeType.TSTAT, statName), current
    end

    token, current = self:Consume("left_paren", tokens, current)
    if token then
        local result
        result, current = self:Expression(tokens, current)
        token, current = self:Consume("right_paren", tokens, current)
        if not token then
            Log:Error("Missing closing parenthesis")
        end
        return result, current
    end

    Log:Error("Invalid input at token " .. current)
end

function MathParser:Factor(tokens, current)
    local left
    left, current = self:Primary(tokens, current)
    while current and current <= #tokens do
        local mul, div
        mul, current = self:Consume("multiply", tokens, current)
        div, current = self:Consume("divide", tokens, current)
        if mul or div then
            local right
            right, current = self:Primary(tokens, current)
            if not right then return left, current end
            left = self:CreateNode(NodeType.BINARY_OP, mul and "*" or "/", left, right)
        else
            break
        end
    end
    return left, current
end

function MathParser:Expression(tokens, current)
    local left
    left, current = self:Factor(tokens, current)
    while current and current <= #tokens do
        local add, sub
        add, current = self:Consume("add", tokens, current)
        sub, current = self:Consume("subtract", tokens, current)
        if add or sub then
            local right
            right, current = self:Factor(tokens, current)
            if not right then return left, current end
            left = self:CreateNode(NodeType.BINARY_OP, add and "+" or "-", left, right)
        else
            break
        end
    end
    return left, current
end

function MathParser:ParseExpression(tokens)
    local current = 1
    return self:Expression(tokens, current)
end

-- 添加新的计算AST的函数
function MathParser:EvaluateAST(node)
    if not node then return 0 end

    if node.type == NodeType.NUMBER then
        return node.value
    elseif node.type == NodeType.SSTAT then
        return self.GetSStat(node.value)
    elseif node.type == NodeType.TSTAT then
        return self.GetTStat(node.value)
    elseif node.type == NodeType.BINARY_OP then
        local left = self:EvaluateAST(node.left)
        local right = self:EvaluateAST(node.right)
        if node.value == "+" then
            return left + right
        elseif node.value == "-" then
            return left - right
        elseif node.value == "*" then
            return left * right
        elseif node.value == "/" then
            if right == 0 then
                Log:Error("Division by zero")
                return 0
            end
            return left / right
        end
    elseif node.type == NodeType.FUNCTION then
        local args = {}
        for _, argNode in ipairs(node.left) do
            table.insert(args, self:EvaluateAST(argNode))
        end
        
        -- Call the appropriate function handler or return 0 if not found
        local handler = functionHandlers[node.value]
        if handler then
            return handler(args)
        end
        return 0
    end
    return 0
end

-- 编译
function MathParser:Compile(input)
    local tokens = self:Tokenizer(input)
    local ast, current = self:Expression(tokens, 1)
    
    -- Check if all tokens were consumed
    if current and current <= #tokens then
        Log:Error("Syntax error: Unexpected token at position " .. current)
        return nil
    end
    
    return ast
end

function MathParser:Evaluate(input, sstat, tstat)
    self.GetSStat = sstat or self.GetSStat
    self.GetTStat = tstat or self.GetTStat
    
    if type(input) == "string" then
        -- 如果输入是字符串，先编译
        local hash = self:HashInput(input)
        if useCache and cache[hash] then
            input = cache[hash]
        else
            local ast = self:Compile(input)
            if not ast then
                Log:Error("Failed to compile formula: " .. input)
                return 0
            end
            input = ast
            if useCache then
                cache[hash] = input
            end
        end
    end
    
    -- 检查输入是否为有效的AST
    if type(input) ~= "table" or not input.type then
        Log:Error("Invalid AST structure")
        return 0
    end
    
    -- 计算AST
    return self:EvaluateAST(input)
end


--计算字符串哈希值
function MathParser:HashInput(input)
    local hash = 0
    for i = 1, #input do
        hash = (hash * 33 + string.byte(input, i)) % 0x7FFFFFFF
    end
    return hash
end

return MathParser