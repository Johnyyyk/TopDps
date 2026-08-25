local addon = TopDps
local Shaman = addon.Shaman

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do
        result[ids[index]] = true
    end
    return result
end

local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(Shaman.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

SetDefaults(Shaman.TALENT_TABS.ELEMENTAL, {
    "weaponImbue",
    "waterShield",
    "elementalMastery",
    "thunderstorm",
    "windShear",
})

SetDefaults(Shaman.TALENT_TABS.ENHANCEMENT, {
    "mainHandWindfury",
    "offHandFlametongue",
    "lightningShield",
    "feralSpirit",
    "shamanisticRage",
    "maelstromWeapon",
    "windShear",
})

SetDefaults(Shaman.TALENT_TABS.RESTORATION, {
    "weaponImbue",
    "waterShield",
    "earthShield",
    "natureSwiftness",
    "manaTide",
    "tidalForce",
    "riptide",
    "windShear",
})
