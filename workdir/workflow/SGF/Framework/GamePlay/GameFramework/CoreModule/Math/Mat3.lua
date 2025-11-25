local Mat3 = {}

--实例化
function Mat3.New(m00, m01, m02, m10, m11, m12, m20, m21, m22)
    local obj = {}
    Mat3.__index = Mat3
    setmetatable(obj, Mat3)
    obj:SetData(m00, m01, m02, m10, m11, m12, m20, m21, m22)
    return obj
end

function Mat3:SetIdentity()
    self.data = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
end

function Mat3:SetZero()
    self.data = {
        {0, 0, 0},
        {0, 0, 0},
        {0, 0, 0}
    }
end

function Mat3:SetData(m00, m01, m02, m10, m11, m12, m20, m21, m22)
    self.data = {
        {m00 or 1, m01 or 0, m02 or 0},
        {m10 or 0, m11 or 1, m12 or 0},
        {m20 or 0, m21 or 0, m22 or 1}
    }
end

function Mat3.__add(lhs, rhs)
    return New(
        lhs.data[1][1] + rhs.data[1][1], lhs.data[1][2] + rhs.data[1][2], lhs.data[1][3] + rhs.data[1][3],
        lhs.data[2][1] + rhs.data[2][1], lhs.data[2][2] + rhs.data[2][2], lhs.data[2][3] + rhs.data[2][3],
        lhs.data[3][1] + rhs.data[3][1], lhs.data[3][2] + rhs.data[3][2], lhs.data[3][3] + rhs.data[3][3]
    )
end

function Mat3.__sub(lhs, rhs)
    return New(
        lhs.data[1][1] - rhs.data[1][1], lhs.data[1][2] - rhs.data[1][2], lhs.data[1][3] - rhs.data[1][3],
        lhs.data[2][1] - rhs.data[2][1], lhs.data[2][2] - rhs.data[2][2], lhs.data[2][3] - rhs.data[2][3],
        lhs.data[3][1] - rhs.data[3][1], lhs.data[3][2] - rhs.data[3][2], lhs.data[3][3] - rhs.data[3][3]
    )
end

function Mat3.__mul(lhs, rhs)
    if type(lhs) == "number" then
        return New(
            lhs * rhs.data[1][1], lhs * rhs.data[1][2], lhs * rhs.data[1][3],
            lhs * rhs.data[2][1], lhs * rhs.data[2][2], lhs * rhs.data[2][3],
            lhs * rhs.data[3][1], lhs * rhs.data[3][2], lhs * rhs.data[3][3]
        )
    elseif type(rhs) == "number" then
        return New(
            lhs.data[1][1] * rhs, lhs.data[1][2] * rhs, lhs.data[1][3] * rhs,
            lhs.data[2][1] * rhs, lhs.data[2][2] * rhs, lhs.data[2][3] * rhs,
            lhs.data[3][1] * rhs, lhs.data[3][2] * rhs, lhs.data[3][3] * rhs
        )
    elseif rhs.x and rhs.y and rhs.z then
        return New(
            lhs.data[1][1] * rhs.x + lhs.data[1][2] * rhs.y + lhs.data[1][3] * rhs.z,
            lhs.data[2][1] * rhs.x + lhs.data[2][2] * rhs.y + lhs.data[2][3] * rhs.z,
            lhs.data[3][1] * rhs.x + lhs.data[3][2] * rhs.y + lhs.data[3][3] * rhs.z
        )
    else
        return New(
            lhs.data[1][1] * rhs.data[1][1] + lhs.data[1][2] * rhs.data[2][1] + lhs.data[1][3] * rhs.data[3][1],
            lhs.data[1][1] * rhs.data[1][2] + lhs.data[1][2] * rhs.data[2][2] + lhs.data[1][3] * rhs.data[3][2],
            lhs.data[1][1] * rhs.data[1][3] + lhs.data[1][2] * rhs.data[2][3] + lhs.data[1][3] * rhs.data[3][3],
            lhs.data[2][1] * rhs.data[1][1] + lhs.data[2][2] * rhs.data[2][1] + lhs.data[2][3] * rhs.data[3][1],
            lhs.data[2][1] * rhs.data[1][2] + lhs.data[2][2] * rhs.data[2][2] + lhs.data[2][3] * rhs.data[3][2],
            lhs.data[2][1] * rhs.data[1][3] + lhs.data[2][2] * rhs.data[2][3] + lhs.data[2][3] * rhs.data[3][3],
            lhs.data[3][1] * rhs.data[1][1] + lhs.data[3][2] * rhs.data[2][1] + lhs.data[3][3] * rhs.data[3][1],
            lhs.data[3][1] * rhs.data[1][2] + lhs.data[3][2] * rhs.data[2][2] + lhs.data[3][3] * rhs.data[3][2],
            lhs.data[3][1] * rhs.data[1][3] + lhs.data[3][2] * rhs.data[2][3] + lhs.data[3][3] * rhs.data[3][3]
        )
    end
