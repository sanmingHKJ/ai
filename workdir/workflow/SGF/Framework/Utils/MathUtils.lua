--[[
    MathUtils - Mathematical utility functions for SGF
    
    Features:
    - Extended math operations
    - Vector and matrix operations
    - Geometry calculations
    - Random number utilities
    - Interpolation functions
    - Physics calculations
]]

local MathUtils = {}

-- Constants
MathUtils.PI = math.pi
MathUtils.TWO_PI = math.pi * 2
MathUtils.HALF_PI = math.pi * 0.5
MathUtils.DEG_TO_RAD = math.pi / 180
MathUtils.RAD_TO_DEG = 180 / math.pi
MathUtils.EPSILON = 1e-6

-- ===========================================
-- Basic Math Extensions
-- ===========================================

--[[
    Clamp a value between min and max
    @param value (number) Value to clamp
    @param minValue (number) Minimum value
    @param maxValue (number) Maximum value
    @return (number) Clamped value
]]
function MathUtils.clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

--[[
    Linear interpolation between two values
    @param a (number) Start value
    @param b (number) End value
    @param t (number) Interpolation factor (0-1)
    @return (number) Interpolated value
]]
function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

--[[
    Inverse linear interpolation
    @param a (number) Start value
    @param b (number) End value
    @param value (number) Value to find t for
    @return (number) Interpolation factor
]]
function MathUtils.inverseLerp(a, b, value)
    if math.abs(b - a) < MathUtils.EPSILON then
        return 0
    end
    return (value - a) / (b - a)
end

--[[
    Remap a value from one range to another
    @param value (number) Input value
    @param fromMin (number) Input range minimum
    @param fromMax (number) Input range maximum
    @param toMin (number) Output range minimum
    @param toMax (number) Output range maximum
    @return (number) Remapped value
]]
function MathUtils.remap(value, fromMin, fromMax, toMin, toMax)
    local t = MathUtils.inverseLerp(fromMin, fromMax, value)
    return MathUtils.lerp(toMin, toMax, t)
end

--[[
    Smooth step interpolation (S-curve)
    @param t (number) Input value (0-1)
    @return (number) Smoothed value
]]
function MathUtils.smoothstep(t)
    t = MathUtils.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

--[[
    Smoother step interpolation (more S-curve)
    @param t (number) Input value (0-1)
    @return (number) Smoothed value
]]
function MathUtils.smootherstep(t)
    t = MathUtils.clamp(t, 0, 1)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

--[[
    Check if two numbers are approximately equal
    @param a (number) First number
    @param b (number) Second number
    @param epsilon (number) Tolerance (optional)
    @return (boolean) True if approximately equal
]]
function MathUtils.approximately(a, b, epsilon)
    epsilon = epsilon or MathUtils.EPSILON
    return math.abs(a - b) <= epsilon
end

--[[
    Round to nearest decimal places
    @param value (number) Value to round
    @param decimals (number) Number of decimal places
    @return (number) Rounded value
]]
function MathUtils.round(value, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

--[[
    Sign function (-1, 0, or 1)
    @param value (number) Input value
    @return (number) Sign of the value
]]
function MathUtils.sign(value)
    if value > 0 then return 1
    elseif value < 0 then return -1
    else return 0 end
end

--[[
    Convert degrees to radians
    @param degrees (number) Degrees
    @return (number) Radians
]]
function MathUtils.toRadians(degrees)
    return degrees * MathUtils.DEG_TO_RAD
end

--[[
    Convert radians to degrees
    @param radians (number) Radians
    @return (number) Degrees
]]
function MathUtils.toDegrees(radians)
    return radians * MathUtils.RAD_TO_DEG
end

-- ===========================================
-- Vector Operations
-- ===========================================

--[[
    Create a 2D vector
    @param x (number) X component
    @param y (number) Y component
    @return (table) Vector2
]]
function MathUtils.vector2(x, y)
    return {x = x or 0, y = y or 0}
end

--[[
    Create a 3D vector
    @param x (number) X component
    @param y (number) Y component
    @param z (number) Z component
    @return (table) Vector3
]]
function MathUtils.vector3(x, y, z)
    return {x = x or 0, y = y or 0, z = z or 0}
end

--[[
    Add two vectors
    @param a (table) First vector
    @param b (table) Second vector
    @return (table) Result vector
]]
function MathUtils.vectorAdd(a, b)
    if a.z ~= nil and b.z ~= nil then
        return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}
    else
        return {x = a.x + b.x, y = a.y + b.y}
    end
