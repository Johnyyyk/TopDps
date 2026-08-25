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
        "pestilence",
        "scourgeStrike",
        "bloodStrike",
        "deathCoil",
        "bloodBoil",
    },

    abilities = {
        deathAndDecay = { spellIds = { DeathKnight.SPELL_IDS.deathAndDecay } },
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
        scourgeStrike = { spellIds = { DeathKnight.SPELL_IDS.scourgeStrike } },
        bloodStrike = { spellIds = { DeathKnight.SPELL_IDS.bloodStrike } },
        deathCoil = { spellIds = { DeathKnight.SPELL_IDS.deathCoil } },
        bloodBoil = { spellIds = { DeathKnight.SPELL_IDS.bloodBoil } },
    },
})

local PRIORITY_SINGLE_TARGET = {
    "deathAndDecay",
    "icyTouch",
    "plagueStrike",
    "pestilence",
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

local function UsesScourgeStrike(context)
    local entries = context and context.actionsByCategory and context.actionsByCategory.scourgeStrike or nil
    return type(entries) == "table" and #entries > 0
end

function Unholy:IsCategoryAllowed(category, context)
    local enemyCount = DeathKnight:GetEnemyCount(context)

    if category == "deathAndDecay" then
        return enemyCount >= 2 or not UsesScourgeStrike(context)
    end

    if category == "pestilence" then
        return DeathKnight:ShouldUsePestilence(context)
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
