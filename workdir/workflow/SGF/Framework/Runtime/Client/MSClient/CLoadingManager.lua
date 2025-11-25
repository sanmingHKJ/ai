local CLoadingManager = {}


local TimerManager = GFScript("CoreModule.TimerManager")

function CLoadingManager:Init()
    self.imgLoading = MS.Players.LocalPlayer.PlayerGui:WaitForChild("LoadingUIMain")
    self:InitLoading()
end

--初始化加载界面
function CLoadingManager:InitLoading()
    if MS.RunService:IsStudio() then
        return
    end

    if self.imgLoading then
        self.imgLoading.Visible = true

        -- 获取初始加载状态
        local allCount = MS.UtilService:GetHistoryLoadIndex()
        local alreadyLoadCount = MS.UtilService:GetHistoryLoadIndex() - MS.UtilService:GetCurrentLoadAssetIndex()
        print(allCount, alreadyLoadCount)
        -- 计算初始进度
        local initialProgress = 0
        if allCount > 0 then
            initialProgress = math.min(100, (alreadyLoadCount / allCount) * 100)
        end

        -- 设置初始UI状态
        if self.imgLoading.Loading and self.imgLoading.Loading.Progress and self.imgLoading.Loading.Progress.img then
            self.imgLoading.Loading.Progress.img.FillAmount = initialProgress / 100
        end

        if self.imgLoading.Loading and self.imgLoading.Loading.txtProgress then
            self.imgLoading.Loading.txtProgress.Title = string.format("%.0f%%", initialProgress)
        end

        -- 设置初始资源数量显示
        local initialTxtValue = string.format("资源:%d/%d", alreadyLoadCount, allCount)
        if self.imgLoading.Loading and self.imgLoading.Loading.txtValue then
            self.imgLoading.Loading.txtValue.Title = initialTxtValue
        end

        print(string.format("初始化加载界面 - 总资源数: %d, 已加载: %d, 初始进度: %.1f%%", allCount, alreadyLoadCount, initialProgress))

        -- 启动真实资源加载进度定时器
        self:StartLoadingProgress()
    end
end

-- 启动加载进度定时器
function CLoadingManager:StartLoadingProgress()
    local TimerManager = GFScript("CoreModule.TimerManager")
    local interval = 0.1 -- 每0.1秒更新一次
    local txtValue = "资源:0/0"
    -- 获取资源加载数据
    local allCount = MS.UtilService:GetHistoryLoadIndex()
    local alreadyLoadCount = MS.UtilService:GetHistoryLoadIndex() - MS.UtilService:GetCurrentLoadAssetIndex()

    print(string.format("开始加载进度 - 总资源数: %d, 已加载: %d", allCount, alreadyLoadCount))

    -- 容错机制参数
    local timeoutConfig = self:GetTimeoutConfig()
    local maxLoadingTime = timeoutConfig.maxLoadingTime
    local minProgressForTimeout = timeoutConfig.minProgressForTimeout
    local fastLoadingTime = timeoutConfig.fastLoadingTime
    local fastProgressForTimeout = timeoutConfig.fastProgressForTimeout
    local elapsedTime = 0 -- 已加载时间

    -- 创建进度更新定时器
    self.loadingTimer = TimerManager:AddTimer(function(dt)
        elapsedTime = elapsedTime + dt

        -- 实时获取当前加载状态
        local currentAllCount = MS.UtilService:GetHistoryLoadIndex()
        local currentAlreadyLoadCount = MS.UtilService:GetHistoryLoadIndex() - MS.UtilService:GetCurrentLoadAssetIndex()

        -- 计算当前进度 (0-100)
        local progress = 0
        if currentAllCount > 0 then
            progress = math.min(100, (currentAlreadyLoadCount / currentAllCount) * 100)
        end

        -- 更新UI显示
        if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.Progress and self.imgLoading.Loading.Progress.img then
            self.imgLoading.Loading.Progress.img.FillAmount = progress / 100
        end

        if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.txtProgress then
            self.imgLoading.Loading.txtProgress.Title = string.format("%.0f%%", progress)
        end

        -- 更新资源数量显示
        txtValue = string.format("资源:%d/%d", currentAlreadyLoadCount, currentAllCount)
        if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.txtValue then
            self.imgLoading.Loading.txtValue.Title = txtValue
        end

        -- 可选：在控制台显示详细进度信息（调试用）
        if progress % 10 < 0.1 then -- 每10%打印一次
            print(string.format("加载进度: %.1f%% (%d/%d) 时间: %.1fs", progress, currentAlreadyLoadCount, currentAllCount,
                elapsedTime))
        end

        -- 检查是否完成
        local isCompleted = false
        local completionReason = ""

        -- 情况1：所有资源都加载完成
        if currentAlreadyLoadCount >= currentAllCount and currentAllCount > 0 then
            isCompleted = true
            completionReason = "所有资源加载完成"
        end

        -- 情况2：快速容错机制 - 超过配置时间且进度超过配置进度（优先检查）
        if not isCompleted and elapsedTime >= fastLoadingTime and progress >= fastProgressForTimeout then
            isCompleted = true
            completionReason = string.format("快速容错机制触发 - 时间: %.1fs, 进度: %.1f%%", elapsedTime, progress)
        end

        -- 情况3：标准容错机制 - 超过配置时间且进度超过配置进度
        if not isCompleted and elapsedTime >= maxLoadingTime and progress >= minProgressForTimeout then
            isCompleted = true
            completionReason = string.format("标准容错机制触发 - 时间: %.1fs, 进度: %.1f%%", elapsedTime, progress)
        end

        if isCompleted then
            -- 确保进度为100%（如果是容错机制触发，显示实际进度）
            local finalProgress = completionReason:find("容错机制") and progress or 100

            if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.Progress and self.imgLoading.Loading.Progress.img then
                self.imgLoading.Loading.Progress.img.FillAmount = finalProgress / 100
            end

            if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.txtProgress then
                self.imgLoading.Loading.txtProgress.Title = string.format("%.0f%%", finalProgress)
            end

            -- 更新最终资源数量显示
            local finalTxtValue = string.format("资`源:%d/%d", currentAlreadyLoadCount, currentAllCount)
            if self.imgLoading and self.imgLoading.Loading and self.imgLoading.Loading.txtValue then
                self.imgLoading.Loading.txtValue.Title = finalTxtValue
            end

            print(string.format("加载完成 - %s - 总资源数: %d, 已加载: %d, 最终进度: %.1f%%",
                completionReason, currentAllCount, currentAlreadyLoadCount, finalProgress))

            -- 停止定时器
            if self.loadingTimer then
                TimerManager:RemoveTimer(self.loadingTimer)
                self.loadingTimer = nil
            end

            -- 加载完成后的回调
            self:OnLoadingComplete()
        end
    end, interval, 0) -- 0表示无限循环，直到手动停止
