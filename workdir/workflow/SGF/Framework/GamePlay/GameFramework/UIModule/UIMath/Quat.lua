-- 说明:四元数类
-- 日期:2025年4月21日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local Vec3 = GFScript("UIModule.UIMath.Vec3")
local Mat3 = GFScript("UIModule.UIMath.Mat3")
local MathDefines = GFScript("UIModule.UIMath.MathDefines")
local FaceCameraMode = MathDefines.FaceCameraMode
local Quat = {}

--实例化
function Quat.New(w, x, y, z)
    local obj = {}
    if type(w) == "table" and #w == 4 then
        obj.z = w[4]
        obj.y = w[3]
        obj.x = w[2]
        obj.w = w[1]
    else
        obj.w = w or 1
        obj.x = x or 0
        obj.y = y or 0
        obj.z = z or 0
    end
    Quat.__index = Quat
    setmetatable(obj, Quat)
    return obj
end

--按table创建
function Quat.newByTable(t)
    return Quat.New(t.w, t.x, t.y, t.z)
end

function Quat.identity()
    return Quat.New(1, 0, 0, 0)
end

function Quat.euler(x, y, z)
    if type(x) == "table" then
        y = x.y
        z = x.z
        x = x.x
    end
    local q = Quat.New()
    q:FromEuler(Vec3.New(x, y, z))
    return q
end

function Quat.lookAt(dir)
    local q = Quat.New()
    q:FromLookRotation(dir)
    return q
end