end

--[[
    Subtract two vectors
    @param a (table) First vector
    @param b (table) Second vector
    @return (table) Result vector
]]
function MathUtils.vectorSubtract(a, b)
    if a.z ~= nil and b.z ~= nil then
        return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}
    else
        return {x = a.x - b.x, y = a.y - b.y}
    end
end

--[[
    Multiply vector by scalar
    @param vector (table) Vector
    @param scalar (number) Scalar value
    @return (table) Result vector
]]
function MathUtils.vectorScale(vector, scalar)
    if vector.z ~= nil then
        return {x = vector.x * scalar, y = vector.y * scalar, z = vector.z * scalar}
    else
        return {x = vector.x * scalar, y = vector.y * scalar}
    end
end

--[[
    Calculate dot product of two vectors
    @param a (table) First vector
    @param b (table) Second vector
    @return (number) Dot product
]]
function MathUtils.vectorDot(a, b)
    if a.z ~= nil and b.z ~= nil then
        return a.x * b.x + a.y * b.y + a.z * b.z
    else
        return a.x * b.x + a.y * b.y
    end
end

--[[
    Calculate cross product of two 3D vectors
    @param a (table) First vector
    @param b (table) Second vector
    @return (table) Cross product vector
]]
function MathUtils.vectorCross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

--[[
    Calculate vector magnitude (length)
    @param vector (table) Vector
    @return (number) Magnitude
]]
function MathUtils.vectorMagnitude(vector)
    if vector.z ~= nil then
        return math.sqrt(vector.x^2 + vector.y^2 + vector.z^2)
    else
        return math.sqrt(vector.x^2 + vector.y^2)
    end
end

--[[
    Calculate squared vector magnitude (faster than magnitude)
    @param vector (table) Vector
    @return (number) Squared magnitude
]]
function MathUtils.vectorMagnitudeSqr(vector)
    if vector.z ~= nil then
        return vector.x^2 + vector.y^2 + vector.z^2
    else
        return vector.x^2 + vector.y^2
    end
end

--[[
    Normalize a vector
    @param vector (table) Vector
    @return (table) Normalized vector
]]
function MathUtils.vectorNormalize(vector)
    local mag = MathUtils.vectorMagnitude(vector)
    if mag > MathUtils.EPSILON then
        return MathUtils.vectorScale(vector, 1 / mag)
    else
        if vector.z ~= nil then
            return {x = 0, y = 0, z = 0}
        else
            return {x = 0, y = 0}
        end
    end
end

--[[
    Calculate distance between two points
    @param a (table) First point
    @param b (table) Second point
    @return (number) Distance
]]
function MathUtils.distance(a, b)
    return MathUtils.vectorMagnitude(MathUtils.vectorSubtract(b, a))
end

--[[
    Calculate squared distance between two points
    @param a (table) First point
    @param b (table) Second point
    @return (number) Squared distance
]]
function MathUtils.distanceSqr(a, b)
    return MathUtils.vectorMagnitudeSqr(MathUtils.vectorSubtract(b, a))
end

--[[
    Interpolate between two vectors
    @param a (table) Start vector
    @param b (table) End vector
    @param t (number) Interpolation factor (0-1)
    @return (table) Interpolated vector
]]
function MathUtils.vectorLerp(a, b, t)
    if a.z ~= nil and b.z ~= nil then
        return {
            x = MathUtils.lerp(a.x, b.x, t),
            y = MathUtils.lerp(a.y, b.y, t),
            z = MathUtils.lerp(a.z, b.z, t)
        }
    else
        return {
            x = MathUtils.lerp(a.x, b.x, t),
            y = MathUtils.lerp(a.y, b.y, t)
        }
    end
