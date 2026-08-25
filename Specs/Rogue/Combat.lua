local addon = TopDps
local Rogue = addon.Rogue

local Combat = addon.SpecProvider:Create({
    id = "ROGUE_COMBAT",
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.COMBAT,

    categories = {
        "sliceAndDice",
        "rupture",
        "eviscerate",
        "sinisterStrike",
        "fanOfKnives",
    },

    abilities = {
        sliceAndDice = {
            spellIds = { Rogue.SPELL_IDS.sliceAndDice },
            refresh = {
                auraSpellIds = { Rogue.SPELL_IDS.sliceAndDice },
                unit = "player",
                filter = "HELPFUL",
                ownOnly = false,
                lead = 2,
            },
        },
        rupture = {
            spellIds = { Rogue.SPELL_IDS.rupture },
            refresh = {
                auraSpellIds = { Rogue.SPELL_IDS.rupture },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        eviscerate = { spellIds = { Rogue.SPELL_IDS.eviscerate } },
        sinisterStrike = { spellIds = { Rogue.SPELL_IDS.sinisterStrike } },
        fanOfKnives = { spellIds = { Rogue.SPELL_IDS.fanOfKnives } },
    },
})

local PRIORITY_SINGLE = {
    "sliceAndDice",
    "rupture",
    "eviscerate",
    "sinisterStrike",
}

local PRIORITY_AOE = {
    "sliceAndDice",
    "fanOfKnives",
}

function Combat:IsCategoryAllowed(category, context)
    local comboPoints = Rogue:GetComboPoints(context)

    if category == "sliceAndDice" then
        return comboPoints >= 1
    end

    if category == "rupture" or category == "eviscerate" then
        return comboPoints >= 5
    end

    if category == "sinisterStrike" then
        return comboPoints < 5
    end

    if category == "fanOfKnives" then
        return Rogue:GetEnemyCount(context) >= 3
    end

    return true
end

function Combat:GetPriority(context)
    if Rogue:GetEnemyCount(context) >= 3 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Combat)
