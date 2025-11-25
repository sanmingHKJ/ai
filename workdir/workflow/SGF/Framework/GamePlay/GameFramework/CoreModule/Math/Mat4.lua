local Vec3 = GFScript("CoreModule.Math.Vec3")
local Vec4 = GFScript("CoreModule.Math.Vec4")
local Mat4 = {}

--实例化
function Mat4.New()
    local obj = {}
    Mat4.__index = Mat4
    setmetatable(obj, Mat4)
    obj:SetIdentity()
    return obj
end

--设置单位矩阵
function Mat4:SetIdentity()
    self:SetData(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    )
end

--设置
function Mat4:SetData(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33)
    self.data[1][1] = m00
    self.data[1][2] = m01
    self.data[1][3] = m02
    self.data[1][4] = m03
    self.data[2][1] = m10
    self.data[2][2] = m11
    self.data[2][3] = m12
    self.data[2][4] = m13
    self.data[3][1] = m20
    self.data[3][2] = m21
    self.data[3][3] = m22
    self.data[3][4] = m23
    self.data[4][1] = m30
    self.data[4][2] = m31
    self.data[4][3] = m32
    self.data[4][4] = m33
end

--矩阵乘法
function Mat4:Mul(mat)
    local res = Mat4.New()
    for i = 1, 4 do
        for j = 1, 4 do
            res.data[i][j] = 0
            for k = 1, 4 do
                res.data[i][j] = res.data[i][j] + self.data[i][k] * mat.data[k][j]
            end
        end
    end
    return res
end

--矩阵乘向量
function Mat4:MulVec3(rhs)
    local res = Vec3.New()
    local invW = 1.0 / (self.data[4][1] * rhs.x + self.data[4][2] * rhs.y + self.data[4][3] * rhs.z + self.data[4][4])

    res.x = (self.data[1][1] * rhs.x + self.data[1][2] * rhs.y + self.data[1][3] * rhs.z + self.data[1][4]) * invW
    res.y = (self.data[2][1] * rhs.x + self.data[2][2] * rhs.y + self.data[2][3] * rhs.z + self.data[2][4]) * invW
    res.z = (self.data[3][1] * rhs.x + self.data[3][2] * rhs.y + self.data[3][3] * rhs.z + self.data[3][4]) * invW

    return res
end

function Mat4:MulVec4(rhs)
    local res = Vec4.New()
    res.x = self.data[1][1] * rhs.x + self.data[1][2] * rhs.y + self.data[1][3] * rhs.z + self.data[1][4] * rhs.w
    res.y = self.data[2][1] * rhs.x + self.data[2][2] * rhs.y + self.data[2][3] * rhs.z + self.data[2][4] * rhs.w
    res.z = self.data[3][1] * rhs.x + self.data[3][2] * rhs.y + self.data[3][3] * rhs.z + self.data[3][4] * rhs.w
    res.w = self.data[4][1] * rhs.x + self.data[4][2] * rhs.y + self.data[4][3] * rhs.z + self.data[4][4] * rhs.w
    return res
end

function Mat4:MulMat3x4(rhs)
    local res = Mat4.New()
    res.data[1][1] = self.data[1][1] * rhs.data[1][1] + self.data[1][2] * rhs.data[2][1] + self.data[1][3] * rhs.data[3][1]
    res.data[1][2] = self.data[1][1] * rhs.data[1][2] + self.data[1][2] * rhs.data[2][2] + self.data[1][3] * rhs.data[3][2]
    res.data[1][3] = self.data[1][1] * rhs.data[1][3] + self.data[1][2] * rhs.data[2][3] + self.data[1][3] * rhs.data[3][3]
    res.data[1][4] = self.data[1][1] * rhs.data[1][4] + self.data[1][2] * rhs.data[2][4] + self.data[1][3] * rhs.data[3][4] + self.data[1][4]
    res.data[2][1] = self.data[2][1] * rhs.data[1][1] + self.data[2][2] * rhs.data[2][1] + self.data[2][3] * rhs.data[3][1]
    res.data[2][2] = self.data[2][1] * rhs.data[1][2] + self.data[2][2] * rhs.data[2][2] + self.data[2][3] * rhs.data[3][2]
    res.data[2][3] = self.data[2][1] * rhs.data[1][3] + self.data[2][2] * rhs.data[2][3] + self.data[2][3] * rhs.data[3][3]
    res.data[2][4] = self.data[2][1] * rhs.data[1][4] + self.data[2][2] * rhs.data[2][4] + self.data[2][3] * rhs.data[3][4] + self.data[2][4]
    res.data[3][1] = self.data[3][1] * rhs.data[1][1] + self.data[3][2] * rhs.data[2][1] + self.data[3][3] * rhs.data[3][1]
    res.data[3][2] = self.data[3][1] * rhs.data[1][2] + self.data[3][2] * rhs.data[2][2] + self.data[3][3] * rhs.data[3][2]
    res.data[3][3] = self.data[3][1] * rhs.data[1][3] + self.data[3][2] * rhs.data[2][3] + self.data[3][3] * rhs.data[3][3]
    res.data[3][4] = self.data[3][1] * rhs.data[1][4] + self.data[3][2] * rhs.data[2][4] + self.data[3][3] * rhs.data[3][4] + self.data[3][4]
    res.data[4][1] = self.data[4][1] * rhs.data[1][1] + self.data[4][2] * rhs.data[2][1] + self.data[4][3] * rhs.data[3][1]
    res.data[4][2] = self.data[4][1] * rhs.data[1][2] + self.data[4][2] * rhs.data[2][2] + self.data[4][3] * rhs.data[3][2]
    res.data[4][3] = self.data[4][1] * rhs.data[1][3] + self.data[4][2] * rhs.data[2][3] + self.data[4][3] * rhs.data[3][3]
    res.data[4][4] = self.data[4][1] * rhs.data[1][4] + self.data[4][2] * rhs.data[2][4] + self.data[4][3] * rhs.data[3][4] + self.data[4][4]
    return res
