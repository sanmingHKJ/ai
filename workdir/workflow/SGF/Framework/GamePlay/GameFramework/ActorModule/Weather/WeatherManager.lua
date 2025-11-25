local Class = GFScript("CoreModule.Class")
local Utils = GFScript("CoreModule.Utils")
local Log = GFScript("CoreModule.Log")
local TimerManager = GFScript("CoreModule.TimerManager")
local WeatherPreset = GFScript("ActorModule.Weather.WeatherPreset")
local MaterialService = game:GetService("MaterialService")
local Json = GFScript("CoreModule.Json")

local WeatherManager = {}

WeatherManager.weatherList = {}

--初始化
function WeatherManager:Init()
    --天气列表
    self.weatherList = {}

    self.currentWeather = nil
    self.targetWeather = nil
    self.transitionTime = 0
    self.currentTransitionTime = 0
    self.isTransitioning = false

    self.backgroundSkybox = nil
    self.foregroundSkybox = nil

    self.dirty = true

    -- self:SwitchWeather("Weather_1", 5)
    -- self:SwitchWeather("Weather_2", 5)

    -- self:SwitchWeather("Weather_1", 10)
    -- self:SwitchWeather("Weather_2", 10)

    
    -- TimerManager:DelayCall(function()
    --     self:SwitchWeather("Weather_1", 10)
    -- end, 15)
end

--删除默认的天空盒
function WeatherManager:DeleteDefaultSkybox()
    local Workspace = game:GetService("Workspace")
    local defaultSkybox = Workspace.Skybox
    if defaultSkybox then
        defaultSkybox:Destroy()
    end
end

--创建天空盒
function WeatherManager:CreateSkybox(weatherPreset, opacity)
    local Workspace = game:GetService("Workspace")
    local skybox = Utils:GetMainStorageNode(weatherPreset.skybox)
    if skybox then
        local newSkybox = skybox:Clone()
        newSkybox.Parent = Workspace

        newSkybox.LoadFinish:connect(function(suc)
            local mat = newSkybox:GetMaterialInstance({}, 0)
        
            if mat == nil then
                Log:Error("WeatherManager:CreateSkybox failed, mat is nil")
                newSkybox:Destroy()
                return nil
            end
        
            mat:SetR32("_Opaque", opacity)
        end)
        return newSkybox
    end
    return nil
end

--切换天气
function WeatherManager:SwitchWeather(weatherName, transitionDuration)
    Log:Info("@@@@@@@@@@@@@@ WeatherManager:SwitchWeather %s", weatherName)
    self:DeleteDefaultSkybox()
    local targetWeather = self.weatherList[weatherName]
    if not targetWeather then
        Log:Error("WeatherManager:SwitchWeather failed, weather not found: %s", tostring(weatherName))
        return
    end

    -- 如果目标天气与当前正在过渡的目标天气相同，则不需要重新切换
    if self.isTransitioning and self.targetWeather == targetWeather then
        return
    end

    if self.currentWeather == nil then
        self.currentWeather = targetWeather
        self.weatherData = targetWeather:GetWeatherData()
        if self.foregroundSkybox then
            self.foregroundSkybox:Destroy()
        end
        self.foregroundSkybox = self:CreateSkybox(targetWeather, 1.0)
        if self.foregroundSkybox then
            self.foregroundSkybox.Name = "ForegroundSkybox"
        end

        self.currentWeather.skyboxAlpha = 1
        self.dirty = true
        return
    end

    -- 如果正在过渡中，则以当前状态作为新的起始点
    if self.isTransitioning then
        local currentAlpha = self.weatherData.skyboxAlpha
        
        self.currentWeather = WeatherPreset.New()
        self.currentWeather:SetWeatherData(self.weatherData)
        
        if self.foregroundSkybox then
            self.foregroundSkybox:Destroy()
        end
        self.foregroundSkybox = self.backgroundSkybox
        self.backgroundSkybox = nil
        
        -- 创建新的背景天空盒，使用当前的alpha值
        self.backgroundSkybox = self:CreateSkybox(targetWeather, currentAlpha)
        
        -- 确保前景和背景天空盒的alpha值正确
        if self.foregroundSkybox then
            local foregroundMat = self.foregroundSkybox:GetMaterialInstance({}, 0)
            if foregroundMat then
                foregroundMat:SetR32("_Opaque", 1 - currentAlpha)
            end
        end
        
        if self.backgroundSkybox then
            local backgroundMat = self.backgroundSkybox:GetMaterialInstance({}, 0)
            if backgroundMat then
                backgroundMat:SetR32("_Opaque", currentAlpha)
            end
        end
    else
        -- 非过渡状态下的首次创建
        self.backgroundSkybox = self:CreateSkybox(targetWeather, 0.0)
    end

    self.targetWeather = targetWeather
    self.transitionTime = transitionDuration or 0
    self.currentTransitionTime = 0
    self.isTransitioning = true
    
    self.dirty = true
end

