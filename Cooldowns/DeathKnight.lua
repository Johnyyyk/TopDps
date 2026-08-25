local addon = TopDps
local DeathKnight = addon.DeathKnight
local KILLING_MACHINE_TALENT_IDS = { 51123, 51127, 51128, 51129, 51130 }
local RIME_TALENT_IDS = { 49188, 56822, 59057 }

addon.CooldownRegistry:RegisterProfile({ classToken = DeathKnight.CLASS_TOKEN, talentTab = DeathKnight.TALENT_TABS.BLOOD, labelKey = "SPEC_DEATHKNIGHT_BLOOD" })
addon.CooldownRegistry:RegisterProfile({ classToken = DeathKnight.CLASS_TOKEN, talentTab = DeathKnight.TALENT_TABS.FROST, labelKey = "SPEC_DEATHKNIGHT_FROST" })
addon.CooldownRegistry:RegisterProfile({ classToken = DeathKnight.CLASS_TOKEN, talentTab = DeathKnight.TALENT_TABS.UNHOLY, labelKey = "SPEC_DEATHKNIGHT_UNHOLY" })

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = DeathKnight.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "currentPresence", type = "aura",
                auraSpellIds = { DeathKnight.SPELL_IDS.bloodPresence, DeathKnight.SPELL_IDS.frostPresence, DeathKnight.SPELL_IDS.unholyPresence },
                displaySpellId = DeathKnight.SPELL_IDS.bloodPresence, name = addon.L.DEATHKNIGHT_CURRENT_PRESENCE,
                showDuration = false, group = addon.COOLDOWN_GROUP_STATES, panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_SELECTABLE_BUFF, order = 10,
            },
            {
                id = "hornOfWinter", type = "aura", auraSpellIds = { 57330, 57623 }, displaySpellId = 57623,
                requiredSpellIds = { DeathKnight.SPELL_IDS.hornOfWinter }, showDuration = true,
                group = addon.COOLDOWN_GROUP_STATES, panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_SELECTABLE_BUFF, order = 20,
            },
            { id = "empowerRuneWeapon", type = "spell", spellIds = { DeathKnight.SPELL_IDS.empowerRuneWeapon }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
            { id = "armyOfTheDead", type = "spell", spellIds = { DeathKnight.SPELL_IDS.armyOfTheDead }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 90 },
            { id = "antiMagicShell", type = "spell", spellIds = { DeathKnight.SPELL_IDS.antiMagicShell }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
            { id = "iceboundFortitude", type = "spell", spellIds = { DeathKnight.SPELL_IDS.iceboundFortitude }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 20 },
            { id = "mindFreeze", type = "spell", spellIds = { DeathKnight.SPELL_IDS.mindFreeze }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
        },
    })
end
RegisterCommonEntries(DeathKnight.TALENT_TABS.BLOOD)
RegisterCommonEntries(DeathKnight.TALENT_TABS.FROST)
RegisterCommonEntries(DeathKnight.TALENT_TABS.UNHOLY)

addon.CooldownRegistry:Register({
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.BLOOD,
    entries = {
        { id = "dancingRuneWeapon", type = "spell", spellIds = { DeathKnight.SPELL_IDS.dancingRuneWeapon }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "hysteria", type = "spell", spellIds = { DeathKnight.SPELL_IDS.hysteria }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "raiseDead", type = "spell", spellIds = { DeathKnight.SPELL_IDS.raiseDead }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 40 },
        { id = "vampiricBlood", type = "spell", spellIds = { DeathKnight.SPELL_IDS.vampiricBlood }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 30 },
        { id = "runeTap", type = "spell", spellIds = { DeathKnight.SPELL_IDS.runeTap }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 40 },
    },
})

addon.CooldownRegistry:Register({
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.FROST,
    entries = {
        { id = "unbreakableArmor", type = "spell", spellIds = { DeathKnight.SPELL_IDS.unbreakableArmor }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "raiseDead", type = "spell", spellIds = { DeathKnight.SPELL_IDS.raiseDead }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 40 },
        { id = "hungeringCold", type = "spell", spellIds = { DeathKnight.SPELL_IDS.hungeringCold }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
        { id = "killingMachine", type = "aura", auraSpellIds = { DeathKnight.SPELL_IDS.killingMachine }, displaySpellId = DeathKnight.SPELL_IDS.killingMachine, requiredTalentSpellIds = KILLING_MACHINE_TALENT_IDS, requiredTalentTab = DeathKnight.TALENT_TABS.FROST, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
        { id = "rime", type = "aura", auraSpellIds = { DeathKnight.SPELL_IDS.freezingFog }, displaySpellId = DeathKnight.SPELL_IDS.freezingFog, requiredTalentSpellIds = RIME_TALENT_IDS, requiredTalentTab = DeathKnight.TALENT_TABS.FROST, group = addon.COOLDOWN_GROUP_PROCS, order = 20 },
    },
})

addon.CooldownRegistry:Register({
    classToken = DeathKnight.CLASS_TOKEN,
    talentTab = DeathKnight.TALENT_TABS.UNHOLY,
    entries = {
        {
            id = "ghoulAlive", type = "state", displaySpellId = DeathKnight.SPELL_IDS.raiseDead,
            name = addon.L.DEATHKNIGHT_GHOUL_STATE, requiredTalentSpellIds = { DeathKnight.SPELL_IDS.masterOfGhouls },
            requiredTalentTab = DeathKnight.TALENT_TABS.UNHOLY,
            getState = function() return DeathKnight:GetPermanentGhoulState() end,
            order = 30,
        },
        { id = "summonGargoyle", type = "spell", spellIds = { DeathKnight.SPELL_IDS.summonGargoyle }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "boneShield", type = "spell", spellIds = { DeathKnight.SPELL_IDS.boneShield }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 30 },
        { id = "antiMagicZone", type = "spell", spellIds = { DeathKnight.SPELL_IDS.antiMagicZone }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 40 },
    },
})