end

---------------------------------运算符重载-------------------------------
function Mat4.__add(lhs, rhs)
    local res = Mat4.New()
    for i = 1, 4 do
        for j = 1, 4 do
            res.data[i][j] = lhs.data[i][j] + rhs.data[i][j]
        end
    end
    return res
end

function Mat4.__sub(lhs, rhs)
    local res = Mat4.New()
    for i = 1, 4 do
        for j = 1, 4 do
            res.data[i][j] = lhs.data[i][j] - rhs.data[i][j]
        end
    end
    return res
end
--乘
function Mat4.__mul(lhs, rhs)
    if rhs.x and rhs.y and rhs.z and rhs.w then
        return lhs:MulVec4(rhs)
    elseif rhs.x and rhs.y and rhs.z then
        return lhs:MulVec3(rhs)
    elseif rhs.m33 then
        return lhs:Mul(rhs)
    elseif rhs.m23 then
        return lhs:MulMat3x4(rhs)
    end
end

function Mat4:__tostring()
    return string.format(
        "[[%f, %f, %f, %f], [%f, %f, %f, %f], [%f, %f, %f, %f], [%f, %f, %f, %f]]",
        self.data[1][1], self.data[1][2], self.data[1][3], self.data[1][4],
        self.data[2][1], self.data[2][2], self.data[2][3], self.data[2][4],
        self.data[3][1], self.data[3][2], self.data[3][3], self.data[3][4],
        self.data[4][1], self.data[4][2], self.data[4][3], self.data[4][4]
    )
end
--设置平移
function Mat4:SetTranslation(x, y, z)
    if type(x) == "table" then
        x, y, z = x.x, x.y, x.z
    end
    self.data[1][4] = x
    self.data[2][4] = y
    self.data[3][4] = z
end

function Mat4:GetTranslation()
    return Vec3.New(self.data[1][4], self.data[2][4], self.data[3][4])
end

--设置旋转
function Mat4:SetRotation(rotation)
    if rotation.x and rotation.y and rotation.z and rotation.w then
        rotation = rotation:ToMat3()
    end
    self.data[1][1] = rotation.data[1][1]
    self.data[1][2] = rotation.data[1][2]
    self.data[1][3] = rotation.data[1][3]
    self.data[2][1] = rotation.data[2][1]
    self.data[2][2] = rotation.data[2][2]
    self.data[2][3] = rotation.data[2][3]
    self.data[3][1] = rotation.data[3][1]
    self.data[3][2] = rotation.data[3][2]
    self.data[3][3] = rotation.data[3][3]
end
--获取旋转，返回四元数
function Mat4:GetRotation()
    local mat3 = Mat3.New()
    mat3:SetData(
        self.data[1][1],
        self.data[1][2],
        self.data[1][3],
        self.data[2][1],
        self.data[2][2],
        self.data[2][3],
        self.data[3][1],
        self.data[3][2],
        self.data[3][3]
    )
    local quat = Quat.New()
    quat:FromMat3(mat3)
    return quat
end
--设置缩放
function Mat4:SetScale(x, y, z)
    if type(x) == "table" then
        x, y, z = x.x, x.y, x.z
    end
    self.data[1][1] = x
    self.data[2][2] = y
    self.data[3][3] = z
end

function Mat4:GetScale()
    return Vec3.New(self.data[1][1], self.data[2][2], self.data[3][3])
end

