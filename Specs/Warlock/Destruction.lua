local addon = TopDps
local Warlock = addon.Warlock

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
    },

    settings = {
        Warlock:CreateCurseSetting(),
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

function Destruction:GetReadyEntries(readiness, entries, category, context)
    if category == "curse" then
        return Warlock:GetCurseReadyEntries(self, readiness, entries, category, context)
    end

    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function Destruction:IsCategoryAllowed(category)
    local commonAllowed = Warlock:GetCommonCategoryAllowed(self, category)
    if commonAllowed ~= nil then
        return commonAllowed
    end

    if category == "conflagrate" then
        return Warlock:HasOwnTargetAura({ Warlock.SPELL_IDS.immolate })
    end

    return true
end

function Destruction:GetPriority()
    return PRIORITY
end

addon.SpecRegistry:Register(Destruction)
