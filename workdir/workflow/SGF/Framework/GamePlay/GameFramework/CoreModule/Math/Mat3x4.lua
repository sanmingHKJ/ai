local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Mat3 = GFScript("CoreModule.Math.Mat3")
local Mat3x4 = {}

--实例化
function Mat3x4.New()
    local obj = {}
    Mat3x4.__index = Mat3x4
    setmetatable(obj, Mat3x4)
    obj:SetIdentity()
    return obj
end

function Mat3x4:FromTransforms(translation, rotation, scale)
    local rotMat = rotation:ToMat3()
    -- 先设置旋转
    self:SetRotation(rotMat:Scaled(scale))
    -- 设置平移
    self:SetTranslation(translation)

end

--设置单位矩阵
function Mat3x4:SetIdentity()
    self.data = {
        {1, 0, 0, 0},
        {0, 1, 0, 0},
        {0, 0, 1, 0}
    }
end

--设置
function Mat3x4:SetData(m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23)
    self.data = {
        {m00, m01, m02, m03},
        {m10, m11, m12, m13},
        {m20, m21, m22, m23}
    }
end

--矩阵乘法
function Mat3x4:Mul(mat)
    local result = Mat3x4.New()
    
    -- 3x3 rotation/scale part
    result.data[1][1] = self.data[1][1] * mat.data[1][1] + self.data[1][2] * mat.data[2][1] + self.data[1][3] * mat.data[3][1]
    result.data[1][2] = self.data[1][1] * mat.data[1][2] + self.data[1][2] * mat.data[2][2] + self.data[1][3] * mat.data[3][2]
    result.data[1][3] = self.data[1][1] * mat.data[1][3] + self.data[1][2] * mat.data[2][3] + self.data[1][3] * mat.data[3][3]
    
    result.data[2][1] = self.data[2][1] * mat.data[1][1] + self.data[2][2] * mat.data[2][1] + self.data[2][3] * mat.data[3][1]
    result.data[2][2] = self.data[2][1] * mat.data[1][2] + self.data[2][2] * mat.data[2][2] + self.data[2][3] * mat.data[3][2]
    result.data[2][3] = self.data[2][1] * mat.data[1][3] + self.data[2][2] * mat.data[2][3] + self.data[2][3] * mat.data[3][3]
    
    result.data[3][1] = self.data[3][1] * mat.data[1][1] + self.data[3][2] * mat.data[2][1] + self.data[3][3] * mat.data[3][1]
    result.data[3][2] = self.data[3][1] * mat.data[1][2] + self.data[3][2] * mat.data[2][2] + self.data[3][3] * mat.data[3][2]
    result.data[3][3] = self.data[3][1] * mat.data[1][3] + self.data[3][2] * mat.data[2][3] + self.data[3][3] * mat.data[3][3]
    
    -- Translation part
    result.data[1][4] = self.data[1][1] * mat.data[1][4] + self.data[1][2] * mat.data[2][4] + self.data[1][3] * mat.data[3][4] + self.data[1][4]
    result.data[2][4] = self.data[2][1] * mat.data[1][4] + self.data[2][2] * mat.data[2][4] + self.data[2][3] * mat.data[3][4] + self.data[2][4]
    result.data[3][4] = self.data[3][1] * mat.data[1][4] + self.data[3][2] * mat.data[2][4] + self.data[3][3] * mat.data[3][4] + self.data[3][4]
    
    return result
end
--矩阵乘向量
function Mat3x4:MulVec3(vec3)
    local res = Vec3.New()
    res.x = self.data[1][1] * vec3.x + self.data[1][2] * vec3.y + self.data[1][3] * vec3.z + self.data[1][4]
    res.y = self.data[2][1] * vec3.x + self.data[2][2] * vec3.y + self.data[2][3] * vec3.z + self.data[2][4]
    res.z = self.data[3][1] * vec3.x + self.data[3][2] * vec3.y + self.data[3][3] * vec3.z + self.data[3][4]
    return res
end

function Mat3x4:MulVec4(vec4)
    local res = Vec3.New()
    res.x = self.data[1][1] * vec4.x + self.data[1][2] * vec4.y + self.data[1][3] * vec4.z + self.data[1][4] 
    res.y = self.data[2][1] * vec4.x + self.data[2][2] * vec4.y + self.data[2][3] * vec4.z + self.data[2][4]
    res.z = self.data[3][1] * vec4.x + self.data[3][2] * vec4.y + self.data[3][3] * vec4.z + self.data[3][4]
    return res
end



---------------------------------运算符重载-------------------------------
function Mat3x4.__add(lhs, rhs)
    local res = Mat3x4.New()
    for i = 1, 3 do
        for j = 1, 4 do
            res.data[i][j] = lhs.data[i][j] + rhs.data[i][j]
        end
    end
    return res
end

function Mat3x4.__sub(lhs, rhs)
    local res = Mat3x4.New()
    for i = 1, 3 do
        for j = 1, 4 do
            res.data[i][j] = lhs.data[i][j] - rhs.data[i][j]
        end
    end
    return res
end
--乘
function Mat3x4.__mul(lhs, rhs)
    if rhs.x and rhs.y and rhs.z and rhs.w then
        return lhs:MulVec4(rhs)
    elseif rhs.x and rhs.y and rhs.z then
        return lhs:MulVec3(rhs)
    else
        return lhs:Mul(rhs)
    end
