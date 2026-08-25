local addon = TopDps

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do result[ids[index]] = true end
    return result
end
local function SetProfileDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(addon.Paladin.CLASS_TOKEN, talentTab)
    if profile then profile.defaultElementEnabled = Allowlist(ids) end
end

SetProfileDefaults(addon.Paladin.TALENT_TABS.HOLY, {
    "avengingWrath",
    "layOnHands",
    "divinePlea",
    "currentSeal",
    "sacredShield",
    "holyShock",
    "divineFavor",
    "divineIllumination",
    "auraMastery",
    "beaconOfLight",
    "infusionOfLight",
    "judgementsOfThePure",
    "lightsGrace",
})

SetProfileDefaults(addon.Paladin.TALENT_TABS.PROTECTION, {
    "avengingWrath",
    "divineProtection",
    "handOfReckoning",
    "righteousDefense",
    "divinePlea",
    "currentSeal",
    "sacredShield",
    "avengersShield",
    "divineSacrifice",
    "holyShield",
    "ardentDefender",
    "divineGuardian",
    "righteousFury",
    "redoubt",
    "reckoning",
    "sealStacks",
})

SetProfileDefaults(addon.Paladin.TALENT_TABS.RETRIBUTION, {
    "avengingWrath",
    "divinePlea",
    "currentSeal",
    "artOfWar",
    "vengeance",
    "sealStacks",
})
