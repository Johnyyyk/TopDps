local addon = TopDps
local Mage = addon.Mage

local Frost = addon.SpecProvider:Create({
    id = "MAGE_FROST",
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.FROST,

    categories = {
        "deepFreeze",
        "frostfireBolt",
        "frostbolt",
        "iceLance",
        "fireBlast",
        "blizzard",
    },

    abilities = {
        deepFreeze = { spellIds = { Mage.SPELL_IDS.deepFreeze } },
        frostfireBolt = { spellIds = { Mage.SPELL_IDS.frostfireBolt } },
        frostbolt = { spellIds = { Mage.SPELL_IDS.frostbolt } },
        iceLance = { spellIds = { Mage.SPELL_IDS.iceLance } },
        fireBlast = { spellIds = { Mage.SPELL_IDS.fireBlast } },
        blizzard = { spellIds = { Mage.SPELL_IDS.blizzard } },
    },
})

local PRIORITY_SINGLE = {
    "deepFreeze",
    "frostfireBolt",
    "frostbolt",
}

local PRIORITY_MOVING = {
    "deepFreeze",
    "frostfireBolt",
    "fireBlast",
    "iceLance",
}

local PRIORITY_AOE = {
    "blizzard",
}

function Frost:IsCategoryAllowed(category, context)
    local fingers = Mage:HasPlayerAura({ Mage.SPELL_IDS.fingersOfFrost })
    local brainFreeze = Mage:HasPlayerAura({ Mage.SPELL_IDS.brainFreeze })

    if category == "deepFreeze" then
        return fingers
    end

    if category == "frostfireBolt" then
        return brainFreeze
    end

    if category == "iceLance" then
        return Mage:IsMoving(context) or fingers
    end

    if category == "fireBlast" then
        return Mage:IsMoving(context)
    end

    if category == "blizzard" then
        return not Mage:IsMoving(context) and Mage:GetEnemyCount(context) >= 4
    end

    if category == "frostbolt" then
        return not Mage:IsMoving(context)
    end

    return true
end

function Frost:GetPriority(context)
    if Mage:GetEnemyCount(context) >= 4 and not Mage:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Mage:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Frost)
