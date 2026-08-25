local addon = TopDps
local Hunter = addon.Hunter

local Survival = addon.SpecProvider:Create({
    id = "HUNTER_SURVIVAL",
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.SURVIVAL,

    categories = {
        "huntersMark",
        "killShot",
        "explosiveShot",
        "serpentSting",
        "blackArrow",
        "aimedShot",
        "multiShot",
        "steadyShot",
        "volley",
    },

    abilities = {
        huntersMark = {
            spellIds = { Hunter.SPELL_IDS.huntersMark },
            refresh = {
                auraSpellIds = { Hunter.SPELL_IDS.huntersMark },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = false,
                lead = 3,
            },
        },
        killShot = { spellIds = { Hunter.SPELL_IDS.killShot } },
        explosiveShot = { spellIds = { Hunter.SPELL_IDS.explosiveShot } },
        serpentSting = {
            spellIds = { Hunter.SPELL_IDS.serpentSting },
            refresh = {
                auraSpellIds = { Hunter.SPELL_IDS.serpentSting },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        blackArrow = {
            spellIds = { Hunter.SPELL_IDS.blackArrow },
            refresh = {
                auraSpellIds = { Hunter.SPELL_IDS.blackArrow },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        aimedShot = { spellIds = { Hunter.SPELL_IDS.aimedShot } },
        multiShot = { spellIds = { Hunter.SPELL_IDS.multiShot } },
        steadyShot = { spellIds = { Hunter.SPELL_IDS.steadyShot } },
        volley = { spellIds = { Hunter.SPELL_IDS.volley } },
    },
})

local PRIORITY_SINGLE = {
    "huntersMark",
    "killShot",
    "explosiveShot",
    "serpentSting",
    "blackArrow",
    "aimedShot",
    "steadyShot",
}

local PRIORITY_MOVING = {
    "huntersMark",
    "killShot",
    "explosiveShot",
    "serpentSting",
    "blackArrow",
    "aimedShot",
}

local PRIORITY_AOE = {
    "killShot",
    "multiShot",
    "volley",
}

function Survival:IsCategoryAllowed(category, context)
    if category == "killShot" then
        return Hunter:IsExecute(context)
    end

    if category == "explosiveShot" then
        return Hunter:FindOwnTargetAura({ Hunter.SPELL_IDS.explosiveShot }) == nil
    end

    if category == "steadyShot" or category == "multiShot" or category == "volley" then
        return not Hunter:IsMoving(context)
    end

    return true
end

function Survival:GetPriority(context)
    if Hunter:GetEnemyCount(context) >= 4 and not Hunter:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Hunter:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

function Survival:GetDebugState()
    return "LnL=" .. tostring(Hunter:HasPlayerAura({ Hunter.SPELL_IDS.lockAndLoad }))
end

addon.SpecRegistry:Register(Survival)
