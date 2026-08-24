local addon = TopDps
local Hunter = addon.Hunter

local BeastMastery = addon.SpecProvider:Create({
    id = "HUNTER_BEAST_MASTERY",
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.BEAST_MASTERY,

    categories = {
        "huntersMark",
        "killShot",
        "serpentSting",
        "arcaneShot",
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
        serpentSting = {
            spellIds = { Hunter.SPELL_IDS.serpentSting },
            refresh = {
                auraSpellIds = { Hunter.SPELL_IDS.serpentSting },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 1,
            },
        },
        arcaneShot = { spellIds = { Hunter.SPELL_IDS.arcaneShot } },
        multiShot = { spellIds = { Hunter.SPELL_IDS.multiShot } },
        steadyShot = { spellIds = { Hunter.SPELL_IDS.steadyShot } },
        volley = { spellIds = { Hunter.SPELL_IDS.volley } },
    },
})

local PRIORITY_SINGLE = {
    "huntersMark",
    "killShot",
    "serpentSting",
    "arcaneShot",
    "multiShot",
    "steadyShot",
}

local PRIORITY_MOVING = {
    "huntersMark",
    "killShot",
    "serpentSting",
    "arcaneShot",
}

local PRIORITY_AOE = {
    "killShot",
    "multiShot",
    "volley",
}

function BeastMastery:IsCategoryAllowed(category, context)
    if category == "killShot" then
        return Hunter:IsExecute(context)
    end

    if category == "volley" then
        return not Hunter:IsMoving(context) and Hunter:GetEnemyCount(context) >= 4
    end

    if category == "multiShot" then
        return not Hunter:IsMoving(context)
    end

    if category == "steadyShot" then
        return not Hunter:IsMoving(context)
    end

    return true
end

function BeastMastery:GetPriority(context)
    if Hunter:GetEnemyCount(context) >= 4 and not Hunter:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Hunter:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(BeastMastery)
