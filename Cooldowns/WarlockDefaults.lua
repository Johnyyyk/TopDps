local addon = TopDps
local Warlock = addon.Warlock

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
    local profile = addon.CooldownRegistry:GetProfile(Warlock.CLASS_TOKEN, talentTab)
    if not profile then
        return
    end

    profile.defaultElementEnabled = Allowlist(ids)
end

SetProfileDefaults(Warlock.TALENT_TABS.DEMONOLOGY, {
    "felArmor",
    "glyphLifeTap",
    "correctPet",
    "weaponStone",
    "soulLink",
    "metamorphosis",
    "shadowWard",
    "soulshatter",
    "demonicCircleTeleport",
    "moltenCore",
    "decimation",
})

SetProfileDefaults(Warlock.TALENT_TABS.DESTRUCTION, {
    "felArmor",
    "glyphLifeTap",
    "correctPet",
    "weaponStone",
    "shadowWard",
    "soulshatter",
    "demonicCircleTeleport",
    "backdraft",
    "empoweredImp",
})
