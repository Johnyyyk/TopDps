local addon = TopDps
local Priest = addon.Priest

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do
        result[ids[index]] = true
    end
    return result
end

local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(Priest.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

SetDefaults(Priest.TALENT_TABS.DISCIPLINE, {
    "innerFire",
    "powerInfusion",
    "painSuppression",
    "penance",
    "prayerOfMending",
    "innerFocus",
    "shadowfiend",
    "hymnOfHope",
    "divineHymn",
})

SetDefaults(Priest.TALENT_TABS.HOLY, {
    "innerFire",
    "guardianSpirit",
    "circleOfHealing",
    "prayerOfMending",
    "innerFocus",
    "shadowfiend",
    "hymnOfHope",
    "divineHymn",
})

SetDefaults(Priest.TALENT_TABS.SHADOW, {
    "innerFire",
    "shadowform",
    "vampiricEmbrace",
    "dispersion",
    "shadowfiend",
    "hymnOfHope",
})
