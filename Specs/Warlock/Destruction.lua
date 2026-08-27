local addon = TopDps
local Warlock = addon.Warlock
local BACKLASH_PROC_SPELL_ID = 34936

local Destruction = addon.SpecProvider:Create({
    id = "WARLOCK_DESTRUCTION",
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DESTRUCTION,

    categories = {
        "lifeTap",
        "curse",
        "immolate",
        "conflagrate",
        "chaosBolt",
        "incinerate",
        "corruption",
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
        conflagrate = {
            spellIds = { Warlock.SPELL_IDS.conflagrate },
        },
        chaosBolt = {
            spellIds = { Warlock.SPELL_IDS.chaosBolt },
        },
        incinerate = {
            spellIds = { Warlock.SPELL_IDS.incinerate },
        },
        corruption = {
            spellIds = { Warlock.SPELL_IDS.corruption },
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

local PRIORITY = {
    "lifeTap",
    "curse",
    "immolate",
    "conflagrate",
    "chaosBolt",
    "incinerate",
}

local PRIORITY_MOVING = {
    "lifeTap",
    "curse",
    "conflagrate",
    "incinerate",
    "corruption",
}

local function IsMovementPriorityActive(provider, context)
    return provider:GetSetting("useMovementPriority") ~= false
        and context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
end

function Destruction:GetReadyEntries(readiness, entries, category, context)
    if category == "curse" then
        return Warlock:GetCurseReadyEntries(self, readiness, entries, category, context)
    end

    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function Destruction:IsCategoryAllowed(category, context)
    local commonAllowed = Warlock:GetCommonCategoryAllowed(self, category, context)
    if commonAllowed ~= nil then
        return commonAllowed
    end

    if category == "conflagrate" then
        return Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.immolate })
    end

    if category == "incinerate" and IsMovementPriorityActive(self, context) then
        return Warlock:HasPlayerAura({ BACKLASH_PROC_SPELL_ID })
    end

    if category == "corruption" then
        return IsMovementPriorityActive(self, context)
            and not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.corruption })
    end

    return true
end

function Destruction:GetPriority(context)
    if IsMovementPriorityActive(self, context) then
        return PRIORITY_MOVING
    end

    return PRIORITY
end

addon.SpecRegistry:Register(Destruction)
