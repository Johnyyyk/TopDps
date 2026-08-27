local addon = TopDps
local Warlock = addon.Warlock

local Demonology = addon.SpecProvider:Create({
    id = "WARLOCK_DEMONOLOGY",
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DEMONOLOGY,

    categories = {
        "lifeTap",
        "curse",
        "corruption",
        "immolate",
        "shadowBolt",
        "incinerate",
        "soulFire",
    },

    abilities = {
        lifeTap = {
            spellIds = { Warlock.SPELL_IDS.lifeTap },
        },
        curse = {
            spellIds = {
                Warlock.SPELL_IDS.curseElements,
                Warlock.SPELL_IDS.curseDoom,
                Warlock.SPELL_IDS.curseAgony,
            },
        },
        corruption = {
            spellIds = { Warlock.SPELL_IDS.corruption },
        },
        immolate = {
            spellIds = { Warlock.SPELL_IDS.immolate },
            refresh = {
                auraSpellIds = { Warlock.SPELL_IDS.immolate },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = addon.REFRESH_LEAD_CAST_TIME,
            },
        },
        shadowBolt = {
            spellIds = { Warlock.SPELL_IDS.shadowBolt },
        },
        incinerate = {
            spellIds = { Warlock.SPELL_IDS.incinerate },
        },
        soulFire = {
            spellIds = { Warlock.SPELL_IDS.soulFire },
        },
    },

    settings = {
        Warlock:CreateCurseSetting(),
        {
            type = "checkbox",
            key = "useMovementPriority",
            labelKey = "ROTATION_USE_MOVEMENT_PRIORITY",
            default = true,
        },
        {
            type = "checkbox",
            key = "useTargetTimeToDie",
            labelKey = "WARLOCK_USE_TARGET_TIME_TO_DIE_FOR_CURSE",
            default = false,
            experimental = true,
            experimentalFeature = addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
        },
    },
})

local PRIORITY_NORMAL = {
    "lifeTap",
    "curse",
    "corruption",
    "immolate",
    "shadowBolt",
    "incinerate",
    "soulFire",
}

local PRIORITY_MOLTEN_CORE = {
    "lifeTap",
    "curse",
    "corruption",
    "immolate",
    "incinerate",
    "shadowBolt",
    "soulFire",
}

local PRIORITY_DECIMATION_SOUL_FIRE = {
    "lifeTap",
    "curse",
    "corruption",
    "immolate",
    "soulFire",
    "shadowBolt",
    "incinerate",
}

local PRIORITY_DECIMATION_REFRESH_CRIT = {
    "lifeTap",
    "curse",
    "corruption",
    "immolate",
    "shadowBolt",
    "soulFire",
    "incinerate",
}

local PRIORITY_MOVING = {
    "lifeTap",
    "curse",
    "corruption",
}

local function IsMovementPriorityActive(provider, context)
    return provider:GetSetting("useMovementPriority") ~= false
        and context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
end

function Demonology:GetReadyEntries(readiness, entries, category, context)
    if category == "curse" then
        return Warlock:GetCurseReadyEntries(self, readiness, entries, category, context)
    end

    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function Demonology:IsCategoryAllowed(category, context)
    local commonAllowed = Warlock:GetCommonCategoryAllowed(self, category, context)
    if commonAllowed ~= nil then
        return commonAllowed
    end

    if category == "corruption" then
        return not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.corruption })
    end

    local moltenCore = Warlock:HasPlayerAura({ Warlock.SPELL_IDS.moltenCoreProc })
    local decimation = Warlock:HasPlayerAura({ Warlock.SPELL_IDS.decimationProc })

    if category == "soulFire" then
        return decimation
    end

    if category == "incinerate" then
        return moltenCore
    end

    return true
end

function Demonology:GetPriority(context)
    if IsMovementPriorityActive(self, context) then
        return PRIORITY_MOVING
    end

    local moltenCore = Warlock:HasPlayerAura({ Warlock.SPELL_IDS.moltenCoreProc })
    local decimation = Warlock:HasPlayerAura({ Warlock.SPELL_IDS.decimationProc })
    local spellCritDebuff = Warlock:HasSpellCritDebuff()

    if decimation then
        if not spellCritDebuff then
            return PRIORITY_DECIMATION_REFRESH_CRIT
        end

        return PRIORITY_DECIMATION_SOUL_FIRE
    end

    if not spellCritDebuff then
        return PRIORITY_NORMAL
    end

    if moltenCore then
        return PRIORITY_MOLTEN_CORE
    end

    return PRIORITY_NORMAL
end

function Demonology:GetDebugState()
    return "MC="
        .. tostring(Warlock:HasPlayerAura({ Warlock.SPELL_IDS.moltenCoreProc }))
        .. ", Decimation="
        .. tostring(Warlock:HasPlayerAura({ Warlock.SPELL_IDS.decimationProc }))
end

addon.SpecRegistry:Register(Demonology)
