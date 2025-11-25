local SHerosManager = {}

function SHerosManager:Init()
    print("SHerosManager:Init")
    MS.NetworkHelper:RegisterNetObj(self)
    self:Regist()
end


function SHerosManager:Regist()
    --侦听回调函数
    self:OnRequest(MS.Protocol.ClientMSGID.SET_HERO_MODEL_REQ, function(userId, msgid, data)
        self:SetHeroModel(userId,data)  
    end)
end

function SHerosManager:SetHeroModel(userId,data)
    print("SHerosManager:SetHeroModel", data)
    self:CallClient(userId, MS.Protocol.ServerMSGID.SET_HERO_MODEL_RSP, data)
end



return SHerosManager