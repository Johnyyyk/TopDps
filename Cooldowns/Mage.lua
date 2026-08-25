local addon = TopDps
local Mage = addon.Mage

addon.CooldownRegistry:RegisterProfile({ classToken = Mage.CLASS_TOKEN, talentTab = Mage.TALENT_TABS.ARCANE, labelKey = "SPEC_MAGE_ARCANE" })
addon.CooldownRegistry:RegisterProfile({ classToken = Mage.CLASS_TOKEN, talentTab = Mage.TALENT_TABS.FIRE, labelKey = "SPEC_MAGE_FIRE" })
addon.CooldownRegistry:RegisterProfile({ classToken = Mage.CLASS_TOKEN, talentTab = Mage.TALENT_TABS.FROST, labelKey = "SPEC_MAGE_FROST" })

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Mage.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "currentArmor",
                type = "aura",
                auraSpellIds = {
                    Mage.SPELL_IDS.moltenArmor,
                    Mage.SPELL_IDS.mageArmor,
                    Mage.SPELL_IDS.iceArmor,
                    Mage.SPELL_IDS.frostArmor,
                },
                displaySpellId = Mage.SPELL_IDS.moltenArmor,
                name = addon.L.MAGE_CURRENT_ARMOR,
                showDuration = false,
                group = addon.COOLDOWN_GROUP_STATES,
                panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_SELECTABLE_BUFF,
                order = 10,
            },
            { id = "mirrorImage", type = "spell", spellIds = { Mage.SPELL_IDS.mirrorImage }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
            { id = "evocation", type = "spell", spellIds = { Mage.SPELL_IDS.evocation }, group = addon.COOLDOWN_GROUP_RESOURCES, order = 10 },
            { id = "iceBlock", type = "spell", spellIds = { Mage.SPELL_IDS.iceBlock }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
            { id = "manaShield", type = "spell", spellIds = { Mage.SPELL_IDS.manaShield }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 20 },
            { id = "counterspell", type = "spell", spellIds = { Mage.SPELL_IDS.counterspell }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
            { id = "invisibility", type = "spell", spellIds = { Mage.SPELL_IDS.invisibility }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
        },
    })
end

RegisterCommonEntries(Mage.TALENT_TABS.ARCANE)
RegisterCommonEntries(Mage.TALENT_TABS.FIRE)
RegisterCommonEntries(Mage.TALENT_TABS.FROST)

addon.CooldownRegistry:Register({
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.ARCANE,
    entries = {
        { id = "arcanePower", type = "spell", spellIds = { Mage.SPELL_IDS.arcanePower }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "presenceOfMind", type = "spell", spellIds = { Mage.SPELL_IDS.presenceOfMind }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "missileBarrage", type = "aura", auraSpellIds = { Mage.SPELL_IDS.missileBarrage }, displaySpellId = Mage.SPELL_IDS.missileBarrage, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.FIRE,
    entries = {
        { id = "combustion", type = "spell", spellIds = { Mage.SPELL_IDS.combustion }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "hotStreak", type = "aura", auraSpellIds = { Mage.SPELL_IDS.hotStreak }, displaySpellId = Mage.SPELL_IDS.hotStreak, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
        { id = "firestarter", type = "aura", auraSpellIds = { Mage.SPELL_IDS.firestarter }, displaySpellId = Mage.SPELL_IDS.firestarter, defaultProcSoundEnabled = false, group = addon.COOLDOWN_GROUP_PROCS, order = 20 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Mage.CLASS_TOKEN,
    talentTab = Mage.TALENT_TABS.FROST,
    entries = {
        { id = "icyVeins", type = "spell", spellIds = { Mage.SPELL_IDS.icyVeins }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "coldSnap", type = "spell", spellIds = { Mage.SPELL_IDS.coldSnap }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "summonWaterElemental", type = "spell", spellIds = { Mage.SPELL_IDS.summonWaterElemental }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 40 },
        { id = "fingersOfFrost", type = "aura", auraSpellIds = { Mage.SPELL_IDS.fingersOfFrost }, displaySpellId = Mage.SPELL_IDS.fingersOfFrost, showStacks = true, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
        { id = "brainFreeze", type = "aura", auraSpellIds = { Mage.SPELL_IDS.brainFreeze }, displaySpellId = Mage.SPELL_IDS.brainFreeze, group = addon.COOLDOWN_GROUP_PROCS, order = 20 },
    },
})