--逆矩阵
function Mat4:Inverse()
    local v0 = self.data[3][1] * self.data[4][2] - self.data[3][2] * self.data[4][1]
    local v1 = self.data[3][1] * self.data[4][3] - self.data[3][3] * self.data[4][1]
    local v2 = self.data[3][1] * self.data[4][4] - self.data[3][4] * self.data[4][1]
    local v3 = self.data[3][2] * self.data[4][3] - self.data[3][3] * self.data[4][2]
    local v4 = self.data[3][2] * self.data[4][4] - self.data[3][4] * self.data[4][2]
    local v5 = self.data[3][3] * self.data[4][4] - self.data[3][4] * self.data[4][3]

    local i00 = (v5 * self.data[2][2] - v4 * self.data[2][3] + v3 * self.data[2][4])
    local i10 = -(v5 * self.data[2][1] - v2 * self.data[2][3] + v1 * self.data[2][4])
    local i20 = (v4 * self.data[2][1] - v2 * self.data[2][2] + v0 * self.data[2][4])
    local i30 = -(v3 * self.data[2][1] - v1 * self.data[2][2] + v0 * self.data[2][3])

    local invDet = 1.0 / (i00 * self.data[1][1] + i10 * self.data[1][2] + i20 * self.data[1][3] + i30 * self.data[1][4])

    i00 = i00 * invDet
    i10 = i10 * invDet
    i20 = i20 * invDet
    i30 = i30 * invDet

    local i01 = -(v5 * self.data[1][2] - v4 * self.data[1][3] + v3 * self.data[1][4]) * invDet
    local i11 = (v5 * self.data[1][1] - v2 * self.data[1][3] + v1 * self.data[1][4]) * invDet
    local i21 = -(v4 * self.data[1][1] - v2 * self.data[1][2] + v0 * self.data[1][4]) * invDet
    local i31 = (v3 * self.data[1][1] - v1 * self.data[1][2] + v0 * self.data[1][3]) * invDet

    v0 = self.data[2][1] * self.data[4][2] - self.data[2][2] * self.data[4][1]
    v1 = self.data[2][1] * self.data[4][3] - self.data[2][3] * self.data[4][1]
    v2 = self.data[2][1] * self.data[4][4] - self.data[2][4] * self.data[4][1]
    v3 = self.data[2][2] * self.data[4][3] - self.data[2][3] * self.data[4][2]
    v4 = self.data[2][2] * self.data[4][4] - self.data[2][4] * self.data[4][2]
    v5 = self.data[2][3] * self.data[4][4] - self.data[2][4] * self.data[4][3]

    local i02 = (v5 * self.data[1][2] - v4 * self.data[1][3] + v3 * self.data[1][4]) * invDet
    local i12 = -(v5 * self.data[1][1] - v2 * self.data[1][3] + v1 * self.data[1][4]) * invDet
    local i22 = (v4 * self.data[1][1] - v2 * self.data[1][2] + v0 * self.data[1][4]) * invDet
    local i32 = -(v3 * self.data[1][1] - v1 * self.data[1][2] + v0 * self.data[1][3]) * invDet

    v0 = self.data[3][1] * self.data[2][2] - self.data[3][2] * self.data[2][1]
    v1 = self.data[3][1] * self.data[2][3] - self.data[3][3] * self.data[2][1]
    v2 = self.data[3][1] * self.data[2][4] - self.data[3][4] * self.data[2][1]
    v3 = self.data[3][2] * self.data[2][3] - self.data[3][3] * self.data[2][2]
    v4 = self.data[3][2] * self.data[2][4] - self.data[3][4] * self.data[2][2]
    v5 = self.data[3][3] * self.data[2][4] - self.data[3][4] * self.data[2][3]

    local i03 = -(v5 * self.data[1][2] - v4 * self.data[1][3] + v3 * self.data[1][4]) * invDet
    local i13 = (v5 * self.data[1][1] - v2 * self.data[1][3] + v1 * self.data[1][4]) * invDet
    local i23 = -(v4 * self.data[1][1] - v2 * self.data[1][2] + v0 * self.data[1][4]) * invDet
    local i33 = (v3 * self.data[1][1] - v1 * self.data[1][2] + v0 * self.data[1][3]) * invDet

    local res = Mat4.New()
    res:SetData(
        i00, i01, i02, i03,
        i10, i11, i12, i13,
        i20, i21, i22, i23,
        i30, i31, i32, i33)
    return res
end

function Mat4:ToMat3()
    local res = Mat3.New()
    res:SetData(
        self.data[1][1],
        self.data[1][2],
        self.data[1][3],
        self.data[2][1],
        self.data[2][2],
        self.data[2][3],
        self.data[3][1],
        self.data[3][2],
        self.data[3][3]
    )
    return res
end
--分解
function Mat4:Decompose()
    local translation = Vec3.New()
    local rotation = Quat.New()
    local scale = Vec3.New()

    translation.x = self.data[1][4]
    translation.y = self.data[2][4]
    translation.z = self.data[3][4]

    scale.x = math.sqrt(self.data[1][1] * self.data[1][1] + self.data[2][1] * self.data[2][1] + self.data[3][1] * self.data[3][1])
    scale.y = math.sqrt(self.data[1][2] * self.data[1][2] + self.data[2][2] * self.data[2][2] + self.data[3][2] * self.data[3][2])
    scale.z = math.sqrt(self.data[1][3] * self.data[1][3] + self.data[2][3] * self.data[2][3] + self.data[3][3] * self.data[3][3])

    local invScale = Vec3.New(1.0 / scale.x, 1.0 / scale.y, 1.0 / scale.z)
    rotation = self:ToMat3():Scaled(invScale)
    
    return translation, rotation, scale
end

--拷贝
function Mat4:Clone()
    local res = Mat4.New()
    for i = 1, 4 do
        for j = 1, 4 do
            res.data[i][j] = self.data[i][j]
        end
    end
    return res
end

return Mat4