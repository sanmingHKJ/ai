print("Setting")

local Setting = game:GetService("Setting")

local lowConfigs = [[{
	"m_eGraphicsQuality":0,               //获取配置档位（0、1、2）（低、中、高）
    "m_eRealTimeShadows":0,               //实时阴影（0关1开）
    "m_ShadowCfg":{                       //阴影级别
        "m_nDistance":0,
        "m_eShadowResolutionLevel":0,
        "m_nCascadeLevel":0
    },
    "m_eWaterReflection":0,               //水面反射（0关1开）
    "m_eWaterSurfaceCaustics":0,          //水面焦散（0关1开）
    "m_eFogEffect":0,                     //雾效（0、1、2、4、8）
    "m_eDynamicSkyLevel":0,               //动态天空（0、1、2）（低、中、高）
    "m_eDynamicVegetation":0,             //动态植被（0关1开）
    "m_eVolumetricLights":0,              //体积光（0关1开）
    "m_eAntiAliasing":0,                  //抗锯齿（0关1开）
    "m_eLutFilter":0,                     //LUT滤镜（0关1开）
    "m_eBloom":0,                         //Bloom（0关1开）
    "m_bHDR":false,                       //HDR（false关true开）
    "m_eDepthOfField":0,                  //景深（0关1开）
    "m_bSSAO":false,                      //SSAO（false关true开）
    "m_eTextureQuality":0,                //贴图质量（0、1、2）（低、中、高）
    "m_eModelQuality":0,                  //模型质量（0、1、2）（低、中、高）
    "m_eEffectQuality":0,                 //特效质量（0、1、2）（低、中、高）
    "m_eMaterialQuality":0,               //材质质量（0、1、2）（低、中、高）
    "m_eResolutionLevel":0,               //分辨率等级（0、1、2）（低、中、高）
    "m_nLimitFrameRate":30,               //帧率限制（30、60、120）（低、中、高）
    "m_eVisionLevel":1,                   // 视野(0近，1中，2远，3更远，4最远)
    "m_nDesign":320,                      //分辨率
}]]

local mediumConfigs = [[{
    "m_eGraphicsQuality":1,               //获取配置档位（0、1、2）（低、中、高）
    "m_eRealTimeShadows":1,               //实时阴影（0关1开）
    "m_ShadowCfg":{                       //阴影级别
        "m_nDistance":4000,
        "m_eShadowResolutionLevel":1,
        "m_nCascadeLevel":0
    },
    "m_eWaterReflection":0,               //水面反射（0关1开）
    "m_eWaterSurfaceCaustics":0,          //水面焦散（0关1开）
    "m_eFogEffect":1,                     //雾效（0、1、2、4、8）
    "m_eDynamicSkyLevel":0,               //动态天空（0、1、2）（低、中、高）
    "m_eDynamicVegetation":0,             //动态植被（0关1开）
    "m_eVolumetricLights":0,              //体积光（0关1开）
    "m_eAntiAliasing":1,                  //抗锯齿（0关1开）
    "m_eLutFilter":0,                     //LUT滤镜（0关1开）
    "m_eBloom":1,                         //Bloom（0关1开）
    "m_bHDR":false,                       //HDR（false关true开）
    "m_eDepthOfField":0,                  //景深（0关1开）
    "m_bSSAO":false,                      //SSAO（false关true开）
    "m_eTextureQuality":1,                //贴图质量（0、1、2）（低、中、高）
    "m_eModelQuality":1,                  //模型质量（0、1、2）（低、中、高）
    "m_eEffectQuality":1,                 //特效质量（0、1、2）（低、中、高）
    "m_eMaterialQuality":0,               //材质质量（0、1、2）（低、中、高）
    "m_eResolutionLevel":1,               //分辨率等级（0、1、2）（低、中、高）
    "m_nLimitFrameRate":30,               //帧率限制（30、60、120）（低、中、高）
    "m_eVisionLevel":2,                   // 视野(0近，1中，2远，3更远，4最远)
    "m_nDesign":720,                      //分辨率
}]]

local highConfigs = [[{
    "m_eGraphicsQuality":2,              //获取配置档位（0、1、2）（低、中、高）
    "m_eRealTimeShadows":1,               //实时阴影（0关1开）
    "m_ShadowCfg":{                       //阴影级别
        "m_nDistance":7000,
        "m_eShadowResolutionLevel":2,
        "m_nCascadeLevel":4
    },
    "m_eWaterReflection":1,               //水面反射（0关1开）
    "m_eWaterSurfaceCaustics":0,          //水面焦散（0关1开）
    "m_eFogEffect":8,                     //雾效（0、1、2、4、8）
    "m_eDynamicSkyLevel":0,               //动态天空（0、1、2）（低、中、高）
    "m_eDynamicVegetation":0,             //动态植被（0关1开）
    "m_eVolumetricLights":1,              //体积光（0关1开）
    "m_eAntiAliasing":1,                  //抗锯齿（0关1开）
    "m_eLutFilter":1,                     //LUT滤镜（0关1开）
    "m_eBloom":1,                         //Bloom（0关1开）
    "m_bHDR":true,                       //HDR（false关true开）
    "m_eDepthOfField":0,                  //景深（0关1开）
    "m_bSSAO":false,                      //SSAO（false关true开）
    "m_eTextureQuality":2,                //贴图质量（0、1、2）（低、中、高）
    "m_eModelQuality":2,                  //模型质量（0、1、2）（低、中、高）
    "m_eEffectQuality":2,                 //特效质量（0、1、2）（低、中、高）
    "m_eMaterialQuality":2,               //材质质量（0、1、2）（低、中、高）
    "m_eResolutionLevel":2,               //分辨率等级（0、1、2）（低、中、高）
    "m_nLimitFrameRate":60,               //帧率限制（30、60、120）（低、中、高）
    "m_eVisionLevel":4,                   // 视野(0近，1中，2远，3更远，4最远)
    "m_nDesign":720,                     //分辨率
}]]

local function loadConfigs( graphicsQuality )
    --这个看项目需求自己判断
    local CUR_PLATFORM = game.WorkSpace.Environment:GetDeviceType()
    if CUR_PLATFORM == Enum.EnumDeviceType.WIN then
        return
    end

    --获取档位
    print("begin loadConfigs, graphicsQuality=" .. graphicsQuality)

    local configs = nil
    if graphicsQuality == 0 then
        configs = lowConfigs
    elseif graphicsQuality == 1 then
        configs = mediumConfigs
    elseif graphicsQuality == 2 then
        configs = highConfigs
    end

    if not configs then
        return
    end

    Setting:LoadMapCustomGameConfigJsonStr(configs)

    print("end loadConfigs, graphicsQuality=" .. graphicsQuality)
end


--加载默认的地图配置是否成功,没有成功就加载默认的档位配置，成功就代表读取的是上次保存的地图配置
Setting.LoadMapCustomSuccess:Connect(function(isSuccess)
    if not isSuccess then
        local graphicsQuality = Setting.GraphicsQuality
        loadConfigs(graphicsQuality)
    end

    --这个看项目需求自己判断
    local CUR_PLATFORM = game.WorkSpace.Environment:GetDeviceType()
    if CUR_PLATFORM == Enum.EnumDeviceType.WIN then
        Setting:RestoreDesign()
    end
end)

--切换档位的通知
Setting.GraphicsQualityUpdate:Connect(function(oldGraphicsQuality, newGraphicsQuality)
    --这个看项目需求自己判断是否加载默认的档位配置
    loadConfigs(newGraphicsQuality)
end)


