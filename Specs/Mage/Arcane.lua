local addon = TopDps
local Mage = addon.Mage

local Arcane = addon.SpecProvider:Create({
    id = "MAGE_ARCANE",
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.ARCANE,
    defaultForClass = true,

    categories = {
        "arcaneMissiles",
        "arcaneBlast",
        "arcaneBarrage",
        "fireBlast",
        "blizzard",
        "arcaneExplosion",
    },

    abilities = {
        arcaneMissiles = { spellIds = { Mage.SPELL_IDS.arcaneMissiles } },
        arcaneBlast = { spellIds = { Mage.SPELL_IDS.arcaneBlast } },
        arcaneBarrage = { spellIds = { Mage.SPELL_IDS.arcaneBarrage } },
        fireBlast = { spellIds = { Mage.SPELL_IDS.fireBlast } },
        blizzard = { spellIds = { Mage.SPELL_IDS.blizzard } },
        arcaneExplosion = { spellIds = { Mage.SPELL_IDS.arcaneExplosion } },
    },
})

local PRIORITY_SINGLE = {
    "arcaneMissiles",
    "arcaneBlast",
}

local PRIORITY_MOVING = {
    "arcaneBarrage",
    "fireBlast",
}

local PRIORITY_AOE = {
    "blizzard",
    "arcaneExplosion",
}

local PRIORITY_AOE_MOVING = {
    "arcaneExplosion",
    "arcaneBarrage",
    "fireBlast",
}

function Arcane:IsCategoryAllowed(category, context)
    local stacks = Mage:GetArcaneBlastStacks()

    if category == "arcaneMissiles" then
        return stacks >= 4
    end

    if category == "arcaneBarrage" or category == "fireBlast" then
        return Mage:IsMoving(context)
    end

    if category == "blizzard" then
        return not Mage:IsMoving(context) and Mage:GetEnemyCount(context) >= 4
    end

    if category == "arcaneExplosion" then
        return Mage:GetEnemyCount(context) >= 4
    end

    return not Mage:IsMoving(context)
end

function Arcane:GetPriority(context)
    if Mage:GetEnemyCount(context) >= 4 then
        if Mage:IsMoving(context) then
            return PRIORITY_AOE_MOVING
        end
        return PRIORITY_AOE
    end

    if Mage:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

function Arcane:GetDebugState()
    return "AB=" .. tostring(Mage:GetArcaneBlastStacks())
        .. ", MB=" .. tostring(Mage:HasPlayerAura({ Mage.SPELL_IDS.missileBarrage }))
end

addon.SpecRegistry:Register(Arcane)
