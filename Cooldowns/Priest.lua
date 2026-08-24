local addon = TopDps
local Priest = addon.Priest

addon.CooldownRegistry:RegisterProfile({ classToken = Priest.CLASS_TOKEN, talentTab = Priest.TALENT_TABS.DISCIPLINE, labelKey = "SPEC_PRIEST_DISCIPLINE" })
addon.CooldownRegistry:RegisterProfile({ classToken = Priest.CLASS_TOKEN, talentTab = Priest.TALENT_TABS.HOLY, labelKey = "SPEC_PRIEST_HOLY" })
addon.CooldownRegistry:RegisterProfile({ classToken = Priest.CLASS_TOKEN, talentTab = Priest.TALENT_TABS.SHADOW, labelKey = "SPEC_PRIEST_SHADOW" })

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Priest.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "innerFire",
                type = "aura",
                auraSpellIds = { Priest.SPELL_IDS.innerFire },
                displaySpellId = Priest.SPELL_IDS.innerFire,
                requiredSpellIds = { Priest.SPELL_IDS.innerFire },
                showDuration = false,
                showStacks = false,
                group = addon.COOLDOWN_GROUP_STATES,
                panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
                order = 10,
            },
            { id = "shadowfiend", type = "spell", spellIds = { Priest.SPELL_IDS.shadowfiend }, group = addon.COOLDOWN_GROUP_RESOURCES, order = 10 },
            { id = "hymnOfHope", type = "spell", spellIds = { Priest.SPELL_IDS.hymnOfHope }, group = addon.COOLDOWN_GROUP_RESOURCES, order = 20 },
            { id = "divineHymn", type = "spell", spellIds = { Priest.SPELL_IDS.divineHymn }, group = addon.COOLDOWN_GROUP_UTILITY, order = 80 },
        },
    })
end

RegisterCommonEntries(Priest.TALENT_TABS.DISCIPLINE)
RegisterCommonEntries(Priest.TALENT_TABS.HOLY)
RegisterCommonEntries(Priest.TALENT_TABS.SHADOW)

addon.CooldownRegistry:Register({
    classToken = Priest.CLASS_TOKEN,
    talentTab = Priest.TALENT_TABS.DISCIPLINE,
    entries = {
        { id = "powerInfusion", type = "spell", spellIds = { Priest.SPELL_IDS.powerInfusion }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
        { id = "painSuppression", type = "spell", spellIds = { Priest.SPELL_IDS.painSuppression }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
        { id = "penance", type = "spell", spellIds = { Priest.SPELL_IDS.penance }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
        { id = "prayerOfMending", type = "spell", spellIds = { Priest.SPELL_IDS.prayerOfMending }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
        { id = "innerFocus", type = "spell", spellIds = { Priest.SPELL_IDS.innerFocus }, group = addon.COOLDOWN_GROUP_UTILITY, order = 40 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Priest.CLASS_TOKEN,
    talentTab = Priest.TALENT_TABS.HOLY,
    entries = {
        { id = "guardianSpirit", type = "spell", spellIds = { Priest.SPELL_IDS.guardianSpirit }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
        { id = "circleOfHealing", type = "spell", spellIds = { Priest.SPELL_IDS.circleOfHealing }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
        { id = "prayerOfMending", type = "spell", spellIds = { Priest.SPELL_IDS.prayerOfMending }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
        { id = "innerFocus", type = "spell", spellIds = { Priest.SPELL_IDS.innerFocus }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Priest.CLASS_TOKEN,
    talentTab = Priest.TALENT_TABS.SHADOW,
    entries = {
        {
            id = "shadowform",
            type = "aura",
            auraSpellIds = { Priest.SPELL_IDS.shadowform },
            displaySpellId = Priest.SPELL_IDS.shadowform,
            requiredSpellIds = { Priest.SPELL_IDS.shadowform },
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 20,
        },
        {
            id = "vampiricEmbrace",
            type = "aura",
            auraSpellIds = { Priest.SPELL_IDS.vampiricEmbrace },
            displaySpellId = Priest.SPELL_IDS.vampiricEmbrace,
            requiredSpellIds = { Priest.SPELL_IDS.vampiricEmbrace },
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 30,
        },
        { id = "dispersion", type = "spell", spellIds = { Priest.SPELL_IDS.dispersion }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
        { id = "silence", type = "spell", spellIds = { Priest.SPELL_IDS.silence }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
    },
})
