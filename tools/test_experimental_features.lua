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
TopDps.Settings = {}
TopDps.Logger = {
    Info = function()
    end,
}

function TopDps.Settings:GetSpecSetting(provider, key)
    return provider.testSettings and provider.testSettings[key] or nil
end

function TopDps.Settings:SetSpecSetting(provider, key, value)
    provider.testSettings = provider.testSettings or {}
    provider.testSettings[key] = value
end

dofile("Specs/SpecProvider.lua")

local provider = TopDps.SpecProvider:Create({
    id = "TEST_SPEC",
    categories = { "spell" },
    abilities = {
        spell = {
            spellIds = { 1 },
        },
    },
    settings = {
        {
            type = "checkbox",
            key = "stableSetting",
            default = true,
        },
        {
            type = "checkbox",
            key = "useTargetTimeToDie",
            default = false,
            experimental = true,
            experimentalFeature = "targetTimeToDie",
        },
    },
})
provider.testSettings = {
    stableSetting = true,
    useTargetTimeToDie = true,
}

local definitions = provider:GetSettingsDefinition()
AssertEqual(definitions[1].labelKey, "ROTATION_ABILITIES", "abilities header")
AssertEqual(definitions[2].key, "ability_spell", "ability setting")
AssertEqual(definitions[3].labelKey, "ROTATION_BEHAVIOR_SETTINGS", "behavior header")
AssertEqual(definitions[4].key, "stableSetting", "stable custom setting")
AssertEqual(definitions[5].labelKey, "ROTATION_EXPERIMENTAL_SETTINGS", "experimental header")
AssertEqual(definitions[5].experimental, true, "experimental header flag")
AssertEqual(definitions[6].key, "useTargetTimeToDie", "experimental setting")
AssertEqual(definitions[6].experimental, true, "experimental setting flag")
AssertEqual(
    provider:GetExperimentalFeatureSettingKey("targetTimeToDie"),
    "useTargetTimeToDie",
    "experimental feature lookup"
)

local ok = pcall(function()
    TopDps.SpecProvider:Create({
        id = "INVALID_EXPERIMENTAL",
        settings = {
            {
                type = "checkbox",
                key = "bad",
                default = true,
                experimental = true,
                experimentalFeature = "badFeature",
            },
        },
    })
end)
AssertEqual(ok, false, "experimental feature must default to false")

ok = pcall(function()
    TopDps.SpecProvider:Create({
        id = "DUPLICATE_EXPERIMENTAL",
        settings = {
            {
                type = "checkbox",
                key = "first",
                default = false,
                experimental = true,
                experimentalFeature = "duplicateFeature",
            },
            {
                type = "checkbox",
                key = "second",
                default = false,
                experimental = true,
                experimentalFeature = "duplicateFeature",
            },
        },
    })
end)
AssertEqual(ok, false, "experimental feature key must be unique per provider")

TopDps.db = {}
dofile("Core/ExperimentalFeatures.lua")

AssertEqual(TopDps.Settings:IsExperimentalFeaturesEnabled(), false, "global experimental default")
AssertEqual(provider:GetSetting("stableSetting"), true, "stable setting ignores experimental gate")
AssertEqual(
    provider:GetSetting("useTargetTimeToDie"),
    false,
    "experimental setting reads safe default while global gate is disabled"
)
provider:SetSetting("useTargetTimeToDie", false)
AssertEqual(
    provider.testSettings.useTargetTimeToDie,
    true,
    "global gate protects stored experimental setting from hidden control writes"
)
AssertEqual(
    TopDps.Settings:IsExperimentalFeatureEnabled(provider, TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE),
    false,
    "global gate blocks feature"
)

TopDps.Settings:SetExperimentalFeaturesEnabled(true)
AssertEqual(TopDps.Settings:IsExperimentalFeaturesEnabled(), true, "global experimental enabled")
AssertEqual(provider:GetSetting("useTargetTimeToDie"), true, "global gate exposes stored experimental setting")
AssertEqual(
    TopDps.Settings:IsExperimentalFeatureEnabled(provider, TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE),
    true,
    "double opt-in enables feature"
)

provider:SetSetting("useTargetTimeToDie", false)
AssertEqual(provider.testSettings.useTargetTimeToDie, false, "experimental setting is writable while global gate is enabled")
AssertEqual(
    TopDps.Settings:IsExperimentalFeatureEnabled(provider, TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE),
    false,
    "per-spec gate blocks feature"
)

provider:SetSetting("useTargetTimeToDie", true)
TopDps.Settings:SetExperimentalFeaturesEnabled(false)
AssertEqual(
    provider:GetSetting("useTargetTimeToDie"),
    false,
    "disabling global gate masks stored experimental setting"
)
AssertEqual(
    provider.testSettings.useTargetTimeToDie,
    true,
    "disabling global gate preserves stored experimental setting"
)
AssertEqual(
    TopDps.Settings:IsExperimentalFeatureEnabled(provider, TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE),
    false,
    "disabling global gate blocks feature again"
)

print("experimental feature smoke tests passed")