end

function Mat3.__div(lhs, rhs)
    if type(rhs) == "number" then
        local invRhs = 1 / rhs
        return New(
            lhs.data[1][1] * invRhs, lhs.data[1][2] * invRhs, lhs.data[1][3] * invRhs,
            lhs.data[2][1] * invRhs, lhs.data[2][2] * invRhs, lhs.data[2][3] * invRhs,
            lhs.data[3][1] * invRhs, lhs.data[3][2] * invRhs, lhs.data[3][3] * invRhs
        )
    else
        return New(
            lhs.data[1][1] / rhs.data[1][1], lhs.data[1][2] / rhs.data[1][2], lhs.data[1][3] / rhs.data[1][3],
            lhs.data[2][1] / rhs.data[2][1], lhs.data[2][2] / rhs.data[2][2], lhs.data[2][3] / rhs.data[2][3],
            lhs.data[3][1] / rhs.data[3][1], lhs.data[3][2] / rhs.data[3][2], lhs.data[3][3] / rhs.data[3][3]
        )
    end
end

Mat3.__unm = function(v)
    return New(
        -v.data[1][1], -v.data[1][2], -v.data[1][3],
        -v.data[2][1], -v.data[2][2], -v.data[2][3],
        -v.data[3][1], -v.data[3][2], -v.data[3][3]
    )
end

Mat3.__eq = function(lhs, rhs)
    return lhs.data[1][1] == rhs.data[1][1] and lhs.data[1][2] == rhs.data[1][2] and lhs.data[1][3] == rhs.data[1][3] and
           lhs.data[2][1] == rhs.data[2][1] and lhs.data[2][2] == rhs.data[2][2] and lhs.data[2][3] == rhs.data[2][3] and
           lhs.data[3][1] == rhs.data[3][1] and lhs.data[3][2] == rhs.data[3][2] and lhs.data[3][3] == rhs.data[3][3]
end

Mat3.__tostring = function(self)
    return string.format(
        "[[%f, %f, %f], [%f, %f, %f], [%f, %f, %f]]",
        self.data[1][1], self.data[1][2], self.data[1][3],
        self.data[2][1], self.data[2][2], self.data[2][3],
        self.data[3][1], self.data[3][2], self.data[3][3]
    )
end

function Mat3:Get(row, col)
    return self.data[row][col]
end

function Mat3:Set(row, col, value)
    self.data[row][col] = value
end

function Mat3:Transpose()
    self.data[1][2], self.data[2][1] = self.data[2][1], self.data[1][2]
    self.data[1][3], self.data[3][1] = self.data[3][1], self.data[1][3]
    self.data[2][3], self.data[3][2] = self.data[3][2], self.data[2][3]
end