end

-- 加载完成回调
function CLoadingManager:OnLoadingComplete()
    print("加载完成！")
    -- 这里可以添加加载完成后的逻辑
    -- 比如隐藏加载界面、显示主界面等

    -- 示例：延迟1秒后隐藏加载界面
    local TimerManager = GFScript("CoreModule.TimerManager")
    TimerManager:DelayCall(function()
        local imgLoading = MS.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUIMain")
        if imgLoading then
            imgLoading.Visible = false
        end
    end, 1)
end

-- 设置容错机制参数
function CLoadingManager:SetTimeoutConfig(maxTime, minProgress, fastTime, fastProgress)
    self.timeoutConfig = {
        maxLoadingTime = maxTime or 30,             -- 默认30秒
        minProgressForTimeout = minProgress or 70,  -- 默认70%
        fastLoadingTime = fastTime or 10,           -- 快速容错时间，默认10秒
        fastProgressForTimeout = fastProgress or 95 -- 快速容错进度，默认95%
    }
    print(string.format("容错机制配置已更新 - 标准: %ds/%.0f%%, 快速: %ds/%.0f%%",
        self.timeoutConfig.maxLoadingTime, self.timeoutConfig.minProgressForTimeout,
        self.timeoutConfig.fastLoadingTime, self.timeoutConfig.fastProgressForTimeout))
end