end

-- ===========================================
-- Geometry Functions
-- ===========================================

--[[
    Calculate angle between two 2D points
    @param from (table) From point
    @param to (table) To point
    @return (number) Angle in radians
]]
function MathUtils.angleBetweenPoints(from, to)
    return math.atan2(to.y - from.y, to.x - from.x)
end

--[[
    Check if point is inside circle
    @param point (table) Point to check
    @param center (table) Circle center
    @param radius (number) Circle radius
    @return (boolean) True if inside
]]
function MathUtils.pointInCircle(point, center, radius)
    return MathUtils.distanceSqr(point, center) <= radius^2
end

--[[
    Check if point is inside rectangle
    @param point (table) Point to check
    @param rect (table) Rectangle {x, y, width, height}
    @return (boolean) True if inside
]]
function MathUtils.pointInRectangle(point, rect)
    return point.x >= rect.x and point.x <= rect.x + rect.width and
           point.y >= rect.y and point.y <= rect.y + rect.height
end

--[[
    Check if two circles overlap
    @param center1 (table) First circle center
    @param radius1 (number) First circle radius
    @param center2 (table) Second circle center
    @param radius2 (number) Second circle radius
    @return (boolean) True if overlapping
]]
function MathUtils.circlesOverlap(center1, radius1, center2, radius2)
    local minDistance = radius1 + radius2
    return MathUtils.distanceSqr(center1, center2) <= minDistance^2
end

