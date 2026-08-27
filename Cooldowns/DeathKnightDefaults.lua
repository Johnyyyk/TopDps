local addon = TopDps
local DeathKnight = addon.DeathKnight

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do result[ids[index]] = true end
    return result
end
local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(DeathKnight.CLASS_TOKEN, talentTab)
    if profile then profile.defaultElementEnabled = Allowlist(ids) end
end

SetDefaults(DeathKnight.TALENT_TABS.BLOOD, {
    "currentPresence",
    "hornOfWinter",
    "empowerRuneWeapon",
    "dancingRuneWeapon",
    "hysteria",
    "raiseDead",
})
SetDefaults(DeathKnight.TALENT_TABS.FROST, {
    "currentPresence",
    "hornOfWinter",
    "empowerRuneWeapon",
    "unbreakableArmor",
    "raiseDead",
    "killingMachine",
    "rime",
})
SetDefaults(DeathKnight.TALENT_TABS.UNHOLY, {
    "currentPresence",
    "hornOfWinter",
    "empowerRuneWeapon",
    "ghoulAlive",
    "summonGargoyle",
    "boneShield",
})
