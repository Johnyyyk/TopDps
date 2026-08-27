local addon = TopDps
local Rogue = addon.Rogue

local Assassination = addon.SpecProvider:Create({
    id = "ROGUE_ASSASSINATION",
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.ASSASSINATION,
    defaultForClass = true,

    categories = {
        "sliceAndDice",
        "hungerForBlood",
        "rupture",
        "envenom",
        "mutilate",
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
                lead = 0,
                isRefreshDue = function(_, aura)
                    return aura == nil
                end,
            },
        },
        hungerForBlood = {
            spellIds = { Rogue.SPELL_IDS.hungerForBlood },
            refresh = {
                auraSpellIds = { Rogue.SPELL_IDS.hungerForBlood },
                unit = "player",
                filter = "HELPFUL",
                ownOnly = false,
                lead = 4,
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
        envenom = { spellIds = { Rogue.SPELL_IDS.envenom } },
        mutilate = { spellIds = { Rogue.SPELL_IDS.mutilate } },
        fanOfKnives = { spellIds = { Rogue.SPELL_IDS.fanOfKnives } },
    },
})

local PRIORITY_SINGLE = {
    "sliceAndDice",
    "hungerForBlood",
    "rupture",
    "envenom",
    "mutilate",
}

local PRIORITY_AOE = {
    "hungerForBlood",
    "fanOfKnives",
}

function Assassination:IsCategoryAllowed(category, context)
    local comboPoints = Rogue:GetComboPoints(context)

    if category == "sliceAndDice" then
        return comboPoints >= 1
    end

    if category == "rupture" then
        return comboPoints >= 1
            and not Rogue:HasPlayerAura({ Rogue.SPELL_IDS.hungerForBlood })
    end

    if category == "envenom" then
        return comboPoints >= 4
            and not Rogue:HasPlayerAura({ Rogue.SPELL_IDS.envenom })
    end

    if category == "mutilate" then
        return comboPoints < 4
    end

    if category == "fanOfKnives" then
        return Rogue:GetEnemyCount(context) >= 4
    end

    return true
end

function Assassination:GetPriority(context)
    if Rogue:GetEnemyCount(context) >= 4 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Assassination)
