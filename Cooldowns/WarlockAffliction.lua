local addon = TopDps
local Warlock = addon.Warlock

local SHADOW_WARD_SPELL_IDS = { 6229, 11739, 11740, 28610, 47890, 47891 }
local DEATH_COIL_SPELL_IDS = { 6789, 17925, 17926, 27223, 47859, 47860 }
local SOULSHATTER_SPELL_IDS = { 29858 }
local DEMONIC_CIRCLE_TELEPORT_SPELL_IDS = { 48020 }
local HOWL_OF_TERROR_SPELL_IDS = { 5484, 17928 }
local INFERNO_SPELL_IDS = { 1122 }

local SUMMON_FELHUNTER_SPELL_ID = 691
local SHADOW_BITE_SPELL_ID = 54049
local SHADOW_TRANCE_AURA_ID = 17941
local ERADICATION_TALENT_IDS = { 47195, 47196, 47197 }
local ERADICATION_AURA_IDS = { 64368, 64370, 64371 }

addon.CooldownRegistry:RegisterProfile({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.AFFLICTION,
    labelKey = "SPEC_WARLOCK_AFFLICTION",
})

addon.CooldownRegistry:Register({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.AFFLICTION,
    entries = {
        {
            id = "felArmor",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.felArmor },
            displaySpellId = Warlock.SPELL_IDS.felArmor,
            requiredSpellIds = { Warlock.SPELL_IDS.felArmor },
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 10,
        },
        {
            id = "glyphLifeTap",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.glyphLifeTapBuff },
            displaySpellId = Warlock.SPELL_IDS.glyphLifeTapBuff,
            name = addon.L.WARLOCK_GLYPH_LIFE_TAP_STATE,
            isApplicable = function()
                return Warlock:HasGlyphLifeTap()
            end,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 20,
        },
        {
            id = "correctPet",
            type = "state",
            displaySpellId = SUMMON_FELHUNTER_SPELL_ID,
            name = addon.L.WARLOCK_FELHUNTER_STATE,
            isApplicable = function()
                return Warlock:IsPetRequirementApplicable()
            end,
            getState = function()
                return {
                    active = Warlock:HasPetSpell(SHADOW_BITE_SPELL_ID),
                    spellId = SUMMON_FELHUNTER_SPELL_ID,
                }
            end,
            order = 30,
        },
        {
            id = "weaponStone",
            type = "state",
            displaySpellId = Warlock.SPELL_IDS.grandSpellstone,
            name = addon.L.WARLOCK_SPELLSTONE_STATE,
            getState = function()
                return Warlock:GetWeaponStoneState(
                    Warlock.SPELL_IDS.grandSpellstone,
                    Warlock.WEAPON_ENCHANT_SPELL_IDS.spellstone
                )
            end,
            order = 40,
        },
        {
            id = "inferno",
            type = "spell",
            spellIds = INFERNO_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 90,
        },
        {
            id = "shadowWard",
            type = "spell",
            spellIds = SHADOW_WARD_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 10,
        },
        {
            id = "deathCoil",
            type = "spell",
            spellIds = DEATH_COIL_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 20,
        },
        {
            id = "soulshatter",
            type = "spell",
            spellIds = SOULSHATTER_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 10,
        },
        {
            id = "demonicCircleTeleport",
            type = "spell",
            spellIds = DEMONIC_CIRCLE_TELEPORT_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 20,
        },
        {
            id = "howlOfTerror",
            type = "spell",
            spellIds = HOWL_OF_TERROR_SPELL_IDS,
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 30,
        },
        {
            id = "shadowTrance",
            type = "aura",
            auraSpellIds = { SHADOW_TRANCE_AURA_ID },
            displaySpellId = SHADOW_TRANCE_AURA_ID,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
        {
            id = "eradication",
            type = "aura",
            auraSpellIds = ERADICATION_AURA_IDS,
            displaySpellId = ERADICATION_AURA_IDS[#ERADICATION_AURA_IDS],
            requiredTalentSpellIds = ERADICATION_TALENT_IDS,
            requiredTalentTab = Warlock.TALENT_TABS.AFFLICTION,
            defaultProcSoundEnabled = false,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 20,
        },
    },
})
