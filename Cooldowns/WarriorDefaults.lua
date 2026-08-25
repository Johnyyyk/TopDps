local addon = TopDps
local Warrior = addon.Warrior

local function Allowlist(ids)
    local result = { __allowlist = true }
    local index
    for index = 1, #ids do
        result[ids[index]] = true
    end
    return result
end

local function SetDefaults(talentTab, ids)
    local profile = addon.CooldownRegistry:GetProfile(Warrior.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

SetDefaults(Warrior.TALENT_TABS.ARMS, {
    "currentShout",
    "correctStance",
    "bladestorm",
    "sweepingStrikes",
    "tasteForBlood",
    "suddenDeath",
    "pummel",
})

SetDefaults(Warrior.TALENT_TABS.FURY, {
    "currentShout",
    "correctStance",
    "deathWish",
    "recklessness",
    "bloodsurge",
    "pummel",
})

SetDefaults(Warrior.TALENT_TABS.PROTECTION, {
    "currentShout",
    "correctStance",
    "shieldWall",
    "lastStand",
    "shieldBlock",
    "spellReflection",
    "enragedRegeneration",
    "vigilance",
    "pummel",
})
