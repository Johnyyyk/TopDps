local addon = TopDps
local Druid = addon.Druid

addon.CooldownRegistry:RegisterProfile({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.BALANCE,
    labelKey = "SPEC_DRUID_BALANCE",
})

addon.CooldownRegistry:RegisterProfile({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.FERAL,
    labelKey = "SPEC_DRUID_FERAL",
})

addon.CooldownRegistry:RegisterProfile({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.RESTORATION,
    labelKey = "SPEC_DRUID_RESTORATION",
})

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Druid.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "barkskin",
                type = "spell",
                spellIds = { Druid.SPELL_IDS.barkskin },
                group = addon.COOLDOWN_GROUP_DEFENSIVE,
                order = 10,
            },
            {
                id = "innervate",
                type = "spell",
                spellIds = { Druid.SPELL_IDS.innervate },
                group = addon.COOLDOWN_GROUP_UTILITY,
                order = 10,
            },
            {
                id = "rebirth",
                type = "spell",
                spellIds = { Druid.SPELL_IDS.rebirth },
                group = addon.COOLDOWN_GROUP_UTILITY,
                order = 20,
            },
        },
    })
end

RegisterCommonEntries(Druid.TALENT_TABS.BALANCE)
RegisterCommonEntries(Druid.TALENT_TABS.FERAL)
RegisterCommonEntries(Druid.TALENT_TABS.RESTORATION)

addon.CooldownRegistry:Register({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.BALANCE,
    entries = {
        {
            id = "moonkinForm",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.moonkinForm },
            displaySpellId = Druid.SPELL_IDS.moonkinForm,
            requiredSpellIds = { Druid.SPELL_IDS.moonkinForm },
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 10,
        },
        {
            id = "starfall",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.starfall },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "forceOfNature",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.forceOfNature },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 20,
        },
        {
            id = "solarEclipse",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.solarEclipse },
            displaySpellId = Druid.SPELL_IDS.solarEclipse,
            defaultProcSoundEnabled = false,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
        {
            id = "lunarEclipse",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.lunarEclipse },
            displaySpellId = Druid.SPELL_IDS.lunarEclipse,
            defaultProcSoundEnabled = false,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 20,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.FERAL,
    entries = {
        {
            id = "tigersFury",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.tigersFury },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "berserk",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.berserk },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 20,
        },
        {
            id = "survivalInstincts",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.survivalInstincts },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 20,
        },
        {
            id = "frenziedRegeneration",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.frenziedRegeneration },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 30,
        },
        {
            id = "dash",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.dash },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 30,
        },
        {
            id = "clearcasting",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.clearcasting },
            displaySpellId = Druid.SPELL_IDS.clearcasting,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Druid.CLASS_TOKEN,
    talentTab = Druid.TALENT_TABS.RESTORATION,
    entries = {
        {
            id = "treeOfLife",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.treeOfLife },
            displaySpellId = Druid.SPELL_IDS.treeOfLife,
            requiredSpellIds = { Druid.SPELL_IDS.treeOfLife },
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 10,
        },
        {
            id = "naturesSwiftness",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.naturesSwiftness },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 30,
        },
        {
            id = "swiftmend",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.swiftmend },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 40,
        },
        {
            id = "wildGrowth",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.wildGrowth },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 50,
        },
        {
            id = "tranquility",
            type = "spell",
            spellIds = { Druid.SPELL_IDS.tranquility },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 60,
        },
        {
            id = "clearcasting",
            type = "aura",
            auraSpellIds = { Druid.SPELL_IDS.clearcasting },
            displaySpellId = Druid.SPELL_IDS.clearcasting,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
    },
})
