local addon = TopDps
local Druid = addon.Druid

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do result[ids[index]] = true end
    return result
end

local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(Druid.CLASS_TOKEN, talentTab)
    if profile then profile.defaultElementEnabled = Allowlist(ids) end
end

SetDefaults(Druid.TALENT_TABS.BALANCE, {
    "markOfTheWild",
    "moonkinForm",
    "starfall",
    "forceOfNature",
    "innervate",
    "solarEclipse",
    "lunarEclipse",
})

SetDefaults(Druid.TALENT_TABS.FERAL, {
    "markOfTheWild",
    "currentFeralForm",
    "tigersFury",
    "berserk",
    "clearcasting",
})

SetDefaults(Druid.TALENT_TABS.RESTORATION, {
    "markOfTheWild",
    "treeOfLife",
    "naturesSwiftness",
    "swiftmend",
    "wildGrowth",
    "tranquility",
    "innervate",
    "rebirth",
    "clearcasting",
})
