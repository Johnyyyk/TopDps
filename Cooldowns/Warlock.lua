local addon = TopDps
local Warlock = addon.Warlock

addon.CooldownRegistry:RegisterProfile({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DEMONOLOGY,
    labelKey = "SPEC_WARLOCK_DEMONOLOGY",
})

addon.CooldownRegistry:RegisterProfile({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DESTRUCTION,
    labelKey = "SPEC_WARLOCK_DESTRUCTION",
})

local function RegisterCommonEntries(talentTab)
    addon.CooldownRegistry:Register({
        classToken = Warlock.CLASS_TOKEN,
        talentTab = talentTab,
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
        },
    })
end

RegisterCommonEntries(Warlock.TALENT_TABS.DEMONOLOGY)
RegisterCommonEntries(Warlock.TALENT_TABS.DESTRUCTION)

addon.CooldownRegistry:Register({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DEMONOLOGY,
    entries = {
        {
            id = "correctPet",
            type = "state",
            displaySpellId = Warlock.SPELL_IDS.summonFelguard,
            name = addon.L.WARLOCK_FELGUARD_STATE,
            isApplicable = function()
                return Warlock:IsPetRequirementApplicable()
            end,
            getState = function()
                return Warlock:GetRequiredPetState("felguard")
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
            id = "soulLink",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.soulLinkAura },
            displaySpellId = Warlock.SPELL_IDS.soulLink,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.soulLink },
            requiredTalentTab = Warlock.TALENT_TABS.DEMONOLOGY,
            isApplicable = function()
                return Warlock:IsPetRequirementApplicable()
            end,
            showDuration = false,
            group = addon.COOLDOWN_GROUP_STATES,
            panelCategory = addon.PANEL_CATEGORY_BUFFS,
            panelBehavior = addon.PANEL_BEHAVIOR_REQUIRED_BUFF,
            order = 50,
        },
        {
            id = "metamorphosis",
            type = "spell",
            spellIds = { Warlock.SPELL_IDS.metamorphosis },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 10,
        },
        {
            id = "demonicEmpowerment",
            type = "spell",
            spellIds = { Warlock.SPELL_IDS.demonicEmpowerment },
            group = addon.COOLDOWN_GROUP_OFFENSIVE,
            order = 20,
        },
        {
            id = "moltenCore",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.moltenCoreProc },
            displaySpellId = Warlock.SPELL_IDS.moltenCoreProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.moltenCoreTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DEMONOLOGY,
            showStacks = true,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
        {
            id = "decimation",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.decimationProc },
            displaySpellId = Warlock.SPELL_IDS.decimationProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.decimationTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DEMONOLOGY,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 20,
        },
        {
            id = "demonicPact",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.demonicPactProc },
            displaySpellId = Warlock.SPELL_IDS.demonicPactProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.demonicPactTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DEMONOLOGY,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 30,
        },
    },
})

addon.CooldownRegistry:Register({
    classToken = Warlock.CLASS_TOKEN,
    talentTab = Warlock.TALENT_TABS.DESTRUCTION,
    entries = {
        {
            id = "correctPet",
            type = "state",
            displaySpellId = Warlock.SPELL_IDS.summonImp,
            name = addon.L.WARLOCK_IMP_STATE,
            isApplicable = function()
                return Warlock:IsPetRequirementApplicable()
            end,
            getState = function()
                return Warlock:GetRequiredPetState("imp")
            end,
            order = 30,
        },
        {
            id = "weaponStone",
            type = "state",
            displaySpellId = Warlock.SPELL_IDS.grandFirestone,
            name = addon.L.WARLOCK_FIRESTONE_STATE,
            getState = function()
                return Warlock:GetWeaponStoneState(
                    Warlock.SPELL_IDS.grandFirestone,
                    Warlock.WEAPON_ENCHANT_SPELL_IDS.firestone
                )
            end,
            order = 40,
        },
        {
            id = "backdraft",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.backdraftProc },
            displaySpellId = Warlock.SPELL_IDS.backdraftProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.backdraftTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DESTRUCTION,
            showStacks = true,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 10,
        },
        {
            id = "empoweredImp",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.empoweredImpProc },
            displaySpellId = Warlock.SPELL_IDS.empoweredImpProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.empoweredImpTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DESTRUCTION,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 20,
        },
        {
            id = "pyroclasm",
            type = "aura",
            auraSpellIds = { Warlock.SPELL_IDS.pyroclasmProc },
            displaySpellId = Warlock.SPELL_IDS.pyroclasmProc,
            requiredTalentSpellIds = { Warlock.SPELL_IDS.pyroclasmTalent },
            requiredTalentTab = Warlock.TALENT_TABS.DESTRUCTION,
            group = addon.COOLDOWN_GROUP_PROCS,
            order = 30,
        },
    },
})
