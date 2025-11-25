-- 说明:颜色类
-- 日期:2024年6月3日
-- 支持:郝文丽
-- 版权声明 (c) 2024 迷你创想. All rights reserved.

local Color = {}

--白色
function Color.white()
    return Color.New(1, 1, 1, 1)
end

--黑色
function Color.black()
    return Color.New(0, 0, 0, 1)
end

--灰色
function Color.gray()
    return Color.New(0.5, 0.5, 0.5, 1)
end

--蓝色
function Color.blue()
    return Color.New(0, 0, 1, 1)
end

--绿色
function Color.green()
    return Color.New(0, 1, 0, 1)
end

--红色
function Color.red()
    return Color.New(1, 0, 0, 1)
end

--黄色
function Color.yellow()
    return Color.New(1, 1, 0, 1)
end

--紫色
function Color.purple()
    return Color.New(1, 0, 1, 1)
end

--青色
function Color.cyan()
    return Color.New(0, 1, 1, 1)
end

--橙色
function Color.orange()
    return Color.New(1, 0.5, 0, 1)
end

--从十六进制字符串创建颜色
function Color.FromHex(hex)
    -- 移除#号（如果存在）
    hex = hex:gsub("#", "")
    
    -- 解析RGB值
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    
    -- 如果有alpha值（8位十六进制），则解析它
    local a = 1
    if #hex == 8 then
        a = tonumber(hex:sub(7, 8), 16) / 255
    end
    
    return Color.New(r, g, b, a)
end

--实例化
function Color.New(r, g, b, a)
    local obj = {}
    obj.r = r or 1
    obj.g = g or 1
    obj.b = b or 1
    obj.a = a or 1
    Color.__index = Color
    setmetatable(obj, Color)
    return obj
end

---------------------------------运算符重载-------------------------------
--加
function Color.__add(lhs, rhs)
    return Color.New(lhs.r + rhs.r, lhs.g + rhs.g, lhs.b + rhs.b, lhs.a + rhs.a)
end

--减
function Color.__sub(lhs, rhs)
    return Color.New(lhs.r - rhs.r, lhs.g - rhs.g, lhs.b - rhs.b, lhs.a - rhs.a)
end

--乘
function Color.__mul(lhs, rhs)
    if type(lhs) == "number" then
        return Color.New(lhs * rhs.r, lhs * rhs.g, lhs * rhs.b, lhs * rhs.a)
    elseif type(rhs) == "number" then
        return Color.New(lhs.r * rhs, lhs.g * rhs, lhs.b * rhs, lhs.a * rhs)
    else
        return Color.New(lhs.r * rhs.r, lhs.g * rhs.g, lhs.b * rhs.b, lhs.a * rhs.a)
    end
end

--除
function Color.__div(lhs, rhs)
    if type(rhs) == "number" then
        return Color.New(lhs.r / rhs, lhs.g / rhs, lhs.b / rhs, lhs.a / rhs)
    else
        return Color.New(lhs.r / rhs.r, lhs.g / rhs.g, lhs.b / rhs.b, lhs.a / rhs.a)
    end
end

--负
function Color.__unm(v)
    return Color.New(-v.r, -v.g, -v.b, -v.a)
end

--等于
function Color.__eq(lhs, rhs)
    return lhs.r == rhs.r and lhs.g == rhs.g and lhs.b == rhs.b and lhs.a == rhs.a
end

--不等于
function Color.__ne(lhs, rhs)
    return lhs.r ~= rhs.r or lhs.g ~= rhs.g or lhs.b ~= rhs.b or lhs.a ~= rhs.a
end

--小于
function Color.__lt(lhs, rhs)
    return lhs.r < rhs.r and lhs.g < rhs.g and lhs.b < rhs.b and lhs.a < rhs.a
end

--小于等于
function Color.__le(lhs, rhs)
    return lhs.r <= rhs.r and lhs.g <= rhs.g and lhs.b <= rhs.b and lhs.a <= rhs.a
