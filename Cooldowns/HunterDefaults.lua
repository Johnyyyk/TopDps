local addon = TopDps
local Hunter = addon.Hunter

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
        "petAlive",
        "rapidFire",
        "killCommand",
        "deterrence",
        "disengage",
        "feignDeath",
        "misdirection",
    }
    local index
    for index = 1, #extra do
        ids[#ids + 1] = extra[index]
    end

    local profile = addon.CooldownRegistry:GetProfile(Hunter.CLASS_TOKEN, talentTab)
    if profile then
        profile.defaultElementEnabled = Allowlist(ids)
    end
end

SetDefaults(Hunter.TALENT_TABS.BEAST_MASTERY, {
    "bestialWrath",
})
SetDefaults(Hunter.TALENT_TABS.MARKSMANSHIP, {
    "readiness",
    "silencingShot",
})
SetDefaults(Hunter.TALENT_TABS.SURVIVAL, {
    "lockAndLoad",
})