end

function Mat3x4:__tostring()
    return string.format(
        "[[%f, %f, %f, %f], [%f, %f, %f, %f], [%f, %f, %f, %f]]",
        self.data[1][1], self.data[1][2], self.data[1][3], self.data[1][4],
        self.data[2][1], self.data[2][2], self.data[2][3], self.data[2][4],
        self.data[3][1], self.data[3][2], self.data[3][3], self.data[3][4]
    )
end
--设置平移
function Mat3x4:SetTranslation(x, y, z)
    if type(x) == "table" then
        x, y, z = x.x, x.y, x.z
    end
    self.data[1][4] = x
    self.data[2][4] = y
    self.data[3][4] = z
end

function Mat3x4:GetTranslation()
    return Vec3.New(self.data[1][4], self.data[2][4], self.data[3][4])
end

--设置旋转
function Mat3x4:SetRotation(rotation)
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
function Mat3x4:GetRotation()
    local mat3 = Mat3.New(self.data[1][1], self.data[1][2], self.data[1][3],
                    self.data[2][1], self.data[2][2], self.data[2][3],
                    self.data[3][1], self.data[3][2], self.data[3][3])
    local quat = Quat.New()
    quat:FromMat3(mat3)
    return quat
end
--设置缩放
function Mat3x4:SetScale(x, y, z)
    if type(x) == "table" then
        x, y, z = x.x, x.y, x.z
    end
    self.data[1][1] = x
    self.data[2][2] = y
    self.data[3][3] = z
end

function Mat3x4:GetScale()
    return Vec3.New(self.data[1][1], self.data[2][2], self.data[3][3])
end

--逆矩阵
function Mat3x4:Inverse()
    local det = self.data[1][1] * (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2]) -
                self.data[1][2] * (self.data[2][1] * self.data[3][3] - self.data[2][3] * self.data[3][1]) +
                self.data[1][3] * (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1])
    if det == 0 then
        return nil
    end
    local invDet = 1 / det
    local res = Mat3x4.New()
    res.data[1][1] = invDet * (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2])
    res.data[1][2] = invDet * (self.data[1][3] * self.data[3][2] - self.data[1][2] * self.data[3][3])
    res.data[1][3] = invDet * (self.data[1][2] * self.data[2][3] - self.data[1][3] * self.data[2][2])
    res.data[1][4] = -(self.data[1][4] * res.data[1][1] + self.data[2][4] * res.data[1][2] + self.data[3][4] * res.data[1][3])
    
    res.data[2][1] = invDet * (self.data[2][3] * self.data[3][1] - self.data[2][1] * self.data[3][3])
    res.data[2][2] = invDet * (self.data[1][1] * self.data[3][3] - self.data[1][3] * self.data[3][1])
    res.data[2][3] = invDet * (self.data[1][3] * self.data[2][1] - self.data[1][1] * self.data[2][3])
    res.data[2][4] = -(self.data[1][4] * res.data[2][1] + self.data[2][4] * res.data[2][2] + self.data[3][4] * res.data[2][3])
    
    res.data[3][1] = invDet * (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1])
    res.data[3][2] = invDet * (self.data[1][2] * self.data[3][1] - self.data[1][1] * self.data[3][2])
    res.data[3][3] = invDet * (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1])
    res.data[3][4] = -(self.data[1][4] * res.data[3][1] + self.data[2][4] * res.data[3][2] + self.data[3][4] * res.data[3][3])
    return res
end

function Mat3x4:ToMat3()
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

function Mat3x4:ToMat4()
    local res = Mat4.New()
    res:SetData(
        self.data[1][1],
        self.data[1][2],
        self.data[1][3],
        self.data[1][4],
        self.data[2][1],
        self.data[2][2],
        self.data[2][3],
        self.data[2][4],
        self.data[3][1],
        self.data[3][2],
        self.data[3][3],
        self.data[3][4],
        0, 0, 0, 1
    )
    return res
end
--分解
function Mat3x4:Decompose()
    local translation = Vec3.New()
    local rotation = Quat.New()
    local scale = Vec3.New()

    -- 获取平移分量
    translation.x = self.data[1][4]
    translation.y = self.data[2][4]
    translation.z = self.data[3][4]

    -- 获取缩放分量（包含符号）
    local m11 = self.data[1][1]
    local m12 = self.data[1][2]
    local m13 = self.data[1][3]
    local m21 = self.data[2][1]
    local m22 = self.data[2][2]
    local m23 = self.data[2][3]
    local m31 = self.data[3][1]
    local m32 = self.data[3][2]
    local m33 = self.data[3][3]

    scale.x = math.sqrt(m11 * m11 + m21 * m21 + m31 * m31) 
    scale.y = math.sqrt(m12 * m12 + m22 * m22 + m32 * m32)
    scale.z = math.sqrt(m13 * m13 + m23 * m23 + m33 * m33)

    local mat3 = self:ToMat3()
    mat3:Scaled(Vec3.New(1 / scale.x, 1 / scale.y, 1 / scale.z))

    -- 从旋转矩阵转换为四元数
    rotation:FromMat3(mat3)

    return translation, rotation, scale
end


--拷贝
function Mat3x4:Clone()
    local res = Mat3x4.New()
    for i = 1, 3 do
        for j = 1, 4 do
            res.data[i][j] = self.data[i][j]
        end
    end
    return res
end

return Mat3x4