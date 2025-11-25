local TradeConfig = {}

-- 手续费率-百分比
TradeConfig.FeeRate = 5
-- 上架最大数量
TradeConfig.MaxCount = 10
-- 保证金率-百分比
TradeConfig.DepositRate = 3
-- 交易货币id
TradeConfig.CurrencyID = 1
-- 交易货币类型
TradeConfig.CurrencyType = "Currency"
-- 订单超时时间
TradeConfig.OutTime = 24 * 60 * 60

---------可售卖道具--key配各类型值----------------
local Mark = { key="Mark", name="收藏列表" }
local MarkTypes = {     }


local Firearm = { key="Firearm", name="枪械" }
local FirearmTypes = {
    { type="Firearm", subType="Rifle", name="步枪" },
    { type="Firearm", subType="SMG", name="冲锋枪" },
    { type="Firearm", subType="Sniper", name="狙击枪" },
    { type="Firearm", subType="Shotgun", name="霰弹枪" },
    { type="Firearm", subType="Pistol", name="手枪" },
    { type="Firearm", subType="LMG", name="轻机枪" },
    { type="Firearm", subType="Marksman", name="精确射手步枪" },
}

local Armor = { key="Armor", name="装备" }
local ArmorTypes = {
    { type="Helmet", subType="Helmet", name="头盔" },
    { type="Armor", subType="Armor", name="防具" },
    { type="Bag", subType="", name="背包" },
    { type="ChestBag", subType="", name="胸挂" },
    
}

local Attachment = { key="Attachment", name="配件" }
local AttachmentTypes = {
    { type="Attachment", subType="Scope", name="瞄准镜" },
    { type="Attachment", subType="Stock", name="枪托" },
    { type="Attachment", subType="ForeGrip", name="前握把" },
    { type="Attachment", subType="RearGrip", name="后握把" },
    { type="Attachment", subType="Muzzle", name="枪口" },
    { type="Attachment", subType="Barrel", name="枪管" },
    { type="Attachment", subType="TacticalDevice", name="战术装备" },
    { type="Attachment", subType="Magazine", name="弹匣" },
    
}

local Melee = { key="Melee", name="近战武器" }
local MeleeTypes = {
    { type="Melee", subType="Dagger", name="匕首" },
    { type="Melee", subType="Bat", name="棍棒" },
    { type="Melee", subType="Axe", name="斧头" },
    
}

local Ammo = { key="Ammo", name="弹药" }
local AmmoTypes = {
    { type="Ammo", subType=".50 AE", name=".50 AE" },
    { type="Ammo", subType="9x19mm", name="9x19mm" },
    { type="Ammo", subType="5.56x45mm", name="5.56x45mm" },
    { type="Ammo", subType="5.45x39mm", name="5.45x39mm" },
    { type="Ammo", subType="6.8x51mm", name="6.8x51mm" },
    { type="Ammo", subType=".300BLK", name=".300BLK" },
    { type="Ammo", subType="7.62x51mm", name="7.62x51mm" },
    { type="Ammo", subType="5.8x42mm", name="5.8x42mm" },
    { type="Ammo", subType="4.6x30mm", name="4.6x30mm" },
    { type="Ammo", subType=".45 ACP", name=".45 ACP" },
    { type="Ammo", subType="12Gauge", name="12Gauge" },
    { type="Ammo", subType="12.7x99mm", name="12.7x99mm" },
    
}

local Consumable = { key="Consumable", name="消耗品" }
local ConsumableTypes = {
    { type="Heal", subType="Chest", name="医疗品" },
    { type="Repair", subType="Chest", name="修理工具" },
    
}

local Junk = { key="Junk", name="收藏品" }
local JunkTypes = {
    { type="Junk", subType="Electronic", name="电子物品" },
    { type="Junk", subType="Medical", name="医疗物品" },
    { type="Junk", subType="ToolMaterials", name="工具材料" },
    { type="Junk", subType="Information", name="资料情报" },
    { type="Junk", subType="Craft", name="工艺藏品" },
    
}

local Throwable = { key="Throwable", name="投掷物" }
local ThrowableTypes = {
    { type="Throwable", subType="Grenade", name="手雷" },
    { type="Throwable", subType="Smoke", name="烟雾弹" },
    { type="Throwable", subType="Flashbang", name="闪光弹" },
    { type="Throwable", subType="Molotov", name="燃烧瓶" },
    
}


TradeConfig.Categorys = {
    Mark,
    Firearm,
    Armor,
    Attachment,
    Melee,
    Ammo,
    Consumable,
    Junk,
    Throwable,
}

TradeConfig.SubCategorys = {
    Mark = MarkTypes,
    Firearm = FirearmTypes,
    Armor = ArmorTypes,
    Attachment = AttachmentTypes,
    Melee = MeleeTypes,
    Ammo = AmmoTypes,
    Consumable = ConsumableTypes,
    Junk = JunkTypes,
    Throwable =ThrowableTypes,
}

----------------------------------------------
TradeConfig.OrderTemplate = {
    orderID=0,      --订单号，中心服生成
    type=0,         --商品类型
    id=0,           --道具id
    price=0,        --商品价格
    feeRate=0,      --佣金率100
    deposit=0,      --保证金
    count=0,        --商品数量
    sellerID=0,     --卖家id
    sellerName="",  --卖家名字
    -- sellerIcon="",  --卖家头像
    sellTimestamp=0,--卖时间戳
    buyerID=0,      --买家id
    buyerName="",   --买家名称
    -- buyerIcon="",   --买家头像
    buyTimestamap=0,--买时间戳
    extendData={},  --扩展数据
    filters={},     --筛选条件
}

return TradeConfig