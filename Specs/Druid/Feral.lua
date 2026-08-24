local addon = TopDps
local Druid = addon.Druid

local Feral = addon.SpecProvider:Create({
    id = "DRUID_FERAL",
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.FERAL,
    defaultForClass = true,

    categories = {
        "savageRoar",
        "rip",
        "rake",
        "mangleCat",
        "ferociousBite",
        "shred",
        "swipeCat",
    },

    abilities = {
        savageRoar = {
            spellIds = { Druid.SPELL_IDS.savageRoar },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.savageRoar },
                unit = "player",
                filter = "HELPFUL",
                ownOnly = false,
                lead = 2,
            },
        },
        rip = {
            spellIds = { Druid.SPELL_IDS.rip },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.rip },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 2,
            },
        },
        rake = {
            spellIds = { Druid.SPELL_IDS.rake },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.rake },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 1,
            },
        },
        mangleCat = {
            spellIds = { Druid.SPELL_IDS.mangleCat },
            refresh = {
                auraSpellIds = { Druid.SPELL_IDS.mangleCat },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = false,
                lead = 5,
            },
        },
        ferociousBite = {
            spellIds = { Druid.SPELL_IDS.ferociousBite },
        },
        shred = {
            spellIds = { Druid.SPELL_IDS.shred },
        },
        swipeCat = {
            spellIds = { Druid.SPELL_IDS.swipeCat },
        },
    },
})

local EMPTY_PRIORITY = {}

local PRIORITY_NORMAL = {
    "savageRoar",
    "rip",
    "rake",
    "mangleCat",
    "ferociousBite",
    "shred",
}

local PRIORITY_CLEARCASTING = {
    "savageRoar",
    "rip",
    "rake",
    "mangleCat",
    "shred",
    "ferociousBite",
}

local PRIORITY_AOE = {
    "savageRoar",
    "swipeCat",
}

local function GetComboPoints(context)
    return math.max(0, tonumber(context and context.player and context.player.comboPoints) or 0)
end

function Feral:CanSafelyBite(context)
    if GetComboPoints(context) < 5 then
        return false
    end

    local rip = Druid:FindTargetAura({ Druid.SPELL_IDS.rip }, true)
    local roar = Druid:FindPlayerAura({ Druid.SPELL_IDS.savageRoar })

    return Druid:GetAuraRemaining(rip, context) >= 10
        and Druid:GetAuraRemaining(roar, context) >= 10
end

function Feral:IsCategoryAllowed(category, context)
    if not Druid:IsCatForm() then
        return false
    end

    local comboPoints = GetComboPoints(context)

    if category == "savageRoar" then
        return comboPoints >= 1
    end

    if category == "rip" then
        return comboPoints >= 5
    end

    if category == "ferociousBite" then
        return self:CanSafelyBite(context)
    end

    if category == "swipeCat" then
        return Druid:GetEnemyCount(context) >= 4
    end

    return true
end

function Feral:GetPriority(context)
    if not Druid:IsCatForm() then
        return EMPTY_PRIORITY
    end

    if Druid:GetEnemyCount(context) >= 4 then
        return PRIORITY_AOE
    end

    if Druid:HasPlayerAura({ Druid.SPELL_IDS.clearcasting }) then
        return PRIORITY_CLEARCASTING
    end

    return PRIORITY_NORMAL
end

addon.SpecRegistry:Register(Feral)
