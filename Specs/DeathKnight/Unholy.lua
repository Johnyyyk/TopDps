local addon = TopDps
local DeathKnight = addon.DeathKnight

local Unholy = addon.SpecProvider:Create({
    id = "DEATHKNIGHT_UNHOLY",
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.UNHOLY,

    categories = {
        "deathAndDecay",
        "icyTouch",
        "plagueStrike",
        "scourgeStrike",
        "bloodStrike",
        "deathCoil",
        "pestilence",
        "bloodBoil",
    },

    abilities = {
        deathAndDecay = {
            spellIds = { DeathKnight.SPELL_IDS.deathAndDecay },
        },
        icyTouch = {
            spellIds = { DeathKnight.SPELL_IDS.icyTouch },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.frostFever },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 3,
            },
        },
        plagueStrike = {
            spellIds = { DeathKnight.SPELL_IDS.plagueStrike },
            refresh = {
                auraSpellIds = { DeathKnight.SPELL_IDS.bloodPlague },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 3,
            },
        },
        scourgeStrike = {
            spellIds = { DeathKnight.SPELL_IDS.scourgeStrike },
        },
        bloodStrike = {
            spellIds = { DeathKnight.SPELL_IDS.bloodStrike },
        },
        deathCoil = {
            spellIds = { DeathKnight.SPELL_IDS.deathCoil },
        },
        pestilence = {
            spellIds = { DeathKnight.SPELL_IDS.pestilence },
        },
        bloodBoil = {
            spellIds = { DeathKnight.SPELL_IDS.bloodBoil },
        },
    },
})

local PRIORITY_SINGLE_TARGET = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "scourgeStrike",
    "bloodStrike",
    "deathCoil",
}

local PRIORITY_AOE = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "deathCoil",
    "scourgeStrike",
    "bloodStrike",
}

function Unholy:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "pestilence" then
        return enemyCount >= 2 and DeathKnight:HasBothDiseases()
    end

    if category == "bloodBoil" then
        return enemyCount >= 2
    end

    return true
end

function Unholy:GetPriority(context)
    if DeathKnight:GetEnemyCount(context) >= 2 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE_TARGET
end

addon.SpecRegistry:Register(Unholy)
