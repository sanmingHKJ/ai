local Class = GFScript("CoreModule.Class")
local ActorManager = GFScript("ActorModule.ActorManager")
local ActorComponent = GFScript("ActorModule.ActorComponent")
local TargetUtils = GFScript("CombatModule.TargetUtils")

local HateComponent = Class.New("HateComponent", ActorComponent)

--构造函数
function HateComponent:Constructor(owner)
    self.updateEnabled = true
    self.hateList = {}
    self.hateDirty = false
end

--初始化
function HateComponent:Init()
    HateComponent.super.Init(self)
end
--更新服务端
function HateComponent:UpdateServer()

    --移除无效的仇恨
    for i = #self.hateList, 1, -1 do
        local hate = self.hateList[i]
        if hate.target.__delete__ or hate.target:IsDead() or 
            hate.target:IsShadow() or 
            hate.target:IsStealth() or 
            hate.target:GetSceneId() ~= self.actor:GetSceneId() then
            table.remove(self.hateList, i)
            self.hateDirty = true
        end
    end

    if self.hateDirty then
        --进行仇恨排序
        table.sort(self.hateList, function(a, b)
            return a.value > b.value
        end)

        local topHateTarget = self:GetTopHateTarget()
        if topHateTarget ~= nil then
            self.actor:ServerSetTarget(topHateTarget)
            --进入战斗
            self.actor:ServerEnterCombat()
        else
            self.actor:ServerSetTarget(nil)
            --离开战斗
            self.actor:ServerLeaveCombat()
        end

        self.hateDirty = false
    end
end

--添加仇恨
function HateComponent:ServerAddHate(target, value)
    if target == nil then
        return
    end

    --给随从添加仇恨
    self.actor:ForEachServants(function(servant)
        if servant.HateComponent then
            servant.HateComponent:ServerAddHate(target, value)
        end
    end)

    self.hateDirty = true
    for i = 1, #self.hateList do
        local hate = self.hateList[i]
        if hate.target == target then
            hate.value = hate.value + value
            return
        end
    end
    table.insert(self.hateList,{target = target, value = value})
end

--获取仇恨
function HateComponent:GetHate(target)
    if target == nil then
        return 0
    end
    for i = 1, #self.hateList do
        local hate = self.hateList[i]
        if hate.target == target then
            return hate.value
        end
    end
    return 0
end

--清空仇恨
function HateComponent:ServerClearHate()
    self.hateList = {}
    self.hateDirty = false
end

--根据索引获取仇恨目标
function HateComponent:GetHateTarget(index)
    if index < 1 or index > #self.hateList then
        return nil
    end
    return self.hateList[index].target
end

--获取顶部仇恨目标
function HateComponent:GetTopHateTarget()
    if #self.hateList == 0 then
        return nil
    end
    return self.hateList[1].target
end

return HateComponent