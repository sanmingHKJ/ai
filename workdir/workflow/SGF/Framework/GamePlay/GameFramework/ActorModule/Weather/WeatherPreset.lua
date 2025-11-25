local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local DataProviderManager = GFScript("CoreModule.DataProviderManager")
local Vec3 = GFScript("CoreModule.Math.Vec3")
local Quat = GFScript("CoreModule.Math.Quat")
local Color = GFScript("CoreModule.Math.Color")

local WeatherPreset = Class.New("WeatherPreset")

--初始化
function WeatherPreset:Constructor()
    --天气名称
    self.name = nil
    --天气类型
    self.weatherType = nil
    --天气强度
    self.weatherIntensity = nil
    --天气持续时间
    self.weatherDuration = nil

    self.lightDirection = nil
    self.lightIntensity = nil
    self.lightColor = nil

    self.fogDensity = nil
    self.fogColor = nil
    self.fogStart = nil
    self.fogEnd = nil

    self.effect = nil

    self.snowAmount = nil
    self.windStrength = nil
    self.wetness = nil

    self.skybox = nil
    self.skyboxAlpha = nil
end

--插值
function WeatherPreset:Lerp(target, time)
    local data = {}

    local selfLightDirection = Quat.euler(self.lightDirection.x, self.lightDirection.y, self.lightDirection.z)
    local targetLightDirection = Quat.euler(target.lightDirection.x, target.lightDirection.y, target.lightDirection.z)
    local dirDelta = selfLightDirection:Slerp(targetLightDirection, time)

    data.lightDirection = dirDelta:ToEuler()
    data.lightIntensity = math.lerp(self.lightIntensity, target.lightIntensity, time)
    data.lightColor = self.lightColor:Lerp(target.lightColor, time)

    data.fogDensity = math.lerp(self.fogDensity, target.fogDensity, time)
    data.fogColor = self.fogColor:Lerp(target.fogColor, time)
    data.fogStart = math.lerp(self.fogStart, target.fogStart, time)
    data.fogEnd = math.lerp(self.fogEnd, target.fogEnd, time)


    data.snowAmount = math.lerp(self.snowAmount, target.snowAmount, time)
    data.windStrength = math.lerp(self.windStrength, target.windStrength, time)
    data.wetness = math.lerp(self.wetness, target.wetness, time)

    data.skyboxAlpha = time

    return data
end

--导出参数数据
function WeatherPreset:GetWeatherData()
    local data = {}

    data.lightDirection = self.lightDirection:Clone()
    data.lightIntensity = self.lightIntensity
    data.lightColor = self.lightColor:Clone()

    data.fogDensity = self.fogDensity
    data.fogColor = self.fogColor:Clone()
    data.fogStart = self.fogStart
    data.fogEnd = self.fogEnd

    data.snowAmount = self.snowAmount
    data.windStrength = self.windStrength
    data.wetness = self.wetness

    data.skyboxAlpha = 1
    
    return data
end

function WeatherPreset:SetWeatherData(data)
    self.lightDirection = data.lightDirection:Clone()
    self.lightIntensity = data.lightIntensity
    self.lightColor = data.lightColor:Clone()

    self.fogDensity = data.fogDensity
    self.fogColor = data.fogColor:Clone()
    self.fogStart = data.fogStart
    self.fogEnd = data.fogEnd

    self.snowAmount = data.snowAmount
    self.windStrength = data.windStrength
    self.wetness = data.wetness

    self.skyboxAlpha = data.skyboxAlpha

end

------------------------------------DataTable------------------------------------
--加载配置
function WeatherPreset:LoadConfig(config)
    self.weatherType = config.weatherType
    self.weatherIntensity = config.weatherIntensity
    self.weatherDuration = config.weatherDuration

    self.lightDirection = Vec3.New(config.lightDirection[1], config.lightDirection[2], config.lightDirection[3])
    self.lightIntensity = config.lightIntensity
    self.lightColor = Color.New(config.lightColor[1] / 255, config.lightColor[2] / 255, config.lightColor[3] / 255, config.lightColor[4] / 255)

    self.fogDensity = config.fogDensity
    self.fogColor = Color.New(config.fogColor[1] / 255, config.fogColor[2] / 255, config.fogColor[3] / 255, config.fogColor[4] / 255)
    self.fogStart = config.fogStart
    self.fogEnd = config.fogEnd

    self.effect = config.effect

    self.snowAmount = config.snowAmount
    self.windStrength = config.windStrength
    self.wetness = config.wetness

    self.skybox = config.skybox
    self.skyboxAlpha = config.skyboxAlpha
end

--从tid加载数据
function WeatherPreset:LoadConfigFromTid(tid)
    self.tid = tid
    self.name = tid
    config = DataProviderManager:GetData("Weather",tid)
    if config == nil then
        Log:Error("WeatherPreset:LoadConfigFromTid failed, tid = %s",tostring(tid))
        return
    end
    self:LoadConfig(config)
end


return WeatherPreset