function Mat3:Inverse()
    local det = self.data[1][1] * (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2]) -
                self.data[1][2] * (self.data[2][1] * self.data[3][3] - self.data[2][3] * self.data[3][1]) +
                self.data[1][3] * (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1])
    if det == 0 then return false end
    local invDet = 1 / det
    local m00 = (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2]) * invDet
    local m01 = (self.data[1][3] * self.data[3][2] - self.data[1][2] * self.data[3][3]) * invDet
    local m02 = (self.data[1][2] * self.data[2][3] - self.data[1][3] * self.data[2][2]) * invDet
    local m10 = (self.data[2][3] * self.data[3][1] - self.data[2][1] * self.data[3][3]) * invDet
    local m11 = (self.data[1][1] * self.data[3][3] - self.data[1][3] * self.data[3][1]) * invDet
    local m12 = (self.data[1][3] * self.data[2][1] - self.data[1][1] * self.data[2][3]) * invDet
    local m20 = (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1]) * invDet
    local m21 = (self.data[1][2] * self.data[3][1] - self.data[1][1] * self.data[3][2]) * invDet
    local m22 = (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]) * invDet
    self:SetData(m00, m01, m02, m10, m11, m12, m20, m21, m22)
    return true
end

function Mat3:SetTranslate(tx, ty)
    self.data[1][3], self.data[2][3] = tx, ty
end

function Mat3:SetScale(sx, sy)
    self.data[1][1], self.data[2][2] = sx, sy
end

function Mat3:SetRotate(angle)
    local rad = math.rad(angle)
    local c, s = math.cos(rad), math.sin(rad)
    self.data[1][1], self.data[1][2], self.data[2][1], self.data[2][2] = c, -s, s, c
end

function Mat3:GetTranslate()
    return self.data[1][3], self.data[2][3]
end

function Mat3:GetScale()
    return self.data[1][1], self.data[2][2]
end

function Mat3:GetRotate()
    return math.deg(math.atan2(self.data[2][1], self.data[1][1]))
end

function Mat3:MulVec2(v)
    return Vec2.New(
        self.data[1][1] * v.x + self.data[1][2] * v.y + self.data[1][3],
        self.data[2][1] * v.x + self.data[2][2] * v.y + self.data[2][3]
    )
end

function Mat3:MulMat3(m)
    return New(
        self.data[1][1] * m.data[1][1] + self.data[1][2] * m.data[2][1] + self.data[1][3] * m.data[3][1],
        self.data[1][1] * m.data[1][2] + self.data[1][2] * m.data[2][2] + self.data[1][3] * m.data[3][2],
        self.data[1][1] * m.data[1][3] + self.data[1][2] * m.data[2][3] + self.data[1][3] * m.data[3][3],
        self.data[2][1] * m.data[1][1] + self.data[2][2] * m.data[2][1] + self.data[2][3] * m.data[3][1],
        self.data[2][1] * m.data[1][2] + self.data[2][2] * m.data[2][2] + self.data[2][3] * m.data[3][2],
        self.data[2][1] * m.data[1][3] + self.data[2][2] * m.data[2][3] + self.data[2][3] * m.data[3][3],
        self.data[3][1] * m.data[1][1] + self.data[3][2] * m.data[2][1] + self.data[3][3] * m.data[3][1],
        self.data[3][1] * m.data[1][2] + self.data[3][2] * m.data[2][2] + self.data[3][3] * m.data[3][2],
        self.data[3][1] * m.data[1][3] + self.data[3][2] * m.data[2][3] + self.data[3][3] * m.data[3][3]
    )
end

function Mat3:Scaled(scale)
    return New(
        self.data[1][1] * scale.x, self.data[1][2] * scale.y, self.data[1][3] * scale.z,
        self.data[2][1] * scale.x, self.data[2][2] * scale.y, self.data[2][3] * scale.z,
        self.data[3][1] * scale.x, self.data[3][2] * scale.y, self.data[3][3] * scale.z
    )
end

function Mat3:Clone()
    return New(
        self.data[1][1], self.data[1][2], self.data[1][3],
        self.data[2][1], self.data[2][2], self.data[2][3],
        self.data[3][1], self.data[3][2], self.data[3][3]
    )
end

return Mat3