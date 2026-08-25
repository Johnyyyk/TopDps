local addon = TopDps
local DeathKnight = addon.DeathKnight

local Frost = addon.SpecProvider:Create({
    id = "DEATHKNIGHT_FROST",
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.FROST,
    defaultForClass = true,

    categories = {
        "icyTouch",
        "plagueStrike",
        "obliterate",
        "frostStrike",
        "howlingBlast",
        "bloodStrike",
        "deathAndDecay",
        "pestilence",
        "bloodBoil",
    },

    abilities = {
        icyTouch = {
            spellIds = { DeathKnight.SPELL_IDS.icyTouch },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.frostFever },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        plagueStrike = {
            spellIds = { DeathKnight.SPELL_IDS.plagueStrike },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.bloodPlague },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        obliterate = { spellIds = { DeathKnight.SPELL_IDS.obliterate } },
        frostStrike = { spellIds = { DeathKnight.SPELL_IDS.frostStrike } },
        howlingBlast = { spellIds = { DeathKnight.SPELL_IDS.howlingBlast } },
        bloodStrike = { spellIds = { DeathKnight.SPELL_IDS.bloodStrike } },
        deathAndDecay = { spellIds = { DeathKnight.SPELL_IDS.deathAndDecay } },
        pestilence = { spellIds = { DeathKnight.SPELL_IDS.pestilence } },
        bloodBoil = { spellIds = { DeathKnight.SPELL_IDS.bloodBoil } },
    },
})

local PRIORITY_NORMAL = {
    "icyTouch",
    "plagueStrike",
    "obliterate",
    "bloodStrike",
    "frostStrike",
    "howlingBlast",
}

local PRIORITY_KILLING_MACHINE = {
    "icyTouch",
    "plagueStrike",
    "frostStrike",
    "howlingBlast",
    "obliterate",
    "bloodStrike",
}

local PRIORITY_RIME = {
    "icyTouch",
    "plagueStrike",
    "howlingBlast",
    "obliterate",
    "bloodStrike",
    "frostStrike",
}

local PRIORITY_AOE = {
    "howlingBlast",
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "frostStrike",
    "obliterate",
    "bloodStrike",
}

function Frost:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "howlingBlast" then
        return enemyCount >= 2
            or DeathKnight:HasPlayerAura({ DeathKnight.SPELL_IDS.freezingFog })
    end

    if category == "deathAndDecay" then
        return enemyCount >= 3
    end

    if category == "pestilence" then
        return enemyCount >= 2 and DeathKnight:HasBothDiseases()
    end

    if category == "bloodBoil" then
        return enemyCount >= 3
    end

    return true
end

function Frost:GetPriority(context)
    if DeathKnight:GetEnemyCount(context) >= 2 then
        return PRIORITY_AOE
    end

    if DeathKnight:HasPlayerAura({ DeathKnight.SPELL_IDS.killingMachine }) then
        return PRIORITY_KILLING_MACHINE
    end

    if DeathKnight:HasPlayerAura({ DeathKnight.SPELL_IDS.freezingFog }) then
        return PRIORITY_RIME
    end

    return PRIORITY_NORMAL
end

addon.SpecRegistry:Register(Frost)
