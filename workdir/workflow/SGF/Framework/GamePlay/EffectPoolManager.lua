--特效节点池

local EffectPoolManager = {
    _EffectId=0,
    _EffectMap = {},
}

local effectNode = {
    node = nil,
    bFree = true, 
    id = nil,
}

-- 播放类型，循环和单次播放的节点分开缓存，防止播放异常
local NodeStatus = {
    Init = 0,
    Once = 1,
    Loop = 2
}

local initCount = 30 --初始化n个
EffectPoolManager.EffectNodeName = 'EFFECT_COMMON_NODE'

----------------------接口--------------------------
--获取空闲节点
function EffectPoolManager:GetFreeEffect(isLoop)
    local nStatus = isLoop and NodeStatus.Loop or NodeStatus.Once
    local _effect
    for k, v in pairs(self._EffectMap) do
        if v.bFree and (v.status == nStatus or v.status == NodeStatus.Init) then --节点空虚且匹配当前播放类型
            _effect = v
            break
        end
    end
    if not _effect then
        _effect = self:_New()
    end
    _effect.bFree = false
    _effect.status = nStatus
    return _effect.id, _effect.node
end

--归还节点
function EffectPoolManager:Release(id)
    for k, v in pairs(self._EffectMap) do
        if v.id == id then
            self:Stop(v.id)
            v.bFree = true
            v.node.Looping = false
            v.node.Enabled = false
            --v.node.Parent = nil --通过lua持有,确保不释放
            v.node.AssetID = ""
            v.node.LocalPosition = Vector3.New(0, 0, 0) 
            v.node.LocalScale = Vector3.New(1.0, 1.0, 1.0)
            v.node.LocalEuler = Vector3.New(0, 0, 0)
            return
        end
    end
end

--清空所有节点
function EffectPoolManager:Clear()
    for k, v in pairs(self._EffectMap) do
        self:_Destroy(k)
    end
    self._EffectMap = {}
    self._EffectId = 0
end

--节点转ID
function EffectPoolManager:GetIdByNode(node)
    if not node then
        return
    end
    for k, v in pairs(self._EffectMap) do
        if v.node == node then
            return v.id
        end
    end
end

--ID转节点
function EffectPoolManager:GetNodeById(id)
    local node = self._EffectMap[id] and self._EffectMap[id].node
    if not node then
        --ERR('未找到指定ID的特效节点', id)
        return
    end
    return node
end

--设置父节点
function EffectPoolManager:SetParent(id, parent, pos)
    local node = self:GetNodeById(id)
    if node then
        node.Parent = parent
        pos = pos or Vector3.New(0, 0, 0) 
        node.LocalPosition = pos
        node.LocalScale = Vector3.New(1.0, 1.0, 1.0)
        node.LocalEuler = Vector3.New(0, 0, 0)
    end
end

--设置prefab. path=完全由使用者传入
function EffectPoolManager:SetPrefab(id, path, callback)
    local node = self:GetNodeById(id)
    if node and path ~= nil then 
        local assetID = MS.Utils.Resources:GetVFXID(path)
        node:SetAssetID(assetID, callback)
        --print("设置资源ID  == ".. assetID)
    end
end

--设置同步 syncFlag = Enum.NodeSyncLocalFlag.X
function EffectPoolManager:SetSync(id, syncFlag)
    local node = self:GetNodeById(id)
    node.LocalSyncFlag = syncFlag
end

--播放. bLoop = 是否循环. 如果loop=false, 播放结束后会回收特效node
--由于部分特效因为延迟加载或者循环播放导致的无法释放, 强制使用定时器进行回收node, 如果bForever=true, 则不会回收
function EffectPoolManager:Start(id, bLoop, bForever)
    local node = self:GetNodeById(id)
    if node then 
        node.Enabled = true
        node.Looping = bForever and true or bLoop
        node:Start()
        if bForever then
            return
        end
        if not bLoop then
            local listener = nil
            listener = node.StopPlaying:connect(function()
                self:Release(id)
                listener:disconnect()
                listener = nil
            end)
        else
            MS.Timer:Launch({OnBeat = function()
                self:Release(id)
            end}, MS.TimerID.EffectTimer, 3, 1, 1, EffectPoolManager) 
        end
    end
end

--暂停
function EffectPoolManager:Pause(id)
    local node = self:GetNodeById(id)
    if node then node:Pause() end
end

--停止
function EffectPoolManager:Stop(id)
    local node = self:GetNodeById(id)
    if node then node:Stop(0) end 
end

--重播. bLoop = 是否循环. 如果loop=false,播放结束后会回收特效node
--由于部分特效因为延迟加载或者循环播放导致的无法释放, 强制使用定时器进行回收node, 如果bForever=true, 则不会回收, 需要使用者自行管理回收
function EffectPoolManager:ReStart(id, bLoop, bForever)
    -- print('ttttttttttttttt ReStart...开始播放特效 ')
    local node = self:GetNodeById(id)
    if node then
        bLoop = bLoop or false
        bForever = bForever or false
        node.Enabled = true
        node.Looping = bForever and true or bLoop
        node:ReStart()
        if bForever then
            return
        end
        if not bLoop then
            local listener = nil
            listener = node.StopPlaying:connect(function()
                -- print("ttttttttttttttt StopPlaying.....特效播放结束,回收特效节点")
                self:Release(id)
                listener:disconnect()
                listener = nil
            end)
        else
            MS.Timer:Launch({OnBeat = function()
                self:Release(id)
            end}, MS.TimerID.EffectTimer, 3, 1, 1, EffectPoolManager) 
        end
    end
end

------------------------内部-----------------------
--创建节点
function EffectPoolManager:_New()
    local effect = MS.Utils.table.DeepCopy(effectNode)
    effect.node = SandboxNode.New("EffectObject")
    effect.node.Name = self.EffectNodeName
    effect.node.Looping = false
    effect.node.LocalPosition = Vector3.New(0, 0, 0) 
    effect.node.LocalScale = Vector3.New(1.0, 1.0, 1.0)
    effect.node.LocalEuler = Vector3.New(0, 0, 0)
    effect.node.LocalSyncFlag = Enum.NodeSyncLocalFlag.DISABLE --默认关闭特效同步
    effect.node.ResourceLoadMode = Enum.ResourceLoadMode.Default --默认为Dynamic动态加载
    effect.id = self:_GenerateEffectId()
    effect.bFree = true
    effect.status = NodeStatus.Init
    self._EffectMap[effect.id] = effect
    return effect
end

--销毁节点
function EffectPoolManager:_Destroy(key)
    local effect = self._EffectMap[key]
    if not effect then
        return
    end
    self:Stop(effect.id)
    effect.node.Parent = nil
    self._EffectMap[key] = nil
end

--effect id generator
function EffectPoolManager:_GenerateEffectId()
	self._EffectId = self._EffectId + 1
	return self._EffectId
end

for i = 1, initCount do
    EffectPoolManager:_New()
end

return EffectPoolManager