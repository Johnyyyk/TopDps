local addon = TopDps
local Rogue = addon.Rogue

local Subtlety = addon.SpecProvider:Create({
    id = "ROGUE_SUBTLETY",
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.SUBTLETY,

    categories = {
        "exposeArmor",
        "sliceAndDice",
        "rupture",
        "hemorrhage",
        "eviscerate",
        "backstab",
        "fanOfKnives",
    },

    abilities = {
        exposeArmor = {
            spellIds = { Rogue.SPELL_IDS.exposeArmor },
            refresh = {
                auraSpellIds = { Rogue.SPELL_IDS.exposeArmor },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 3,
            },
        },
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
        hemorrhage = {
            spellIds = { Rogue.SPELL_IDS.hemorrhage },
            refresh = {
                auraSpellIds = { Rogue.SPELL_IDS.hemorrhage },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = false,
                lead = 3,
            },
        },
        eviscerate = { spellIds = { Rogue.SPELL_IDS.eviscerate } },
        backstab = { spellIds = { Rogue.SPELL_IDS.backstab } },
        fanOfKnives = { spellIds = { Rogue.SPELL_IDS.fanOfKnives } },
    },

    settings = {
        {
            type = "checkbox",
            key = "useExposeArmor",
            labelKey = "ROGUE_USE_EXPOSE_ARMOR",
            default = false,
        },
    },
})

local PRIORITY_SINGLE = {
    "exposeArmor",
    "sliceAndDice",
    "rupture",
    "hemorrhage",
    "eviscerate",
    "backstab",
}

local PRIORITY_AOE = {
    "sliceAndDice",
    "fanOfKnives",
}

function Subtlety:IsCategoryAllowed(category, context)
    local comboPoints = Rogue:GetComboPoints(context)

    if category == "exposeArmor" then
        return self:GetSetting("useExposeArmor") == true and comboPoints >= 1
    end

    if category == "sliceAndDice" then
        return comboPoints >= 1
    end

    if category == "rupture" or category == "eviscerate" then
        return comboPoints >= 4
    end

    if category == "hemorrhage" or category == "backstab" then
        return comboPoints < 5
    end

    if category == "fanOfKnives" then
        return Rogue:GetEnemyCount(context) >= 6
    end

    return true
end

function Subtlety:GetPriority(context)
    if Rogue:GetEnemyCount(context) >= 6 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Subtlety)
