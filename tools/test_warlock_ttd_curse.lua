local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = {
        Modules = {},
    }

    function addon:CreateModule(name)
        local module = self.Modules[name]
        if module then
            return module
        end

        module = {}
        self.Modules[name] = module
        self[name] = module
        return module
    end

    return addon
end

TopDps = NewAddon()
TopDps.REFRESH_LEAD_CAST_TIME = "CAST_TIME"
TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE = "targetTimeToDie"
TopDps.SpecProvider = {}
TopDps.SpecRegistry = {
    providers = {},
}

function TopDps.SpecProvider:Create(definition)
    definition.testSettings = {
        curseMode = "auto",
        useMovementPriority = true,
        useTargetTimeToDie = false,
    }

    function definition:GetSetting(key)
        return self.testSettings[key]
    end

    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

dofile("Specs/Warlock/Common.lua")

dofile("Specs/Warlock/Demonology.lua")
dofile("Specs/Warlock/Destruction.lua")

local Warlock = TopDps.Warlock
local Demonology = TopDps.SpecRegistry.providers.WARLOCK_DEMONOLOGY
local Destruction = TopDps.SpecRegistry.providers.WARLOCK_DESTRUCTION
local externalMagicVulnerability = true
local bossLike = false
local activeCurseSpellId = nil

Warlock.HasExternalMagicVulnerability = function()
    return externalMagicVulnerability
end

Warlock.IsBossLikeTarget = function()
    return bossLike
end

Warlock.HasOwnTargetAura = function(_, spellIds)
    local index
    for index = 1, #spellIds do
        if spellIds[index] == activeCurseSpellId then
            return true
        end
    end

    return false
end

local function FindSetting(provider, key)
    local index
    for index = 1, #(provider.settings or {}) do
        local setting = provider.settings[index]
        if setting.key == key then
            return setting
        end
    end

    return nil
end

local function Context(timeToDie)
    return {
        target = {
            timeToDie = timeToDie,
        },
    }
end

local function TestProviderSettings()
    local demoSetting = FindSetting(Demonology, "useTargetTimeToDie")
    local destroSetting = FindSetting(Destruction, "useTargetTimeToDie")

    AssertEqual(demoSetting ~= nil, true, "demo TTD setting")
    AssertEqual(demoSetting.default, false, "demo TTD default")
    AssertEqual(demoSetting.experimental, true, "demo TTD experimental")
    AssertEqual(
        demoSetting.experimentalFeature,
        TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
        "demo TTD feature"
    )

    AssertEqual(destroSetting ~= nil, true, "destro TTD setting")
    AssertEqual(destroSetting.default, false, "destro TTD default")
    AssertEqual(destroSetting.experimental, true, "destro TTD experimental")
    AssertEqual(
        destroSetting.experimentalFeature,
        TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
        "destro TTD feature"
    )
end

local function TestAutoCurseSelectionWithTimeToDie()
    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_AUTO
    externalMagicVulnerability = true
    bossLike = false

    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(61)),
        Warlock.SPELL_IDS.curseDoom,
        "TTD above Doom duration chooses Doom"
    )
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(60)),
        Warlock.SPELL_IDS.curseAgony,
        "TTD at Doom duration chooses Agony"
    )
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(20)),
        Warlock.SPELL_IDS.curseAgony,
        "short TTD chooses Agony"
    )

    bossLike = true
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(20)),
        Warlock.SPELL_IDS.curseAgony,
        "known short TTD overrides boss fallback"
    )

    bossLike = false
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(90)),
        Warlock.SPELL_IDS.curseDoom,
        "known long TTD overrides normal-target fallback"
    )
end

local function TestLegacyFallbackWithoutTimeToDie()
    externalMagicVulnerability = true

    bossLike = true
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(nil)),
        Warlock.SPELL_IDS.curseDoom,
        "nil TTD keeps boss Doom fallback"
    )

    bossLike = false
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(nil)),
        Warlock.SPELL_IDS.curseAgony,
        "nil TTD keeps normal Agony fallback"
    )
end

local function TestElementsAndManualModesIgnoreTimeToDie()
    externalMagicVulnerability = false
    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_AUTO
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(120)),
        Warlock.SPELL_IDS.curseElements,
        "TTD never replaces required Elements"
    )

    externalMagicVulnerability = true
    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_DOOM
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(10)),
        Warlock.SPELL_IDS.curseDoom,
        "manual Doom ignores TTD"
    )

    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_AGONY
    AssertEqual(
        Warlock:GetPreferredCurseSpellId(Demonology, Context(120)),
        Warlock.SPELL_IDS.curseAgony,
        "manual Agony ignores TTD"
    )

    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_AUTO
end

local function TestCurseReplacementWhenEstimateChanges()
    externalMagicVulnerability = true
    Demonology.testSettings.curseMode = Warlock.CURSE_MODE_AUTO

    activeCurseSpellId = Warlock.SPELL_IDS.curseDoom
    AssertEqual(
        Warlock:IsCurseRequirementSatisfied(Demonology, Context(30)),
        false,
        "short TTD makes active Doom unsatisfied"
    )
    AssertEqual(
        Warlock:GetCommonCategoryAllowed(Demonology, "curse", Context(30)),
        true,
        "short TTD allows replacing Doom"
    )

    activeCurseSpellId = Warlock.SPELL_IDS.curseAgony
    AssertEqual(
        Warlock:IsCurseRequirementSatisfied(Demonology, Context(30)),
        true,
        "short TTD accepts Agony"
    )
    AssertEqual(
        Warlock:IsCurseRequirementSatisfied(Demonology, Context(90)),
        false,
        "long TTD makes active Agony unsatisfied"
    )

    activeCurseSpellId = Warlock.SPELL_IDS.curseDoom
    AssertEqual(
        Warlock:IsCurseRequirementSatisfied(Demonology, Context(90)),
        true,
        "long TTD accepts Doom"
    )

    activeCurseSpellId = Warlock.SPELL_IDS.curseAgony
    bossLike = true
    AssertEqual(
        Warlock:IsCurseRequirementSatisfied(Demonology, Context(nil)),
        true,
        "nil TTD keeps legacy acceptance of either damage curse"
    )

    activeCurseSpellId = nil
end

TestProviderSettings()
TestAutoCurseSelectionWithTimeToDie()
TestLegacyFallbackWithoutTimeToDie()
TestElementsAndManualModesIgnoreTimeToDie()
TestCurseReplacementWhenEstimateChanges()

print("warlock TTD curse smoke tests passed")
