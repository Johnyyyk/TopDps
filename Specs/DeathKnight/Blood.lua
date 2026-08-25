local addon = TopDps
local DeathKnight = addon.DeathKnight

local Blood = addon.SpecProvider:Create({
    id = "DEATHKNIGHT_BLOOD",
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.BLOOD,

    categories = {
        "icyTouch",
        "plagueStrike",
        "pestilence",
        "heartStrike",
        "deathStrike",
        "deathCoil",
        "deathAndDecay",
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
        pestilence = { spellIds = { DeathKnight.SPELL_IDS.pestilence } },
        heartStrike = { spellIds = { DeathKnight.SPELL_IDS.heartStrike } },
        deathStrike = { spellIds = { DeathKnight.SPELL_IDS.deathStrike } },
        deathCoil = { spellIds = { DeathKnight.SPELL_IDS.deathCoil } },
        deathAndDecay = { spellIds = { DeathKnight.SPELL_IDS.deathAndDecay } },
        bloodBoil = { spellIds = { DeathKnight.SPELL_IDS.bloodBoil } },
    },
})

local PRIORITY_SINGLE_TARGET = {
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "heartStrike",
    "deathStrike",
    "deathCoil",
}

local PRIORITY_CLEAVE = {
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "heartStrike",
    "deathStrike",
    "deathCoil",
}

local PRIORITY_AOE = {
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "deathStrike",
    "deathCoil",
    "heartStrike",
}

local PRIORITY_MASS_AOE = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
    "bloodBoil",
    "deathStrike",
    "deathCoil",
}

function Blood:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "deathAndDecay" then
        return enemyCount >= 8
    end

    if category == "pestilence" then
        return DeathKnight:ShouldUsePestilence(context)
    end

    if category == "bloodBoil" then
        return enemyCount >= 5
    end

    return true
end

function Blood:GetPriority(context)
    local enemyCount = DeathKnight:GetEnemyCount(context)
    if enemyCount >= 8 then
        return PRIORITY_MASS_AOE
    end

    if enemyCount >= 5 then
        return PRIORITY_AOE
    end

    if enemyCount >= 2 then
        return PRIORITY_CLEAVE
    end

    return PRIORITY_SINGLE_TARGET
end

addon.SpecRegistry:Register(Blood)
