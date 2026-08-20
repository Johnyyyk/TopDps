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

function Demonology:GetReadyEntries(readiness, entries, category, context)
    if category == "curse" then
        return Warlock:GetCurseReadyEntries(self, readiness, entries, category, context)
    end

    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function Demonology:IsCategoryAllowed(category)
    local commonAllowed = Warlock:GetCommonCategoryAllowed(self, category)
    if commonAllowed ~= nil then
        return commonAllowed
    end

    if category == "corruption" then
        return not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.corruption })
    end

    if category == "immolate" then
        return not Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.immolate })
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

function Demonology:GetPriority()
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
