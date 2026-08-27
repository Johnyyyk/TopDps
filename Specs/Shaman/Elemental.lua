local addon = TopDps
local Shaman = addon.Shaman

local Elemental = addon.SpecProvider:Create({
    id = "SHAMAN_ELEMENTAL",
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ELEMENTAL,

    categories = {
        "flameShock",
        "lavaBurst",
        "chainLightning",
        "fireNova",
        "lightningBolt",
        "earthShock",
    },

    abilities = {
        flameShock = {
            spellIds = { Shaman.SPELL_IDS.flameShock },
            refresh = {
                auraSpellIds = { Shaman.SPELL_IDS.flameShock },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                isRefreshDue = function(_, aura)
                    return aura == nil
                end,
            },
        },
        lavaBurst = { spellIds = { Shaman.SPELL_IDS.lavaBurst } },
        chainLightning = { spellIds = { Shaman.SPELL_IDS.chainLightning } },
        fireNova = { spellIds = { Shaman.SPELL_IDS.fireNova } },
        lightningBolt = { spellIds = { Shaman.SPELL_IDS.lightningBolt } },
        earthShock = { spellIds = { Shaman.SPELL_IDS.earthShock } },
    },

    settings = {
        {
            type = "checkbox",
            key = "useMovementPriority",
            labelKey = "ROTATION_USE_MOVEMENT_PRIORITY",
            default = true,
        },
    },
})

local PRIORITY_SINGLE = {
    "flameShock",
    "lavaBurst",
    "chainLightning",
    "lightningBolt",
}

local PRIORITY_AOE = {
    "chainLightning",
    "fireNova",
    "flameShock",
    "lavaBurst",
    "lightningBolt",
}

local PRIORITY_MOVING = {
    "flameShock",
    "earthShock",
    "fireNova",
}

function Elemental:IsCategoryAllowed(category, context)
    if category == "lavaBurst" then
        return Shaman:HasOwnTargetAura({ Shaman.SPELL_IDS.flameShock })
    end

    if category == "earthShock" then
        return Shaman:HasOwnTargetAura({ Shaman.SPELL_IDS.flameShock })
    end

    if category == "fireNova" then
        return Shaman:GetEnemyCount(context) >= 3
    end

    return true
end

function Elemental:GetPriority(context)
    if self:GetSetting("useMovementPriority") ~= false and Shaman:IsMoving(context) then
        return PRIORITY_MOVING
    end

    if Shaman:GetEnemyCount(context) >= 3 then
        return PRIORITY_AOE
    end

    return PRIORITY_SINGLE
end

addon.SpecRegistry:Register(Elemental)