end

--大于
function Color.__gt(lhs, rhs)
    return lhs.r > rhs.r and lhs.g > rhs.g and lhs.b > rhs.b and lhs.a > rhs.a
end

--大于等于
function Color.__ge(lhs, rhs)
    return lhs.r >= rhs.r and lhs.g >= rhs.g and lhs.b >= rhs.b and lhs.a >= rhs.a
end

--打印
function Color:__tostring()
    return string.format("Color(%f, %f, %f, %f)", self.r, self.g, self.b, self.a)
end


---------------------------------方法-----------------------------------
--获取颜色
function Color:Get()
    return self.r, self.g, self.b, self.a
end

--设置颜色
function Color:Set(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a
end

--设置红色
function Color:SetR(r)
    self.r = r
end

--设置绿色
function Color:SetG(g)
    self.g = g
end

--设置蓝色
function Color:SetB(b)
    self.b = b
end

--设置透明度
function Color:SetA(a)
    self.a = a
end

--获取红色
function Color:GetR()
    return self.r
end

--获取绿色
function Color:GetG()
    return self.g
end

--获取蓝色
function Color:GetB()
    return self.b
end

--获取透明度
function Color:GetA()
    return self.a
end

--获取灰度
function Color:GetGray()
    return self.r * 0.299 + self.g * 0.587 + self.b * 0.114
end

--获取反色
function Color:GetInversed()
    return Color.New(1 - self.r, 1 - self.g, 1 - self.b, self.a)
end

--获取亮度
function Color:GetBrightness()
    return (self.r + self.g + self.b) / 3
end

--获取最大值
function Color:GetMax()
    return math.max(self.r, self.g, self.b)
end

--获取最小值
function Color:GetMin()
    return math.min(self.r, self.g, self.b)
end

--获取饱和度
function Color:GetSaturation()
    local max = self:GetMax()
    local min = self:GetMin()
    if max == 0 then
        return 0
    else
        return (max - min) / max
    end
end

--获取色调
function Color:GetHue()
    local max = self:GetMax()
    local min = self:GetMin()
    if max == min then
        return 0
    end
    local h
    if max == self.r then
        h = (self.g - self.b) / (max - min)
    elseif max == self.g then
        h = 2 + (self.b - self.r) / (max - min)
    else
        h = 4 + (self.r - self.g) / (max - min)
    end
    h = h * 60
    if h < 0 then
        h = h + 360
    end
    return h
end

--设置色调
function Color:SetHue(h)
    local s = self:GetSaturation()
    local v = self:GetMax()
    local h = h
    local hi = math.floor(h / 60) % 6
    local f = h / 60 - hi
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if hi == 0 then
        self.r = v
        self.g = t
        self.b = p
    elseif hi == 1 then
        self.r = q
        self.g = v
        self.b = p
    elseif hi == 2 then
        self.r = p
        self.g = v
        self.b = t
    elseif hi == 3 then
        self.r = p
        self.g = q
        self.b = v
    elseif hi == 4 then
        self.r = t
        self.g = p
        self.b = v
    else
        self.r = v
        self.g = p
        self.b = q
    end
end

--转换为Vec3
function Color:ToVec3()
    return Vec3.New(self.r, self.g, self.b)
end

--转换为Vec4
function Color:ToVec4()
    return Vec4.New(self.r, self.g, self.b, self.a)
end

--克隆
function Color:Clone()
    return Color.New(self.r, self.g, self.b, self.a)
end

--插值
function Color:Lerp(to, t)
    return Color.New(self.r + (to.r - self.r) * t, self.g + (to.g - self.g) * t, self.b + (to.b - self.b) * t, self.a + (to.a - self.a) * t)
end

--转换为十六进制字符串
function Color:ToHex()
    return string.format("#%02X%02X%02X", self.r * 255, self.g * 255, self.b * 255)
end

return Color