---------------------------------运算符重载-------------------------------
Quat.__add = function(lhs, rhs)
    return Quat.New(lhs.w + rhs.w, lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
end

Quat.__sub = function(lhs, rhs)
    return Quat.New(lhs.w - rhs.w, lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
end

Quat.__mul = function(lhs, rhs)
    if type(lhs) == "number" then
        return Quat.New(lhs * rhs.w, lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    elseif type(rhs) == "number" then
        return Quat.New(lhs.w * rhs, lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    elseif getmetatable(lhs) == Quat and getmetatable(rhs) == Vec3 then
        return lhs:MulVec3(rhs)
    else
        if rhs.x and rhs.y and rhs.z then
            if rhs.w then
                return Quat.New(
                    lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
                    lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
                    lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
                    lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w
                )
            else
                return lhs:MulVec3(Vec3.New(rhs.x, rhs.y, rhs.z))
            end
        end
    end
end

Quat.__div = function(lhs, rhs)
    return Quat.New(lhs.w / rhs, lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
end

Quat.__unm = function(q)
    return Quat.New(-q.w, -q.x, -q.y, -q.z)
end

Quat.__eq = function(lhs, rhs)
    return lhs:Equals(rhs)
end

Quat.__tostring = function(q)
    return string.format("Quat(%f, %f, %f, %f)", q.w, q.x, q.y, q.z)
end

function Quat:ToEulerString()
    local euler = self:ToEuler()
    return string.format("Euler(%f, %f, %f)", euler.x, euler.y, euler.z)
end

---------------------------------运算符重载-------------------------------

function Quat:IsNaN()
    return self.w ~= self.w or self.x ~= self.x or self.y ~= self.y or self.z ~= self.z
end

function Quat:Equals(other)
    return math.abs(self.w - other.w) < MathDefines.M_EPSILON and 
           math.abs(self.x - other.x) < MathDefines.M_EPSILON and 
           math.abs(self.y - other.y) < MathDefines.M_EPSILON and 
           math.abs(self.z - other.z) < MathDefines.M_EPSILON
end

function Quat:Length()
    return math.sqrt(self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z)
end

function Quat:FromAngleAxis(angle, axis)
    local normAxis = axis:Normalized()
    angle = angle * MathDefines.M_DEGTORAD_2
    local sinAngle = math.sin(angle)
    local cosAngle = math.cos(angle)

    self.w = cosAngle
    self.x = normAxis.x * sinAngle
    self.y = normAxis.y * sinAngle
    self.z = normAxis.z * sinAngle
end

function Quat:ToAngleAxis()
    local halfAngle = math.acos(self.w)
    local sinHalfAngle = math.sin(halfAngle)
    if sinHalfAngle < 0.0001 then
        return 0, Vec3.New(1, 0, 0)
    end
    local angle = halfAngle * 2
    local axis = Vec3.New(self.x, self.y, self.z) / sinHalfAngle
    return angle, axis
end

function Quat:FromEuler(euler)
    self:FromEulerXYZ(euler.x, euler.y, euler.z)
end

function Quat:FromEulerXYZ(x,y,z)
    local halfX = x * 0.5 * MathDefines.M_DEGTORAD
    local halfY = y * 0.5 * MathDefines.M_DEGTORAD
    local halfZ = z * 0.5 * MathDefines.M_DEGTORAD
    local cosX = math.cos(halfX)
    local sinX = math.sin(halfX)
    local cosY = math.cos(halfY)
    local sinY = math.sin(halfY)
    local cosZ = math.cos(halfZ)
    local sinZ = math.sin(halfZ)
    self.x = sinX * cosY * cosZ + cosX * sinY * sinZ
    self.y = cosX * sinY * cosZ - sinX * cosY * sinZ
    self.z = cosX * cosY * sinZ - sinX * sinY * cosZ
    self.w = cosX * cosY * cosZ + sinX * sinY * sinZ
end

function Quat:ToEuler()
    local check = 2 * (-self.y*self.z + self.w*self.x)
    if check < -0.995 then
        return Vec3.New(-90,0,
                -math.atan2(2 * (self.x * self.z - self.w * self.y), 1 - 2 * (self.y * self.y + self.z * self.z)) * MathDefines.M_RADTODEG)
    elseif check > 0.995 then
        return Vec3.New(90,0,
                math.atan2(2 * (self.x * self.z - self.w * self.y), 1 - 2 * (self.y * self.y + self.z * self.z)) * MathDefines.M_RADTODEG)
    else
        return Vec3.New(
                math.asin(check) * MathDefines.M_RADTODEG,
                math.atan2(2 * (self.x * self.z + self.w * self.y), 1 - 2 * (self.x * self.x + self.y * self.y)) * MathDefines.M_RADTODEG,
                math.atan2(2 * (self.x * self.y + self.w * self.z), 1 - 2 * (self.x * self.x + self.z * self.z)) * MathDefines.M_RADTODEG
            )
    end
end

function Quat:FromRotationTo(from, to)
    local normStart = from:Normalized()
    local normEnd = to:Normalized()
    local d = normStart:Dot(normEnd)
    if d > (-1 + MathDefines.M_EPSILON) then
        local c = normStart:Cross(normEnd)
        local s = math.sqrt((1 + d) * 2)
        local invS = 1 / s
        self.x = c.x * invS
        self.y = c.y * invS
        self.z = c.z * invS
        self.w = 0.5 * s
    else
        local axis = Vec3.New(1,0,0):Cross(normStart)
        if axis:Magnitude() < MathDefines.M_EPSILON then
            axis = Vec3.New(0,1,0):Cross(normStart)
        end
        self:FromAngleAxis(180,axis)
    end
end

function Quat:FromLookRotation(direction, upDirection)
    upDirection = upDirection or Vec3.New(0,1,0)
    local ret = Quat.New()
    local forward = direction:Normalized()

    local v = forward:Cross(upDirection)
    if v:SqrMagnitude() >= MathDefines.M_EPSILON then
        v:Normalize()
        local up = v:Cross(forward)
        local right = up:Cross(forward)
        ret:FromAxes(right, up, forward)
    else 
        ret:FromRotationTo(Vec3.New(0,0,1), forward)
    end
    if not self:IsNaN() then
        self.w = ret.w
        self.x = ret.x
        self.y = ret.y
        self.z = ret.z
        return true
    else
        return false
    end
end

function Quat:FromDirection(direction)
    self:FromRotationTo(Vec3.New(0,0,1), direction)
end

function Quat:GetLeft()
    return self:MulVec3(Vec3.New(-1,0,0))
end

function Quat:GetUp()
    return self:MulVec3(Vec3.New(0,1,0))
end

function Quat:GetForward()
    return self:MulVec3(Vec3.New(0,0,1))
end

function Quat:GetBackward()
    return self:MulVec3(Vec3.New(0,0,-1))
end

function Quat:GetRight()
    return self:MulVec3(Vec3.New(1,0,0))
end

function Quat:GetDown()
    return self:MulVec3(Vec3.New(0,-1,0))
end

function Quat:Normalize()
    local length = self:Length()
    if length > 0 then
        return Quat.New(self.w / length, self.x / length, self.y / length, self.z / length)
    else
        return Quat.New(1, 0, 0, 0)
    end
end

function Quat:Inversed()
    local factor = 1 / (self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z)
    return Quat.New(self.w * factor, -self.x * factor, -self.y * factor, -self.z * factor)
end

function Quat:Inverse()
    local factor = 1 / (self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z)
    self.w = self.w * factor
    self.x = -self.x * factor
    self.y = -self.y * factor
    self.z = -self.z * factor
end

function Quat:InverseRotate(v)
    return self:Inversed():MulVec3(v)
end

function Quat:Rotate(v)
    return self:MulVec3(v)
end

function Quat:MulVec3(v)
    local qvec = Vec3.New(self.x,self.y,self.z)
    local uv = qvec:Cross(v)
    local uuv = qvec:Cross(uv)
    return v + uv * (2 * self.w) + uuv * 2
end

function Quat:MulQuat(q)
    return Quat.New(
        self.w * q.w - self.x * q.x - self.y * q.y - self.z * q.z,
        self.w * q.x + self.x * q.w + self.y * q.z - self.z * q.y,
        self.w * q.y - self.x * q.z + self.y * q.w + self.z * q.x,
        self.w * q.z + self.x * q.y - self.y * q.x + self.z * q.w
    )
end

function Quat:Dot(q)
    return self.w * q.w + self.x * q.x + self.y * q.y + self.z * q.z
end

function Quat:Cross(q)
    local w = self.w * q.w - self.x * q.x - self.y * q.y - self.z * q.z
    local x = self.w * q.x + self.x * q.w + self.y * q.z - self.z * q.y
    local y = self.w * q.y - self.x * q.z + self.y * q.w + self.z * q.x
    local z = self.w * q.z + self.x * q.y - self.y * q.x + self.z * q.w
    return Quat.New(w, x, y, z)
end

--球面插值
function Quat:Slerp(to, t)
    -- Clamp t to [0,1]
    t = math.max(0, math.min(1, t))
    
    -- Check if quaternions are nearly equal
    local cosAngle = self:Dot(to)
    if math.abs(cosAngle) >= 0.9999 then
        -- Quaternions are very close - linear interpolation is fine
        return (self + (to - self) * t):Normalize()
    end

    -- Ensure we take the shortest path
    local sign = 1.0
    if cosAngle < 0.0 then
        cosAngle = -cosAngle
        sign = -1.0
    end

    local angle = math.acos(cosAngle)
    local sinAngle = math.sin(angle)
    
    local t1, t2
    if sinAngle > 0.001 then
        local invSinAngle = 1.0 / sinAngle
        t1 = math.sin((1.0 - t) * angle) * invSinAngle
        t2 = math.sin(t * angle) * invSinAngle
    else
        t1 = 1.0 - t
        t2 = t
    end

    -- Return normalized result
    return (self * t1 + to * (sign * t2)):Normalize()
end

function Quat:Lerp(to, t)
    return self * (1 - t) + to * t
end

function Quat:Reflect(normal)
    return self - 2 * self:Dot(normal) * normal
end

function Quat:Perpendicular()
    local x = self.x
    local y = self.y
    local z = self.z
    if math.abs(x) <= math.abs(y) and math.abs(x) <= math.abs(z) then
        return Quat.New(0, -z, y, -x)
    elseif math.abs(y) <= math.abs(x) and math.abs(y) <= math.abs(z) then
        return Quat.New(-z, 0, x, -y)
    else
        return Quat.New(-y, x, -z, 0)
    end
end

function Quat:Conjugate()
    return Quat.New(self.w, -self.x, -self.y, -self.z)
end

function Quat:SetYaw(yaw)
    local halfYaw = yaw * 0.5
    local cosHalfYaw = math.cos(halfYaw)
    local sinHalfYaw = math.sin(halfYaw)
    self.w = cosHalfYaw
    self.x = 0
    self.y = sinHalfYaw
    self.z = 0
end

function Quat:SetPitch(pitch)
    local halfPitch = pitch * 0.5
    local cosHalfPitch = math.cos(halfPitch)
    local sinHalfPitch = math.sin(halfPitch)
    self.w = cosHalfPitch
    self.x = sinHalfPitch
    self.y = 0
    self.z = 0
end

function Quat:SetRoll(roll)
    local halfRoll = roll * 0.5
    local cosHalfRoll = math.cos(halfRoll)
    local sinHalfRoll = math.sin(halfRoll)
    self.w = cosHalfRoll
    self.x = 0
    self.y = 0
    self.z = sinHalfRoll
end

--获取Yaw
function Quat:GetYaw()
    return math.atan2(2 * (self.w * self.y + self.z * self.x), 1 - 2 * (self.x * self.x + self.y * self.y))
end

--获取Pitch
function Quat:GetPitch()
    return math.asin(2 * (self.w * self.x - self.y * self.z))
end

--获取Roll
function Quat:GetRoll()
    return math.atan2(2 * (self.w * self.z + self.x * self.y), 1 - 2 * (self.y * self.y + self.z * self.z))
end

--转换成表
function Quat:Serialize()
    return {self.w, self.x, self.y, self.z}
end

--从表创建
function Quat:Deserialize(t)
    self.w, self.x, self.y, self.z = t[1], t[2], t[3], t[4]
end
function Quat:Clone()
    return Quat.New(self.w, self.x, self.y, self.z)
end
--转换成表
function Quat:ToTable()
    return {self.w, self.x, self.y, self.z}
end

--按Y轴旋转
function Quat:AddEulerY(angle)
    local euler = self:ToEuler()
    local retQuat = Quat.identity()

    retQuat:FromEuler({x = euler.x, y = euler.y + angle, z = euler.z })
    return retQuat
end

function Quat:FromAxes(xAxis, yAxis, zAxis)
    local matrix = Mat3.New()
    matrix:SetData(
        xAxis.x, yAxis.x, zAxis.x,
        xAxis.y, yAxis.y, zAxis.y,
        xAxis.z, yAxis.z, zAxis.z
    )
    self:FromMat3(matrix)
end

function Quat:ToAxes()
    local kRot = self:ToMat3()
    return 
        Vec3.New(kRot.data[1][1], kRot.data[2][1], kRot.data[3][1]),
        Vec3.New(kRot.data[1][2], kRot.data[2][2], kRot.data[3][2]),
        Vec3.New(kRot.data[1][3], kRot.data[2][3], kRot.data[3][3])
end

function Quat:FromMat3(matrix)
    local t = matrix.data[1][1] + matrix.data[2][2] + matrix.data[3][3]

    if t > 0 then
        local invS = 0.5 / math.sqrt(1 + t)
        self.x = (matrix.data[3][2] - matrix.data[2][3]) * invS
        self.y = (matrix.data[1][3] - matrix.data[3][1]) * invS
        self.z = (matrix.data[2][1] - matrix.data[1][2]) * invS
        self.w = 0.25 / invS
    else
        if matrix.data[1][1] > matrix.data[2][2] and matrix.data[1][1] > matrix.data[3][3] then
            local invS = 0.5 / math.sqrt(1 + matrix.data[1][1] - matrix.data[2][2] - matrix.data[3][3])
            self.x = 0.25 / invS
            self.y = (matrix.data[1][2] + matrix.data[2][1]) * invS
            self.z = (matrix.data[3][1] + matrix.data[1][3]) * invS
            self.w = (matrix.data[3][2] - matrix.data[2][3]) * invS
        elseif matrix.data[2][2] > matrix.data[3][3] then
            local invS = 0.5 / math.sqrt(1 + matrix.data[2][2] - matrix.data[1][1] - matrix.data[3][3])
            self.x = (matrix.data[1][2] + matrix.data[2][1]) * invS
            self.y = 0.25 / invS
            self.z = (matrix.data[2][3] + matrix.data[3][2]) * invS
            self.w = (matrix.data[1][3] - matrix.data[3][1]) * invS
        else
            local invS = 0.5 / math.sqrt(1 + matrix.data[3][3] - matrix.data[1][1] - matrix.data[2][2])
            self.x = (matrix.data[1][3] + matrix.data[3][1]) * invS
            self.y = (matrix.data[2][3] + matrix.data[3][2]) * invS
            self.z = 0.25 / invS
            self.w = (matrix.data[2][1] - matrix.data[1][2]) * invS
        end
    end
end

function Quat:ToMat3()
    local fTx  = self.x + self.x
    local fTy  = self.y + self.y
    local fTz  = self.z + self.z
    local fTwx = fTx * self.w
    local fTwy = fTy * self.w
    local fTwz = fTz * self.w
    local fTxx = fTx * self.x
    local fTxy = fTy * self.x
    local fTxz = fTz * self.x
    local fTyy = fTy * self.y
    local fTyz = fTz * self.y
    local fTzz = fTz * self.z

    local kRot = Mat3.New()
    kRot:Set(1, 1, 1.0 - (fTyy + fTzz))
    kRot:Set(1, 2, fTxy - fTwz)
    kRot:Set(1, 3, fTxz + fTwy)
    kRot:Set(2, 1, fTxy + fTwz)
    kRot:Set(2, 2, 1.0 - (fTxx + fTzz))
    kRot:Set(2, 3, fTyz - fTwx)
    kRot:Set(3, 1, fTxz - fTwy)
    kRot:Set(3, 2, fTyz + fTwx)
    kRot:Set(3, 3, 1.0 - (fTxx + fTyy))
    return kRot
end

function Quat:GetFaceCameraRotation(cameraPos, cameraRotation, pos, rotation, faceMode, minAngle)
    if faceMode == FaceCameraMode.FC_ROTATE_XYZ then
        return cameraRotation
    elseif faceMode == FaceCameraMode.FC_ROTATE_Y then
        local euler = rotation:ToEuler()
        euler.y = cameraRotation:ToEuler().y
        local ret = Quat.New()
        ret:FromEuler(euler)
        return ret
    elseif faceMode == FaceCameraMode.FC_LOOKAT_XYZ then
        local ret = Quat.New()
        ret:FromLookRotation(cameraPos - pos)
        return ret
    elseif faceMode == FaceCameraMode.FC_LOOKAT_Y or faceMode == FaceCameraMode.FC_LOOKAT_MIXED then
        local lookAtVec = pos - cameraPos
        local lookAtVecXZ = Vec3.New(lookAtVec.x,0,lookAtVec.z)
        local lookAt = Quat.New()
        lookAt:FromLookRotation(lookAtVecXZ)
        local euler = rotation:ToEuler()
        if faceMode == FaceCameraMode.FC_LOOKAT_MIXED then
            local angle = lookAtVec:AngleBetween(rotation * Vec3.New(0,1,0))
            if angle > 180 - minAngle then
                euler.x = euler.x + minAngle - (180 - angle)
            elseif angle < minAngle then
                euler.x = euler.x - minAngle + angle
            end
        end
        euler.y = lookAt:ToEuler().y
        local ret = Quat.New()
        ret:FromEuler(euler)
        return ret
    end
    return rotation
end

function Quat:Angle(quat)
    local dot = self:Dot(quat)
    local angle = math.acos(math.min(math.max(dot, -1), 1)) * 180 / MathDefines.M_PI
    return angle
end

function Quat:Set(w, x, y, z)
    self.w, self.x, self.y, self.z = w, x, y, z
    return self
end

return Quat