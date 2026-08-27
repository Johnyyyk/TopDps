local addon = TopDps
local Warrior = addon.Warrior

addon.CooldownRegistry:RegisterProfile({ classToken = Warrior.CLASS_TOKEN, talentTab = Warrior.TALENT_TABS.ARMS, labelKey = "SPEC_WARRIOR_ARMS" })
addon.CooldownRegistry:RegisterProfile({ classToken = Warrior.CLASS_TOKEN, talentTab = Warrior.TALENT_TABS.FURY, labelKey = "SPEC_WARRIOR_FURY" })
addon.CooldownRegistry:RegisterProfile({ classToken = Warrior.CLASS_TOKEN, talentTab = Warrior.TALENT_TABS.PROTECTION, labelKey = "SPEC_WARRIOR_PROTECTION" })

addon.CooldownRegistry:Register({
    classToken = Warrior.CLASS_TOKEN,
    entries = {
        {
            id = "currentShout",
            type = "aura",
            auraSpellIds = { Warrior.SPELL_IDS.battleShout, Warrior.SPELL_IDS.commandingShout },
            displaySpellId = Warrior.SPELL_IDS.battleShout,
            name = addon.L.WARRIOR_CURRENT_SHOUT,
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_ACTIVE_ONLY,
            order = 10,
        },
        { id = "berserkerRage", type = "spell", spellIds = { Warrior.SPELL_IDS.berserkerRage }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 40 },
        { id = "enragedRegeneration", type = "spell", spellIds = { Warrior.SPELL_IDS.enragedRegeneration }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 50 },
        { id = "pummel", type = "spell", spellIds = { Warrior.SPELL_IDS.pummel }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
        { id = "intervene", type = "spell", spellIds = { Warrior.SPELL_IDS.intervene }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
        { id = "challengingShout", type = "spell", spellIds = { Warrior.SPELL_IDS.challengingShout }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.ARMS,
    entries = {
        { id = "correctStance", type = "state", displaySpellId = Warrior.SPELL_IDS.battleStance, name = addon.L.WARRIOR_BATTLE_STANCE_STATE, getState = function() return Warrior:GetRequiredStanceState(Warrior.SPELL_IDS.battleStance) end, order = 20 },
        { id = "bladestorm", type = "spell", spellIds = { Warrior.SPELL_IDS.bladestorm }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
        { id = "sweepingStrikes", type = "spell", spellIds = { Warrior.SPELL_IDS.sweepingStrikes }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "recklessness", type = "spell", spellIds = { Warrior.SPELL_IDS.recklessness }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "tasteForBlood", type = "aura", auraSpellIds = { Warrior.SPELL_IDS.tasteForBlood }, displaySpellId = Warrior.SPELL_IDS.tasteForBlood, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
        { id = "suddenDeath", type = "aura", auraSpellIds = { Warrior.SPELL_IDS.suddenDeath }, displaySpellId = Warrior.SPELL_IDS.suddenDeath, group = addon.COOLDOWN_GROUP_PROCS, order = 20 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.FURY,
    entries = {
        { id = "correctStance", type = "state", displaySpellId = Warrior.SPELL_IDS.berserkerStance, name = addon.L.WARRIOR_BERSERKER_STANCE_STATE, getState = function() return Warrior:GetRequiredStanceState(Warrior.SPELL_IDS.berserkerStance) end, order = 20 },
        { id = "deathWish", type = "spell", spellIds = { Warrior.SPELL_IDS.deathWish }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
        { id = "recklessness", type = "spell", spellIds = { Warrior.SPELL_IDS.recklessness }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "bloodsurge", type = "aura", auraSpellIds = { Warrior.SPELL_IDS.bloodsurge }, displaySpellId = Warrior.SPELL_IDS.bloodsurge, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Warrior.CLASS_TOKEN,
    talentTab = Warrior.TALENT_TABS.PROTECTION,
    entries = {
        { id = "correctStance", type = "state", displaySpellId = Warrior.SPELL_IDS.defensiveStance, name = addon.L.WARRIOR_DEFENSIVE_STANCE_STATE, getState = function() return Warrior:GetRequiredStanceState(Warrior.SPELL_IDS.defensiveStance) end, order = 20 },
        { id = "shieldWall", type = "spell", spellIds = { Warrior.SPELL_IDS.shieldWall }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
        { id = "lastStand", type = "spell", spellIds = { Warrior.SPELL_IDS.lastStand }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 20 },
        { id = "shieldBlock", type = "spell", spellIds = { Warrior.SPELL_IDS.shieldBlock }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 30 },
        { id = "spellReflection", type = "spell", spellIds = { Warrior.SPELL_IDS.spellReflection }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 60 },
        { id = "shieldBash", type = "spell", spellIds = { 72, 1671, 1672 }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
        { id = "taunt", type = "spell", spellIds = { Warrior.SPELL_IDS.taunt }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
        { id = "shieldSlam", type = "spell", spellIds = { Warrior.SPELL_IDS.shieldSlam }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
        { id = "shockwave", type = "spell", spellIds = { Warrior.SPELL_IDS.shockwave }, group = addon.COOLDOWN_GROUP_UTILITY, order = 40 },
        {
            id = "swordAndBoard",
            type = "aura",
            auraSpellIds = { Warrior.SPELL_IDS.swordAndBoard },
            displaySpellId = Warrior.SPELL_IDS.swordAndBoard,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
        {
            id = "vigilance",
            type = "aura",
            auraSpellIds = { Warrior.SPELL_IDS.vigilance },
            displaySpellId = Warrior.SPELL_IDS.vigilance,
            requiredSpellIds = { Warrior.SPELL_IDS.vigilance },
            auraUnit = "group",
            auraFilter = "HELPFUL",
            ownOnly = true,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 30,
        },
    },
})
