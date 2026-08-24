local addon = TopDps
local DeathKnight = addon.DeathKnight

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

local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(DeathKnight.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

local COMMON = {
    "empowerRuneWeapon",
    "antiMagicShell",
    "iceboundFortitude",
    "mindFreeze",
}

SetDefaults(DeathKnight.TALENT_TABS.BLOOD, {
    COMMON[1],
    COMMON[2],
    COMMON[3],
    COMMON[4],
    "dancingRuneWeapon",
})

SetDefaults(DeathKnight.TALENT_TABS.FROST, {
    COMMON[1],
    COMMON[2],
    COMMON[3],
    COMMON[4],
    "unbreakableArmor",
    "killingMachine",
    "rime",
})

SetDefaults(DeathKnight.TALENT_TABS.UNHOLY, {
    COMMON[1],
    COMMON[2],
    COMMON[3],
    COMMON[4],
    "summonGargoyle",
    "boneShield",
})
