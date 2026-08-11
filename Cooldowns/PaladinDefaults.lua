local addon = TopDps

local function Allowlist(ids)
    local result = {
        __allowlist = true,
    }
    local index

    for index = 1, #ids do
        result[ids[index]] = true
    end

    return result
end

local function SetProfileDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(addon.Paladin.CLASS_TOKEN, talentTab)
    if not profile then
        return
    end

    profile.defaultElementEnabled = Allowlist(ids)
end

SetProfileDefaults(addon.Paladin.TALENT_TABS.HOLY, {
    "avengingWrath",
    "divineProtection",
    "divineShield",
    "handOfProtection",
    "handOfSacrifice",
    "layOnHands",
    "handOfFreedom",
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
    "divineShield",
    "handOfSacrifice",
    "layOnHands",
    "handOfFreedom",
    "handOfReckoning",
    "righteousDefense",
    "hammerOfJustice",
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
    "divineProtection",
    "divineShield",
    "handOfFreedom",
    "handOfSalvation",
    "hammerOfJustice",
    "divinePlea",
    "currentSeal",
    "repentance",
    "artOfWar",
    "vengeance",
    "sealStacks",
})
