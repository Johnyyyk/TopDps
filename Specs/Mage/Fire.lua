local addon = TopDps
local Mage = addon.Mage

local Fire = addon.SpecProvider:Create({
    id = "MAGE_FIRE",
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.FIRE,

    categories = {
        "scorch",
        "livingBomb",
        "pyroblast",
        "fireball",
        "frostfireBolt",
        "fireBlast",
        "blizzard",
    },

    abilities = {
        scorch = {
            spellIds = { Mage.SPELL_IDS.scorch },
            refresh = {
                auraSpellIds = {
                    Mage.SPELL_IDS.improvedScorch,
                    Mage.SPELL_IDS.shadowMastery,
                    Mage.SPELL_IDS.wintersChill,
                },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = false,
                lead = 3,
            },
        },
        livingBomb = {
            spellIds = { Mage.SPELL_IDS.livingBomb },
            refresh = {
                auraSpellIds = { Mage.SPELL_IDS.livingBomb },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        pyroblast = { spellIds = { Mage.SPELL_IDS.pyroblast } },
        fireball = { spellIds = { Mage.SPELL_IDS.fireball } },
        frostfireBolt = { spellIds = { Mage.SPELL_IDS.frostfireBolt } },
        fireBlast = { spellIds = { Mage.SPELL_IDS.fireBlast } },
        blizzard = { spellIds = { Mage.SPELL_IDS.blizzard } },
    },

    settings = {
        {
            type = "dropdown",
            key = "fillerMode",
            labelKey = "MAGE_FIRE_FILLER_MODE",
            default = Mage.FIRE_FILLER_FIREBALL,
            values = {
                Mage.FIRE_FILLER_FIREBALL,
                Mage.FIRE_FILLER_FROSTFIRE,
            },
            valueLabels = {
                [Mage.FIRE_FILLER_FIREBALL] = "MAGE_FIRE_FILLER_FIREBALL",
                [Mage.FIRE_FILLER_FROSTFIRE] = "MAGE_FIRE_FILLER_FROSTFIRE",
            },
        },
    },
})

local PRIORITY_SINGLE = {
    "scorch",
    "livingBomb",
    "pyroblast",
    "fireball",
    "frostfireBolt",
}

local PRIORITY_MOVING = {
    "scorch",
    "livingBomb",
    "pyroblast",
    "fireBlast",
}

local PRIORITY_AOE = {
    "livingBomb",
    "blizzard",
}

function Fire:IsCategoryAllowed(category, context)
    if category == "pyroblast" then
        return Mage:HasPlayerAura({ Mage.SPELL_IDS.hotStreak })
    end

    if category == "fireball" then
        return not Mage:IsMoving(context)
            and self:GetSetting("fillerMode") == Mage.FIRE_FILLER_FIREBALL
    end

    if category == "frostfireBolt" then
        return not Mage:IsMoving(context)
            and self:GetSetting("fillerMode") == Mage.FIRE_FILLER_FROSTFIRE
    end

    if category == "fireBlast" then
        return Mage:IsMoving(context)
    end

    if category == "blizzard" then
        return not Mage:IsMoving(context) and Mage:GetEnemyCount(context) >= 4
    end

    return true
end

function Fire:GetPriority(context)
    if Mage:GetEnemyCount(context) >= 4 and not Mage:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Mage:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Fire)
