local addon = TopDps
local Rogue = addon.Rogue

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
        "poisons",
        "tricksOfTheTrade",
        "kick",
        "vanish",
        "cloakOfShadows",
        "evasion",
        "sprint",
    }
    local index
    for index = 1, #extra do
        ids[#ids + 1] = extra[index]
    end

    local profile = addon.CooldownRegistry:GetProfile(Rogue.CLASS_TOKEN, talentTab)
    if profile then profile.defaultElementEnabled = Allowlist(ids) end
end

SetDefaults(Rogue.TALENT_TABS.ASSASSINATION, { "coldBlood" })
SetDefaults(Rogue.TALENT_TABS.COMBAT, { "bladeFlurry", "adrenalineRush", "killingSpree" })
SetDefaults(Rogue.TALENT_TABS.SUBTLETY, { "shadowDance", "shadowstep" })
