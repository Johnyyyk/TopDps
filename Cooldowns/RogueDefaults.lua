local addon = TopDps
local Rogue = addon.Rogue

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do result[ids[index]] = true end
    return result
end
local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(Rogue.CLASS_TOKEN, talentTab)
    if profile then profile.defaultElementEnabled = Allowlist(ids) end
end

SetDefaults(Rogue.TALENT_TABS.ASSASSINATION, {
    "poisons", "tricksOfTheTrade", "vanish", "coldBlood", "overkill",
})
SetDefaults(Rogue.TALENT_TABS.COMBAT, {
    "poisons", "tricksOfTheTrade", "bladeFlurry", "adrenalineRush", "killingSpree",
})
SetDefaults(Rogue.TALENT_TABS.SUBTLETY, {
    "poisons", "tricksOfTheTrade", "vanish", "shadowDance", "premeditation", "shadowstep",
})
