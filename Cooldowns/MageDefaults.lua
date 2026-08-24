local addon = TopDps
local Mage = addon.Mage

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do
        result[ids[index]] = true
    end
    return result
end

local function SetDefaults(talentTab, extra)
    local ids = {
        "mirrorImage",
        "evocation",
        "iceBlock",
        "counterspell",
        "invisibility",
    }
    local index
    for index = 1, #extra do
        ids[#ids + 1] = extra[index]
    end

    local profile = addon.CooldownRegistry:GetProfile(Mage.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

SetDefaults(Mage.TALENT_TABS.ARCANE, { "arcanePower", "presenceOfMind", "missileBarrage" })
SetDefaults(Mage.TALENT_TABS.FIRE, { "combustion", "hotStreak" })
SetDefaults(Mage.TALENT_TABS.FROST, { "icyVeins", "coldSnap", "fingersOfFrost", "brainFreeze" })
