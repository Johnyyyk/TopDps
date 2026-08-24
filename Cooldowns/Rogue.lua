local addon = TopDps
local Rogue = addon.Rogue

addon.CooldownRegistry:RegisterProfile({ classToken = Rogue.CLASS_TOKEN, talentTab = Rogue.TALENT_TABS.ASSASSINATION, labelKey = "SPEC_ROGUE_ASSASSINATION" })
addon.CooldownRegistry:RegisterProfile({ classToken = Rogue.CLASS_TOKEN, talentTab = Rogue.TALENT_TABS.COMBAT, labelKey = "SPEC_ROGUE_COMBAT" })
addon.CooldownRegistry:RegisterProfile({ classToken = Rogue.CLASS_TOKEN, talentTab = Rogue.TALENT_TABS.SUBTLETY, labelKey = "SPEC_ROGUE_SUBTLETY" })

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Rogue.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "poisons",
                type = "state",
                displaySpellId = Rogue.SPELL_IDS.deadlyPoison,
                name = addon.L.ROGUE_POISONS_STATE,
                getState = function()
                    return Rogue:GetWeaponPoisonState()
                end,
                group = addon.COOLDOWN_GROUP_STATES,
                panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_STATE,
                order = 10,
            },
            { id = "tricksOfTheTrade", type = "spell", spellIds = { Rogue.SPELL_IDS.tricksOfTheTrade }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
            { id = "kick", type = "spell", spellIds = { Rogue.SPELL_IDS.kick }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
            { id = "vanish", type = "spell", spellIds = { Rogue.SPELL_IDS.vanish }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
            { id = "cloakOfShadows", type = "spell", spellIds = { Rogue.SPELL_IDS.cloakOfShadows }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
            { id = "evasion", type = "spell", spellIds = { Rogue.SPELL_IDS.evasion }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 20 },
            { id = "sprint", type = "spell", spellIds = { Rogue.SPELL_IDS.sprint }, group = addon.COOLDOWN_GROUP_UTILITY, order = 40 },
        },
    })
end

RegisterCommonEntries(Rogue.TALENT_TABS.ASSASSINATION)
RegisterCommonEntries(Rogue.TALENT_TABS.COMBAT)
RegisterCommonEntries(Rogue.TALENT_TABS.SUBTLETY)

addon.CooldownRegistry:Register({
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.ASSASSINATION,
    entries = {
        { id = "coldBlood", type = "spell", spellIds = { Rogue.SPELL_IDS.coldBlood }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
        { id = "overkill", type = "aura", auraSpellIds = { Rogue.SPELL_IDS.overkill }, displaySpellId = Rogue.SPELL_IDS.overkill, defaultProcSoundEnabled = false, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.COMBAT,
    entries = {
        { id = "bladeFlurry", type = "spell", spellIds = { Rogue.SPELL_IDS.bladeFlurry }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
        { id = "adrenalineRush", type = "spell", spellIds = { Rogue.SPELL_IDS.adrenalineRush }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "killingSpree", type = "spell", spellIds = { Rogue.SPELL_IDS.killingSpree }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Rogue.CLASS_TOKEN,
    talentTab = Rogue.TALENT_TABS.SUBTLETY,
    entries = {
        { id = "shadowDance", type = "spell", spellIds = { Rogue.SPELL_IDS.shadowDance }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
        { id = "premeditation", type = "spell", spellIds = { Rogue.SPELL_IDS.premeditation }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
        { id = "shadowstep", type = "spell", spellIds = { Rogue.SPELL_IDS.shadowstep }, group = addon.COOLDOWN_GROUP_UTILITY, order = 50 },
        { id = "preparation", type = "spell", spellIds = { Rogue.SPELL_IDS.preparation }, group = addon.COOLDOWN_GROUP_UTILITY, order = 60 },
    },
})