--[[
    Check if two rectangles overlap
    @param rect1 (table) First rectangle {x, y, width, height}
    @param rect2 (table) Second rectangle {x, y, width, height}
    @return (boolean) True if overlapping
]]
function MathUtils.rectanglesOverlap(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

-- ===========================================
-- Random Number Utilities
-- ===========================================

--[[
    Random float between min and max
    @param minValue (number) Minimum value
    @param maxValue (number) Maximum value
    @return (number) Random float
]]
function MathUtils.randomFloat(minValue, maxValue)
    return minValue + (maxValue - minValue) * math.random()
end

--[[
    Random integer between min and max (inclusive)
    @param minValue (number) Minimum value
    @param maxValue (number) Maximum value
    @return (number) Random integer
]]
function MathUtils.randomInt(minValue, maxValue)
    return math.random(minValue, maxValue)
end

--[[
    Random boolean with probability
    @param probability (number) Probability (0-1)
    @return (boolean) Random boolean
]]
function MathUtils.randomBool(probability)
    probability = probability or 0.5
    return math.random() < probability
end

--[[
    Random point in circle
    @param center (table) Circle center
    @param radius (number) Circle radius
    @return (table) Random point
]]
function MathUtils.randomPointInCircle(center, radius)
    local angle = MathUtils.randomFloat(0, MathUtils.TWO_PI)
    local distance = MathUtils.randomFloat(0, radius)
    return {
        x = center.x + math.cos(angle) * distance,
        y = center.y + math.sin(angle) * distance
    }
end

--[[
    Random point on circle circumference
    @param center (table) Circle center
    @param radius (number) Circle radius
    @return (table) Random point
]]
function MathUtils.randomPointOnCircle(center, radius)
    local angle = MathUtils.randomFloat(0, MathUtils.TWO_PI)
    return {
        x = center.x + math.cos(angle) * radius,
        y = center.y + math.sin(angle) * radius
    }
end

--[[
    Choose random element from array
    @param array (table) Array to choose from
    @return Element from array
]]
function MathUtils.randomChoice(array)
    if #array == 0 then
        return nil
    end
    return array[math.random(1, #array)]
end

--[[
    Shuffle array in place (Fisher-Yates)
    @param array (table) Array to shuffle
    @return (table) Shuffled array
]]
function MathUtils.shuffleArray(array)
    for i = #array, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

-- ===========================================
-- Easing Functions
-- ===========================================

--[[
    Quadratic ease in
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeInQuad(t)
    return t * t
end

--[[
    Quadratic ease out
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeOutQuad(t)
    return 1 - (1 - t)^2
end

--[[
    Quadratic ease in-out
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - 2 * (1 - t)^2
    end
end

--[[
    Cubic ease in
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeInCubic(t)
    return t^3
end

--[[
    Cubic ease out
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeOutCubic(t)
    return 1 - (1 - t)^3
end

--[[
    Bounce ease out
    @param t (number) Time (0-1)
    @return (number) Eased value
]]
function MathUtils.easeOutBounce(t)
    if t < 1/2.75 then
        return 7.5625 * t * t
    elseif t < 2/2.75 then
        t = t - 1.5/2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5/2.75 then
        t = t - 2.25/2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625/2.75
        return 7.5625 * t * t + 0.984375
    end
end

-- ===========================================
-- Physics Utilities
-- ===========================================

--[[
    Calculate trajectory for projectile motion
    @param startPos (table) Starting position
    @param targetPos (table) Target position
    @param gravity (number) Gravity strength
    @param angle (number) Launch angle in radians (optional)
    @return (table) Velocity vector needed
]]
function MathUtils.calculateTrajectory(startPos, targetPos, gravity, angle)
    local dx = targetPos.x - startPos.x
    local dy = targetPos.y - startPos.y
    
    if angle then
        -- Calculate velocity for given angle
        local velocityMag = math.sqrt(gravity * dx^2 / (dx * math.sin(2 * angle) - 2 * dy * math.cos(angle)^2))
        return {
            x = velocityMag * math.cos(angle),
            y = velocityMag * math.sin(angle)
        }
    else
        -- Calculate optimal angle for minimum velocity
        local optimalAngle = math.atan2(dy + math.sqrt(dy^2 + dx^2), dx) / 2
        return MathUtils.calculateTrajectory(startPos, targetPos, gravity, optimalAngle)
    end
end

--[[
    Calculate spring force
    @param currentPos (number) Current position
    @param targetPos (number) Target position
    @param velocity (number) Current velocity
    @param springConstant (number) Spring strength
    @param damping (number) Damping factor
    @return (number) Spring force
]]
function MathUtils.springForce(currentPos, targetPos, velocity, springConstant, damping)
    local displacement = targetPos - currentPos
    local force = springConstant * displacement - damping * velocity
    return force
end

-- ===========================================
-- Noise Functions
-- ===========================================

--[[
    Simple 1D Perlin-like noise
    @param x (number) Input coordinate
    @param seed (number) Random seed (optional)
    @return (number) Noise value (-1 to 1)
]]
function MathUtils.noise1D(x, seed)
    seed = seed or 1
    x = x + seed * 1000
    local intX = math.floor(x)
    local fracX = x - intX
    
    -- Hash function for pseudo-random values
    local function hash(n)
        n = (n * 1103515245 + 12345) % 2147483648
        n = (n / 2147483648) * 2 - 1
        return n
    end
    
    local a = hash(intX)
    local b = hash(intX + 1)
    
    -- Smooth interpolation
    local smoothFracX = fracX * fracX * (3 - 2 * fracX)
    return MathUtils.lerp(a, b, smoothFracX)
end

--[[
    Fractal noise (sum of octaves)
    @param x (number) Input coordinate
    @param octaves (number) Number of octaves
    @param persistence (number) Amplitude reduction per octave
    @param seed (number) Random seed (optional)
    @return (number) Fractal noise value
]]
function MathUtils.fractalNoise1D(x, octaves, persistence, seed)
    octaves = octaves or 4
    persistence = persistence or 0.5
    
    local total = 0
    local frequency = 1
    local amplitude = 1
    local maxValue = 0
    
    for i = 1, octaves do
        total = total + MathUtils.noise1D(x * frequency, seed) * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * 2
    end
    
    return total / maxValue
end

return MathUtils