local addon = TopDps
local Hunter = addon.Hunter

local Marksmanship = addon.SpecProvider:Create({
    id = "HUNTER_MARKSMANSHIP",
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.MARKSMANSHIP,
    defaultForClass = true,

    categories = {
        "huntersMark",
        "killShot",
        "serpentSting",
        "chimeraShot",
        "aimedShot",
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
                lead = 0,
            },
        },
        chimeraShot = { spellIds = { Hunter.SPELL_IDS.chimeraShot } },
        aimedShot = { spellIds = { Hunter.SPELL_IDS.aimedShot } },
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
    "chimeraShot",
    "aimedShot",
    "arcaneShot",
    "steadyShot",
}

local PRIORITY_MOVING = {
    "huntersMark",
    "killShot",
    "serpentSting",
    "chimeraShot",
    "aimedShot",
    "arcaneShot",
}

local PRIORITY_AOE = {
    "killShot",
    "multiShot",
    "volley",
}

function Marksmanship:IsCategoryAllowed(category, context)
    if category == "killShot" then
        return Hunter:IsExecute(context)
    end

    if category == "arcaneShot" then
        return Hunter:IsMoving(context) or Hunter:ShouldUseArcaneShot()
    end

    if category == "steadyShot" or category == "multiShot" or category == "volley" then
        return not Hunter:IsMoving(context)
    end

    return true
end

function Marksmanship:GetPriority(context)
    if Hunter:GetEnemyCount(context) >= 4 and not Hunter:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Hunter:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Marksmanship)
