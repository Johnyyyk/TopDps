local addon = TopDps
local Warlock = addon.Warlock

local SPELL_IDS = {
    unstableAffliction = 30108,
    haunt = 48181,
    drainSoul = 1120,
    seedOfCorruption = 27243,
    shadowTrance = 17941,
}

local Affliction = addon.SpecProvider:Create({
    id = "WARLOCK_AFFLICTION",
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.AFFLICTION,

    categories = {
        "lifeTap",
        "curse",
        "corruption",
        "unstableAffliction",
        "haunt",
        "shadowBolt",
        "drainSoul",
        "seedOfCorruption",
    },

    abilities = {
        lifeTap = { spellIds = { Warlock.SPELL_IDS.lifeTap } },
        curse = {
            spellIds = {
                Warlock.SPELL_IDS.curseElements,
                Warlock.SPELL_IDS.curseDoom,
                Warlock.SPELL_IDS.curseAgony,
            },
        },
        corruption = { spellIds = { Warlock.SPELL_IDS.corruption } },
        unstableAffliction = {
            spellIds = { SPELL_IDS.unstableAffliction },
            refresh = {
                auraSpellIds = { SPELL_IDS.unstableAffliction },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = addon.REFRESH_LEAD_CAST_TIME,
            },
        },
        haunt = {
            spellIds = { SPELL_IDS.haunt },
            refresh = {
                auraSpellIds = { SPELL_IDS.haunt },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = addon.REFRESH_LEAD_CAST_TIME,
            },
        },
        shadowBolt = { spellIds = { Warlock.SPELL_IDS.shadowBolt } },
        drainSoul = { spellIds = { SPELL_IDS.drainSoul } },
        seedOfCorruption = { spellIds = { SPELL_IDS.seedOfCorruption } },
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
            labelKey = "WARLOCK_AFFLICTION_USE_TARGET_TIME_TO_DIE",
            default = false,
            experimental = true,
            experimentalFeature = addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
        },
    },
})

local PRIORITY_NEEDS_ELEMENTS = {
    "lifeTap",
    "curse",
    "shadowBolt",
    "haunt",
    "unstableAffliction",
    "corruption",
}

local PRIORITY_NEEDS_CRIT_DEBUFF = {
    "lifeTap",
    "shadowBolt",
    "haunt",
    "unstableAffliction",
    "corruption",
    "curse",
}

local PRIORITY_NORMAL = {
    "lifeTap",
    "haunt",
    "unstableAffliction",
    "corruption",
    "curse",
    "shadowBolt",
}

local PRIORITY_EXECUTE = {
    "lifeTap",
    "haunt",
    "unstableAffliction",
    "corruption",
    "curse",
    "drainSoul",
    "shadowBolt",
}

local PRIORITY_EXECUTE_NEEDS_CRIT_DEBUFF = {
    "lifeTap",
    "shadowBolt",
    "haunt",
    "unstableAffliction",
    "corruption",
    "curse",
    "drainSoul",
}

local PRIORITY_MOVING = {
    "lifeTap",
    "curse",
    "corruption",
    "shadowBolt",
}

local PRIORITY_AOE = {
    "lifeTap",
    "corruption",
    "seedOfCorruption",
    "shadowBolt",
}

local function IsMovementPriorityActive(provider, context)
    return provider:GetSetting("useMovementPriority") ~= false
        and context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
end

local function IsExecute(context)
    local health = context and context.target and context.target.health or nil
    return health and health.maximum > 0 and health.fraction <= 0.25 or false
end

local function HasEnoughTimeToBenefit(context, minimumSeconds)
    local timeToDie = context and context.target and tonumber(context.target.timeToDie) or nil
    return timeToDie == nil or timeToDie > minimumSeconds
end

local function HasShadowTrance()
    return Warlock:HasPlayerAura({ SPELL_IDS.shadowTrance })
end

local function IsAutoAgonyMode(provider)
    return provider:GetSetting("curseMode") == Warlock.CURSE_MODE_AUTO
        and Warlock:HasExternalMagicVulnerability()
end

local function GetAfflictionCurseReadyEntries(provider, readiness, entries, category, context)
    if not IsAutoAgonyMode(provider) then
        return Warlock:GetCurseReadyEntries(provider, readiness, entries, category, context)
    end

    local wantedName = GetSpellInfo(Warlock.SPELL_IDS.curseAgony)
    local filtered = {}
    local index
    for index = 1, #entries do
        local entry = entries[index]
        if entry.spellId == Warlock.SPELL_IDS.curseAgony
            or (wantedName and entry.spellName == wantedName) then
            filtered[#filtered + 1] = entry
        end
    end

    return readiness:GetDefaultReadyEntries(filtered, category, provider, context)
end

function Affliction:GetReadyEntries(readiness, entries, category, context)
    if category == "curse" then
        return GetAfflictionCurseReadyEntries(self, readiness, entries, category, context)
    end

    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function Affliction:IsCategoryAllowed(category, context)
    if category == "curse" and IsAutoAgonyMode(self) then
        return not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.curseAgony })
    end

    local commonAllowed = Warlock:GetCommonCategoryAllowed(self, category, context)
    if commonAllowed ~= nil then
        return commonAllowed
    end

    if category == "corruption" then
        return not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.corruption, SPELL_IDS.seedOfCorruption })
            and HasEnoughTimeToBenefit(context, 8)
    end

    if category == "unstableAffliction" then
        return HasEnoughTimeToBenefit(context, 8)
    end

    if category == "haunt" then
        return HasEnoughTimeToBenefit(context, 4)
    end

    if category == "drainSoul" then
        return IsExecute(context)
    end

    if category == "seedOfCorruption" then
        local enemyCount = tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
        return enemyCount >= 4
            and not Warlock:HasOwnTargetAura({ SPELL_IDS.seedOfCorruption })
    end

    if category == "shadowBolt" then
        if IsMovementPriorityActive(self, context) then
            return HasShadowTrance()
        end

        if IsExecute(context) then
            return HasShadowTrance() or not Warlock:HasSpellCritDebuff()
        end
    end

    return true
end

function Affliction:GetPriority(context)
    local enemyCount = tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
    if enemyCount >= 4 and not IsMovementPriorityActive(self, context) then
        return PRIORITY_AOE
    end

    if IsMovementPriorityActive(self, context) then
        return PRIORITY_MOVING
    end

    if not Warlock:HasExternalMagicVulnerability() then
        return PRIORITY_NEEDS_ELEMENTS
    end

    if IsExecute(context) then
        if not Warlock:HasSpellCritDebuff() then
            return PRIORITY_EXECUTE_NEEDS_CRIT_DEBUFF
        end

        return PRIORITY_EXECUTE
    end

    if not Warlock:HasSpellCritDebuff() then
        return PRIORITY_NEEDS_CRIT_DEBUFF
    end

    return PRIORITY_NORMAL
end

function Affliction:GetDebugState()
    return "Execute="
        .. tostring(IsExecute({ target = addon.UnitStateService:GetTargetSnapshot() }))
        .. ", ShadowTrance="
        .. tostring(HasShadowTrance())
end

addon.SpecRegistry:Register(Affliction)
