local addon = TopDps
local Priest = addon.Priest

local Shadow = addon.SpecProvider:Create({
    id = "PRIEST_SHADOW",
    classToken = Priest.CLASS_TOKEN,
    talentTab = Priest.TALENT_TABS.SHADOW,
    defaultForClass = true,

    categories = {
        "vampiricTouch",
        "devouringPlague",
        "shadowWordPain",
        "mindBlast",
        "mindFlay",
        "shadowWordDeath",
        "mindSear",
    },

    abilities = {
        vampiricTouch = {
            spellIds = { Priest.SPELL_IDS.vampiricTouch },
            refresh = {
                auraSpellIds = { Priest.SPELL_IDS.vampiricTouch },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = addon.REFRESH_LEAD_CAST_TIME,
            },
        },
        devouringPlague = {
            spellIds = { Priest.SPELL_IDS.devouringPlague },
            refresh = {
                auraSpellIds = { Priest.SPELL_IDS.devouringPlague },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
            },
        },
        shadowWordPain = {
            spellIds = { Priest.SPELL_IDS.shadowWordPain },
            refresh = {
                auraSpellIds = { Priest.SPELL_IDS.shadowWordPain },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 0,
                isRefreshDue = function(_, aura)
                    return aura == nil
                end,
            },
        },
        mindBlast = { spellIds = { Priest.SPELL_IDS.mindBlast } },
        mindFlay = { spellIds = { Priest.SPELL_IDS.mindFlay } },
        shadowWordDeath = { spellIds = { Priest.SPELL_IDS.shadowWordDeath } },
        mindSear = { spellIds = { Priest.SPELL_IDS.mindSear } },
    },
})

local PRIORITY_SINGLE = {
    "shadowWordPain",
    "vampiricTouch",
    "devouringPlague",
    "mindBlast",
    "mindFlay",
}

local PRIORITY_MOVING = {
    "shadowWordPain",
    "devouringPlague",
    "shadowWordDeath",
}

local PRIORITY_AOE = {
    "vampiricTouch",
    "devouringPlague",
    "mindSear",
}

function Shadow:IsCategoryAllowed(category, context)
    if category == "shadowWordPain" then
        return Priest:GetShadowWeavingStacks() >= 5
            and Priest:HasEnoughTimeToBenefit(context, 8)
    end

    if category == "vampiricTouch" or category == "devouringPlague" then
        return Priest:HasEnoughTimeToBenefit(context, 8)
            and (category ~= "vampiricTouch" or not Priest:IsMoving(context))
    end

    if category == "mindBlast" or category == "mindFlay" then
        return not Priest:IsMoving(context)
    end

    if category == "shadowWordDeath" then
        return Priest:IsMoving(context)
    end

    if category == "mindSear" then
        return not Priest:IsMoving(context) and Priest:GetEnemyCount(context) >= 4
    end

    return true
end

function Shadow:GetPriority(context)
    if Priest:GetEnemyCount(context) >= 4 and not Priest:IsMoving(context) then
        return PRIORITY_AOE
    end

    if Priest:IsMoving(context) then
        return PRIORITY_MOVING
    end

    return PRIORITY_SINGLE
end

function Shadow:GetDebugState()
    return "ShadowWeaving=" .. tostring(Priest:GetShadowWeavingStacks())
end

addon.SpecRegistry:Register(Shadow)
