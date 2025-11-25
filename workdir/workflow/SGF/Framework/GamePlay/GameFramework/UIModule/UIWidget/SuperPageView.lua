-- 说明:分页控件
-- 日期:2025年2月26日
-- 支持:郝文丽
-- 版权声明 (c) 2025 迷你创想. All rights reserved.
local UIClass = GFScript("UIModule.UIClass")
local UIUtils = GFScript("UIModule.UIUtils")
local UILog = GFScript("UIModule.UILog")
local SuperGridView = GFScript("UIModule.UIWidget.SuperGridView")

local SuperPageView = UIClass.New("SuperPageView", SuperGridView)

function SuperPageView:Constructor()
    self.layoutDirection = "Horizontal"
    self.allowOutOfBoundary = true
    
    -- 分页相关属性
    self.currentPage = 1  -- 当前页码
    self.totalPages = 1   -- 总页数
    self.pageSize = 1     -- 每页显示数量
    self.pageIndicator = nil  -- 页面指示器
    self.autoScrollEnabled = false  -- 是否启用自动滚动
    self.autoScrollInterval = 3.0   -- 自动滚动间隔(秒)
    self.autoScrollTimer = 0        -- 自动滚动计时器
    self.pageChangeCallback = nil   -- 页面切换回调
    self.pageIndicatorTemplate = nil  -- 页面指示器模板
    self.pageIndicators = {}        -- 页面指示器列表
end

--[[
    设置每页显示数量
    @param size: 每页显示数量
]]
function SuperPageView:SetPageSize(size)
    if size <= 0 then
        UILog:Warn("SetPageSize: Invalid page size")
        return
    end
    self.pageSize = size
    self:UpdateTotalPages()
    self:ForceUpdate()
end

--[[
    更新总页数
]]
function SuperPageView:UpdateTotalPages()
    if #self.dataList == 0 then
        self.totalPages = 1
    else
        self.totalPages = math.ceil(#self.dataList / self.pageSize)
    end
    self:UpdatePageIndicator()
end

--[[
    设置页面指示器模板
    @param template: 指示器模板节点
]]
function SuperPageView:SetPageIndicatorTemplate(template)
    self.pageIndicatorTemplate = template
    if template then
        template.Visible = false
    end
    self:UpdatePageIndicator()
end

--[[
    更新页面指示器
]]
function SuperPageView:UpdatePageIndicator()
    if not self.pageIndicatorTemplate then
        return
    end
    
    -- 清理旧的指示器
    for _, indicator in ipairs(self.pageIndicators) do
        indicator:Destroy()
    end
    self.pageIndicators = {}
    
    -- 创建新的指示器
    for i = 1, self.totalPages do
        local indicator = self.pageIndicatorTemplate:Clone()
        indicator.Name = "PageIndicator" .. i
        indicator.Visible = true
        indicator.Parent = self.bindObj
        table.insert(self.pageIndicators, indicator)
    end
    
    -- 更新指示器状态
    self:UpdateIndicatorState()
end

--[[
    更新指示器状态
]]
function SuperPageView:UpdateIndicatorState()
    for i, indicator in ipairs(self.pageIndicators) do
        if i == self.currentPage then
            -- 当前页指示器高亮
            indicator.Color = Color.New(1, 1, 1, 1)
        else
            -- 其他页指示器暗淡
            indicator.Color = Color.New(0.5, 0.5, 0.5, 0.5)
        end
    end
end

--[[
    设置当前页
    @param page: 页码
    @param animated: 是否使用动画
]]
function SuperPageView:SetCurrentPage(page, animated)
    if page < 1 or page > self.totalPages then
        UILog:Warn("SetCurrentPage: Invalid page number")
        return
    end
    
    self.currentPage = page
    self:UpdateIndicatorState()
    
    -- 计算目标位置
    local targetIndex = (page - 1) * self.pageSize + 1
    self:ScrollToItem(targetIndex, animated, "Start")
    
    -- 触发回调
    if self.pageChangeCallback then
        self.pageChangeCallback(self, page)
    end
end

--[[
    获取当前页
    @return: 当前页码
]]
function SuperPageView:GetCurrentPage()
    return self.currentPage
end

--[[
    获取总页数
    @return: 总页数
]]
function SuperPageView:GetTotalPages()
    return self.totalPages
end

--[[
    设置页面切换回调
    @param callback: 回调函数
]]
function SuperPageView:SetPageChangeCallback(callback)
    self.pageChangeCallback = callback
end

--[[
    设置自动滚动
    @param enabled: 是否启用
    @param interval: 滚动间隔(秒)
]]
function SuperPageView:SetAutoScroll(enabled, interval)
    self.autoScrollEnabled = enabled
    if interval then
        self.autoScrollInterval = interval
    end
    self.autoScrollTimer = 0
end

--[[
    更新方法
    @param deltaTime: 帧间隔时间
]]
function SuperPageView:Update(deltaTime)
    SuperPageView.super.Update(self, deltaTime)
    
    -- 处理自动滚动
    if self.autoScrollEnabled and self.totalPages > 1 then
        self.autoScrollTimer = self.autoScrollTimer + deltaTime
        if self.autoScrollTimer >= self.autoScrollInterval then
            self.autoScrollTimer = 0
            local nextPage = self.currentPage + 1
            if nextPage > self.totalPages then
                nextPage = 1
            end
            self:SetCurrentPage(nextPage, true)
        end
    end
end

--[[
    设置数据列表
    @param dataList: 数据列表
    @param dataKey: 数据键
]]
function SuperPageView:SetDataList(dataList, dataKey)
    SuperPageView.super.SetDataList(self, dataList, dataKey)
    self:UpdateTotalPages()
    self:SetCurrentPage(1, false)
end

--[[
    滚动到指定索引的item
    @param index: 目标索引
    @param animated: 是否启用动画
    @param alignment: 对齐方式
]]
function SuperPageView:ScrollToItem(index, animated, alignment)
    SuperPageView.super.ScrollToItem(self, index, animated, alignment)
    
    -- 更新当前页
    local newPage = math.ceil(index / self.pageSize)
    if newPage ~= self.currentPage then
        self.currentPage = newPage
        self:UpdateIndicatorState()
        if self.pageChangeCallback then
            self.pageChangeCallback(self, newPage)
        end
    end
end

return SuperPageView