-- 显示固定时间的Loading界面（供外部调用）
-- @param duration 显示时间（秒），默认3秒
-- @param customText 自定义文本，可选
function CLoadingManager:ShowFixedLoading(duration, customText)
    if MS.RunService:IsStudio() then
        return
    end

    duration = duration or 3 -- 默认3秒
    customText = customText or "加载中..."

    local imgLoading = MS.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUIMain")
    if not imgLoading then
        print("Loading界面不存在")
        return
    end

    -- 停止之前的loading定时器（如果有）
    self:StopFixedLoading()

    -- 显示界面
    imgLoading.Visible = true

    -- 设置初始状态
    if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
        imgLoading.Loading.Progress.img.FillAmount = 0
    end

    if imgLoading.Loading and imgLoading.Loading.txtProgress then
        imgLoading.Loading.txtProgress.Title = "0%"
    end

    if imgLoading.Loading and imgLoading.Loading.txtValue then
        imgLoading.Loading.txtValue.Title = customText
    end

    print(string.format("显示固定Loading界面 - 持续时间: %ds, 文本: %s", duration, customText))

    -- 创建固定进度定时器
    local elapsedTime = 0
    local interval = 0.1 -- 每0.1秒更新一次

    self.fixedLoadingTimer = TimerManager:AddTimer(function(dt)
        elapsedTime = elapsedTime + dt

        -- 计算进度 (0-100)
        local progress = math.min(100, (elapsedTime / duration) * 100)

        -- 更新UI显示
        if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
            imgLoading.Loading.Progress.img.FillAmount = progress / 100
        end

        if imgLoading.Loading and imgLoading.Loading.txtProgress then
            imgLoading.Loading.txtProgress.Title = string.format("%.0f%%", progress)
        end

        -- 检查是否完成
        if elapsedTime >= duration then
            -- 确保进度为100%
            if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
                imgLoading.Loading.Progress.img.FillAmount = 1.0
            end

            if imgLoading.Loading and imgLoading.Loading.txtProgress then
                imgLoading.Loading.txtProgress.Title = "100%"
            end

            print(string.format("固定Loading完成 - 持续时间: %ds", duration))

            -- 停止定时器
            if self.fixedLoadingTimer then
                TimerManager:RemoveTimer(self.fixedLoadingTimer)
                self.fixedLoadingTimer = nil
            end

            -- 隐藏界面
            imgLoading.Visible = false
        end
    end, interval, 0)
end

-- 停止固定Loading界面
function CLoadingManager:StopFixedLoading()
    if self.fixedLoadingTimer then
        local TimerManager = GFScript("CoreModule.TimerManager")
        TimerManager:RemoveTimer(self.fixedLoadingTimer)
        self.fixedLoadingTimer = nil
        print("固定Loading已停止")
    end

    -- 隐藏界面
    local imgLoading = MS.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUIMain")
    if imgLoading then
        imgLoading.Visible = false
    end
end

-- 显示带回调的固定Loading界面
-- @param duration 显示时间（秒）
-- @param onComplete 完成回调函数
-- @param customText 自定义文本，可选
function CLoadingManager:ShowFixedLoadingWithCallback(duration, onComplete, customText)
    -- if MS.RunService:IsStudio() then
    --     return
    -- end

    duration = duration or 3
    customText = customText or "加载中..."

    local imgLoading = MS.Players.LocalPlayer.PlayerGui:FindFirstChild("LoadingUIMain")
    if not imgLoading then
        print("Loading界面不存在")
        if onComplete then
            onComplete()
        end
        return
    end

    -- 停止之前的loading定时器（如果有）
    self:StopFixedLoading()

    -- 显示界面
    imgLoading.Visible = true

    -- 设置初始状态
    if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
        imgLoading.Loading.Progress.img.FillAmount = 0
    end

    if imgLoading.Loading and imgLoading.Loading.txtProgress then
        imgLoading.Loading.txtProgress.Title = "0%"
    end

    if imgLoading.Loading and imgLoading.Loading.txtValue then
        imgLoading.Loading.txtValue.Title = customText
    end

    print(string.format("显示固定Loading界面(带回调) - 持续时间: %ds, 文本: %s", duration, customText))

    -- 创建固定进度定时器
    local elapsedTime = 0
    local interval = 0.1

    self.fixedLoadingTimer = TimerManager:AddTimer(function(dt)
        elapsedTime = elapsedTime + dt

        -- 计算进度 (0-100)
        local progress = math.min(100, (elapsedTime / duration) * 100)

        -- 更新UI显示
        if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
            imgLoading.Loading.Progress.img.FillAmount = progress / 100
        end

        if imgLoading.Loading and imgLoading.Loading.txtProgress then
            imgLoading.Loading.txtProgress.Title = string.format("%.0f%%", progress)
        end

        -- 检查是否完成
        if elapsedTime >= duration then
            -- 确保进度为100%
            if imgLoading.Loading and imgLoading.Loading.Progress and imgLoading.Loading.Progress.img then
                imgLoading.Loading.Progress.img.FillAmount = 1.0
            end

            if imgLoading.Loading and imgLoading.Loading.txtProgress then
                imgLoading.Loading.txtProgress.Title = "100%"
            end

            print(string.format("固定Loading完成(带回调) - 持续时间: %ds", duration))

            -- 停止定时器
            if self.fixedLoadingTimer then
                TimerManager:RemoveTimer(self.fixedLoadingTimer)
                self.fixedLoadingTimer = nil
            end

            -- 隐藏界面
            imgLoading.Visible = false

            -- 调用完成回调
            if onComplete then
                onComplete()
            end
        end
    end, interval, 0)
end

-- 获取容错机制配置
function CLoadingManager:GetTimeoutConfig()
    if not self.timeoutConfig then
        self:SetTimeoutConfig() -- 使用默认配置
    end
    return self.timeoutConfig
end

return CLoadingManager
