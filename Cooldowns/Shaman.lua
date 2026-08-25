local addon = TopDps
local Shaman = addon.Shaman

local MAIN_HAND_SLOT = 16
local OFF_HAND_SLOT = 17

addon.CooldownRegistry:RegisterProfile({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ELEMENTAL,
    labelKey = "SPEC_SHAMAN_ELEMENTAL",
})

addon.CooldownRegistry:RegisterProfile({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ENHANCEMENT,
    labelKey = "SPEC_SHAMAN_ENHANCEMENT",
})

addon.CooldownRegistry:RegisterProfile({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.RESTORATION,
    labelKey = "SPEC_SHAMAN_RESTORATION",
})

addon.CooldownRegistry:Register({
    classToken = Shaman.CLASS_TOKEN,
    entries = {
        {
            id = "bloodlustHeroism",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.bloodlust, Shaman.SPELL_IDS.heroism },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 90,
        },
        {
            id = "windShear",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.windShear },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 10,
        },
        {
            id = "tremorTotem",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.tremorTotem },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 20,
        },
        {
            id = "groundingTotem",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.groundingTotem },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 30,
        },
        {
            id = "fireTotem",
            type = "state",
            displaySpellId = Shaman.SPELL_IDS.callOfTheElements,
            name = addon.L.SHAMAN_FIRE_TOTEM_STATE,
            getState = function()
                return Shaman:GetFireTotemState()
            end,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_ABILITIES,
            panelBehavior = addon.PANEL_BEHAVIOR_ALWAYS,
            order = 90,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ELEMENTAL,
    entries = {
        {
            id = "weaponImbue",
            type = "state",
            displaySpellId = Shaman.SPELL_IDS.flametongueWeapon,
            name = addon.L.SHAMAN_FLAMETONGUE_STATE,
            getState = function()
                return Shaman:GetWeaponImbueState(
                    MAIN_HAND_SLOT,
                    Shaman.SPELL_IDS.flametongueWeapon,
                    Shaman.WEAPON_ENCHANT_SPELL_IDS.flametongue
                )
            end,
            order = 10,
        },
        {
            id = "waterShield",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.waterShield },
            displaySpellId = Shaman.SPELL_IDS.waterShield,
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 20,
        },
        {
            id = "elementalMastery",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.elementalMastery },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "thunderstorm",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.thunderstorm },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 40,
        },
        {
            id = "elementalFocus",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.elementalFocus },
            displaySpellId = Shaman.SPELL_IDS.elementalFocus,
            defaultProcSoundEnabled = false,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.ENHANCEMENT,
    entries = {
        {
            id = "mainHandWindfury",
            type = "state",
            displaySpellId = Shaman.SPELL_IDS.windfuryWeapon,
            name = addon.L.SHAMAN_WINDFURY_STATE,
            getState = function()
                return Shaman:GetWeaponImbueState(
                    MAIN_HAND_SLOT,
                    Shaman.SPELL_IDS.windfuryWeapon,
                    Shaman.WEAPON_ENCHANT_SPELL_IDS.windfury
                )
            end,
            order = 10,
        },
        {
            id = "offHandFlametongue",
            type = "state",
            displaySpellId = Shaman.SPELL_IDS.flametongueWeapon,
            name = addon.L.SHAMAN_FLAMETONGUE_OFFHAND_STATE,
            getState = function()
                return Shaman:GetWeaponImbueState(
                    OFF_HAND_SLOT,
                    Shaman.SPELL_IDS.flametongueWeapon,
                    Shaman.WEAPON_ENCHANT_SPELL_IDS.flametongue
                )
            end,
            order = 20,
        },
        {
            id = "lightningShield",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.lightningShield },
            displaySpellId = Shaman.SPELL_IDS.lightningShield,
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 30,
        },
        {
            id = "feralSpirit",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.feralSpirit },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "shamanisticRage",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.shamanisticRage },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 10,
        },
        {
            id = "maelstromWeapon",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.maelstromWeapon },
            displaySpellId = Shaman.SPELL_IDS.maelstromWeapon,
            showStacks = true,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Shaman.CLASS_TOKEN,
    talentTab = Shaman.TALENT_TABS.RESTORATION,
    entries = {
        {
            id = "weaponImbue",
            type = "state",
            displaySpellId = Shaman.SPELL_IDS.earthlivingWeapon,
            name = addon.L.SHAMAN_EARTHLIVING_STATE,
            getState = function()
                return Shaman:GetWeaponImbueState(
                    MAIN_HAND_SLOT,
                    Shaman.SPELL_IDS.earthlivingWeapon,
                    Shaman.WEAPON_ENCHANT_SPELL_IDS.earthliving
                )
            end,
            order = 10,
        },
        {
            id = "waterShield",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.waterShield },
            displaySpellId = Shaman.SPELL_IDS.waterShield,
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 20,
        },
        {
            id = "earthShield",
            type = "aura",
            auraSpellIds = { 974, 32593, 32594, 49283, 49284 },
            displaySpellId = 49284,
            requiredSpellIds = { Shaman.SPELL_IDS.earthShield },
            auraUnit = "group",
            auraFilter = "HELPFUL",
            ownOnly = true,
            showStacks = true,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 30,
        },
        {
            id = "natureSwiftness",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.natureSwiftness },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 10,
        },
        {
            id = "manaTide",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.manaTide },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 40,
        },
        {
            id = "tidalForce",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.tidalForce },
            group = addon.COOLDOWN_GROUP_DEFENSIVE,
            order = 20,
        },
        {
            id = "riptide",
            type = "spell",
            spellIds = { Shaman.SPELL_IDS.riptide },
            group = addon.COOLDOWN_GROUP_UTILITY,
            order = 50,
        },
        {
            id = "tidalWaves",
            type = "aura",
            auraSpellIds = { Shaman.SPELL_IDS.tidalWaves },
            displaySpellId = Shaman.SPELL_IDS.tidalWaves,
            showStacks = true,
            defaultProcSoundEnabled = false,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
    },
})
