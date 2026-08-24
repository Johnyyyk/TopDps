local addon = TopDps
local DeathKnight = addon.DeathKnight

local Blood = addon.SpecProvider:Create({
    id = "DEATHKNIGHT_BLOOD",
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.BLOOD,

    categories = {
        "icyTouch",
        "plagueStrike",
        "deathStrike",
        "heartStrike",
        "deathCoil",
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
        deathStrike = {
            spellIds = { DeathKnight.SPELL_IDS.deathStrike },
        },
        heartStrike = {
            spellIds = { DeathKnight.SPELL_IDS.heartStrike },
        },
        deathCoil = {
            spellIds = { DeathKnight.SPELL_IDS.deathCoil },
        },
        deathAndDecay = {
            spellIds = { DeathKnight.SPELL_IDS.deathAndDecay },
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
    "icyTouch",
    "plagueStrike",
    "deathStrike",
    "heartStrike",
    "deathCoil",
}

local PRIORITY_AOE = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "deathCoil",
    "deathStrike",
    "heartStrike",
}

function Blood:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "deathAndDecay" then
        return enemyCount >= 3
    end

    if category == "pestilence" then
        return enemyCount >= 2 and DeathKnight:HasBothDiseases()
    end

    if category == "bloodBoil" then
        return enemyCount >= 2
    end

    return true
end

function Blood:GetPriority(context)
    if DeathKnight:GetEnemyCount(context) >= 2 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE_TARGET
end

addon.SpecRegistry:Register(Blood)
