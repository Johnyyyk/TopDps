local addon = TopDps
local Hunter = addon.Hunter

addon.CooldownRegistry:RegisterProfile({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.BEAST_MASTERY,
    labelKey = "SPEC_HUNTER_BEAST_MASTERY",
})
addon.CooldownRegistry:RegisterProfile({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.MARKSMANSHIP,
    labelKey = "SPEC_HUNTER_MARKSMANSHIP",
})
addon.CooldownRegistry:RegisterProfile({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.SURVIVAL,
    labelKey = "SPEC_HUNTER_SURVIVAL",
})

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Hunter.CLASS_TOKEN,
        talentTab = talentTab,
        entries = {
            {
                id = "petAlive",
                type = "state",
                displaySpellId = Hunter.SPELL_IDS.callPet,
                name = addon.L.HUNTER_PET_STATE,
                getState = function()
                    return {
                        active = Hunter:IsPetAlive(),
                        spellId = Hunter.SPELL_IDS.callPet,
                    }
                end,
                order = 10,
            },
            {
                id = "currentAspect",
                type = "aura",
                auraSpellIds = {
                    Hunter.SPELL_IDS.aspectDragonhawk,
                    Hunter.SPELL_IDS.aspectHawk,
                    Hunter.SPELL_IDS.aspectViper,
                    Hunter.SPELL_IDS.aspectMonkey,
                    Hunter.SPELL_IDS.aspectCheetah,
                    Hunter.SPELL_IDS.aspectPack,
                    Hunter.SPELL_IDS.aspectWild,
                    Hunter.SPELL_IDS.aspectBeast,
                },
                displaySpellId = Hunter.SPELL_IDS.aspectDragonhawk,
                name = addon.L.HUNTER_CURRENT_ASPECT,
                showDuration = false,
                group = addon.COOLDOWN_GROUP_STATES,
                panelCategory = addon.PANEL_CATEGORY_BUFFS,
                panelBehavior = addon.PANEL_BEHAVIOR_SELECTABLE_BUFF,
                order = 20,
            },
            { id = "rapidFire", type = "spell", spellIds = { Hunter.SPELL_IDS.rapidFire }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 10 },
            { id = "killCommand", type = "spell", spellIds = { Hunter.SPELL_IDS.killCommand }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 20 },
            { id = "deterrence", type = "spell", spellIds = { Hunter.SPELL_IDS.deterrence }, group = addon.COOLDOWN_GROUP_DEFENSIVE, order = 10 },
            { id = "disengage", type = "spell", spellIds = { Hunter.SPELL_IDS.disengage }, group = addon.COOLDOWN_GROUP_UTILITY, order = 10 },
            { id = "feignDeath", type = "spell", spellIds = { Hunter.SPELL_IDS.feignDeath }, group = addon.COOLDOWN_GROUP_UTILITY, order = 20 },
            { id = "misdirection", type = "spell", spellIds = { Hunter.SPELL_IDS.misdirection }, group = addon.COOLDOWN_GROUP_UTILITY, order = 30 },
        },
    })
end

RegisterCommonEntries(Hunter.TALENT_TABS.BEAST_MASTERY)
RegisterCommonEntries(Hunter.TALENT_TABS.MARKSMANSHIP)
RegisterCommonEntries(Hunter.TALENT_TABS.SURVIVAL)

addon.CooldownRegistry:Register({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.BEAST_MASTERY,
    entries = {
        { id = "bestialWrath", type = "spell", spellIds = { Hunter.SPELL_IDS.bestialWrath }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "beastWithin", type = "aura", auraSpellIds = { Hunter.SPELL_IDS.beastWithin }, displaySpellId = Hunter.SPELL_IDS.beastWithin, defaultProcSoundEnabled = false, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.MARKSMANSHIP,
    entries = {
        { id = "readiness", type = "spell", spellIds = { Hunter.SPELL_IDS.readiness }, group = addon.COOLDOWN_GROUP_OFFENSIVE, order = 30 },
        { id = "silencingShot", type = "spell", spellIds = { Hunter.SPELL_IDS.silencingShot }, group = addon.COOLDOWN_GROUP_UTILITY, order = 40 },
    },
})

addon.CooldownRegistry:Register({
    classToken = Hunter.CLASS_TOKEN,
    talentTab = Hunter.TALENT_TABS.SURVIVAL,
    entries = {
        { id = "lockAndLoad", type = "aura", auraSpellIds = { Hunter.SPELL_IDS.lockAndLoad }, displaySpellId = Hunter.SPELL_IDS.lockAndLoad, showStacks = true, group = addon.COOLDOWN_GROUP_PROCS, order = 10 },
    },
})