--获取天气
function WeatherManager:GetWeather(weatherName)
    return self.weatherList[weatherName]
end

--添加天气
function WeatherManager:AddWeatherByTid(tid)
    local weatherPreset = WeatherPreset.New()
    weatherPreset:LoadConfigFromTid(tid)
    self:AddWeather(weatherPreset.name, weatherPreset)
end

--添加天气
function WeatherManager:AddWeather(weatherName, weather)
    self.weatherList[weatherName] = weather
end

--移除天气
function WeatherManager:RemoveWeather(weatherName)
    self.weatherList[weatherName] = nil
end

--获取天气列表
function WeatherManager:GetWeatherList()
    return self.weatherList
end


--更新
function WeatherManager:Update(dt)
    if self.isTransitioning then
        self.currentTransitionTime = self.currentTransitionTime + dt
        local t = math.min(1, self.currentTransitionTime / self.transitionTime)
        
        self.weatherData = self.currentWeather:Lerp(self.targetWeather, t)

        if self.currentTransitionTime >= self.transitionTime then
            self.isTransitioning = false
            self.currentWeather = self.targetWeather
            self.targetWeather = nil
            self.weatherData = self.currentWeather:GetWeatherData()
        end

        self.dirty = true
    end

    if self.dirty then
        self:UpdateDirectionalLight()
        self:UpdateFog()
        self:UpdateGlobalShaderParams()
        self:UpdateSkybox()
        self:UpdateEffect()
        --self:PrintWeatherData()
        self.dirty = false
    end
end 

function WeatherManager:WeatherDataToString()
    return Json.encode(self.weatherData)
end

function WeatherManager:PrintWeatherData()
    Log:Info("WeatherManager:PrintWeatherData " .. self:WeatherDataToString())
end

--更新方向光
function WeatherManager:UpdateDirectionalLight()
    if self.weatherData == nil then
        return
    end

    local Workspace = game:GetService("Workspace")
    if Workspace.Environment == nil then
        return
    end
    local SunLight = Workspace.Environment.SunLight

    if SunLight == nil then
        return
    end
    SunLight.LocalSyncFlag = Enum.NodeSyncLocalFlag.NO_SEND

    SunLight.Euler = Vector3.New(self.weatherData.lightDirection.x, self.weatherData.lightDirection.y, self.weatherData.lightDirection.z)
    SunLight.Intensity = self.weatherData.lightIntensity
    SunLight.Color = ColorQuad.New(self.weatherData.lightColor.r * 255, 
        self.weatherData.lightColor.g * 255, 
        self.weatherData.lightColor.b * 255, 
        self.weatherData.lightColor.a * 255)

end

--更新雾
function WeatherManager:UpdateFog()
    if self.weatherData == nil then
        return
    end

    local Workspace = game:GetService("Workspace")
    if Workspace.Environment == nil then
        return
    end
    local Atmosphere = Workspace.Environment.Atmosphere
    
    if Atmosphere == nil then
        return
    end
    Atmosphere.LocalSyncFlag = Enum.NodeSyncLocalFlag.NO_SEND

    Atmosphere.FogStart = self.weatherData.fogStart
    Atmosphere.FogEnd = self.weatherData.fogEnd
    Atmosphere.FogColor = ColorQuad.New(self.weatherData.fogColor.r * 255, 
        self.weatherData.fogColor.g * 255, 
        self.weatherData.fogColor.b * 255, 
        self.weatherData.fogColor.a * 255)
end

--更新全局着色器参数
function WeatherManager:UpdateGlobalShaderParams()
    if self.weatherData == nil then
        return
    end
    MaterialService:SetGlobalFloat("gSnowAmount", self.weatherData.snowAmount)
    MaterialService:SetGlobalFloat("gWindStrength", self.weatherData.windStrength)
    MaterialService:SetGlobalFloat("gWetness", self.weatherData.wetness)

    -- MaterialService:SetGlobalVector("Weather_WindDirection", self.weatherData.windDirection)
end

--更新天空盒
function WeatherManager:UpdateSkybox()
    if self.weatherData == nil then
        return
    end

    if self.backgroundSkybox == nil then
        return
    end

    if self.foregroundSkybox == nil then
        return
    end
    local backgroundMat = self.backgroundSkybox:GetMaterialInstance({}, 0)
    local foregroundMat = self.foregroundSkybox:GetMaterialInstance({}, 0)

    if backgroundMat == nil or foregroundMat == nil then
        return
    end

    backgroundMat:SetR32("_Opaque", self.weatherData.skyboxAlpha)
    foregroundMat:SetR32("_Opaque", 1 - self.weatherData.skyboxAlpha)

    if self.weatherData.skyboxAlpha >= 1 then
        self.foregroundSkybox:Destroy()
        self.foregroundSkybox = nil

        self.foregroundSkybox = self.backgroundSkybox
        self.backgroundSkybox = nil
    end
end

--更新效果
function WeatherManager:UpdateEffect()
    if self.weatherData == nil then
        return
    end

end


return WeatherManager