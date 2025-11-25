--天气配置范例
local WeatherConfig = {
    name = "Weather_3001_Evening",
    weatherType = "WeatherType_3001_Evening",
    weatherIntensity = 1,
    weatherDuration = 10,

    lightDirection = {50,-85,-160},
    lightIntensity = 0.95,
    lightColor = {166, 206, 225, 1},

    fogDensity = 1,
    fogColor = {141, 180, 198, 255},
    fogStart = 6000,
    fogEnd = 16000,

    effect = "Effect_1",

    snowAmount = 1,
    windStrength = 1,
    wetness = 1,

    skybox = "Assets.Skybox.FK_3001_SkyBoxSphere_evening",
    skyboxAlpha = 1,
}

return WeatherConfig