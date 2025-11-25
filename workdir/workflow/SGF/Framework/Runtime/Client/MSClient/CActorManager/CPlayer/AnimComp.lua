-- 动画组件
local animComp = {}

function animComp.New(animatorLoadedCallback)
    local o = {}
    setmetatable(o, {__index = animComp})

    o:Init(animatorLoadedCallback)

    return o
end

function animComp:Init(animatorLoadedCallback)
    self.animator = nil

    self.animatorLoadedCallback = animatorLoadedCallback
end

function animComp:SetActor(actor, isLoadFinish)
    self.actor = actor
    if self.actor then
		self.animator = self.actor:GetAnimator()
		self.animator.IsReplication = true

		if isLoadFinish then
			self.animatorLoadedCallback('', true)
		else
			-- 状态机资源加载完成通知(UpdateAssetNotify不一定会执行,如果执行脚本之前已经加载完成则不会收到通知)
			self.animator.UpdateAssetNotify:connect(function(url, state)
				if self.animatorLoadedCallback then
					self.animatorLoadedCallback(url, state)
				end
			end)
		end
    end
end

function animComp:GetAnimator()
	if not self.animator then
		LOG(err, "AnimComp::animator is nil...")
	end
	return self.animator
end

function animComp:GetState(stateName, layerIdx, layerName)
	if self.animator then
		layerIdx = layerIdx or MS.Const.PlayerStateKey.BaseLayerInt
		layerName = layerName or MS.Const.PlayerStateKey.BaseLayer
		local layer = self.animator.controller:GetStateMachine(layerIdx)
    	local state = layer:GetState(layerName.. '.' .. stateName)
		return state
	end
	return nil
end

-- 设置Trigger
function animComp:SetTrigger(name)
	if self.animator then
		self.animator:SetTrigger(name, true)
	end
end

function animComp:SetBool(key, value)
	if self.animator then
		self.animator:SetBool(key, value)
	end
end

function animComp:SetInt(key, value)
	if self.animator then
		self.animator:SetInt(key, value)
	end
end

function animComp:SetFloat(key, value)
	if self.animator then
		self.animator:SetFloat(key, value)
	end
end

-- normalized:标准化开始的offset
function animComp:Play(name, layer, normalized)
    if self.animator then
        layer = layer or MS.Const.PlayerStateKey.BaseLayerInt
        normalized = normalized or 0
		self.animator:Play(name, layer, normalized)
	end
end

-- 渐变动画：淡入淡出
function animComp:CrossFade(stateName, layer, transitionTotal, transitionOffset)
    if self.animator then
		layer = layer or MS.Const.PlayerStateKey.BaseLayerInt
		transitionTotal = transitionTotal or 0.1
		transitionOffset = transitionOffset or 0 -- 此参数引擎目前没支持。所以不生效 2024.1.2
		self.animator:CrossFade(stateName, layer, transitionTotal, transitionOffset)
	end
end

-- 设置动画控制器资源
function animComp:SetControllerAsset(node)
    if self.animator then
		self.animator:SetControllerAsset(node)
	end
end

-- 更新动画控制器资源
function animComp:UpdateControllerAsset(assetResType, url)
    if self.animator then
		self.animator:UpdateControllerAsset(assetResType, url)
	end
end

-- 获取layer层级权重
function animComp:GetLayerWeight(layer)
	if self.animator then
		return self.animator:GetLayerWeight(layer)
	end
end

-- 设置layer层级权重[0,1]
function animComp:SetLayerWeight(layer, weight)
	if self.animator then
		self.animator:SetLayerWeight(layer, weight)
	end
end

return animComp