local addon = TopDps
local SpecProvider = addon:CreateModule("SpecProvider")

SpecProvider.__index = SpecProvider

local EMPTY_PRIORITY = {}
local NEXT_SWING_CENTER_SETTING_KEY = "showNextSwingCenter"

local VALID_SWING_RESETS = {
    MAIN_HAND = true,
    OFF_HAND = true,
    BOTH = true,
}

local function ValidateRefreshDefinition(category, refresh)
    if refresh == nil then
        return
    end

    if type(refresh) ~= "table" then
        error("TopDps: rotation refresh for " .. tostring(category) .. " must be a table")
    end

    if type(refresh.auraSpellIds) ~= "table" or #refresh.auraSpellIds == 0 then
        error("TopDps: rotation refresh for " .. tostring(category) .. " requires auraSpellIds")
    end

    if refresh.lead ~= nil and refresh.lead ~= addon.REFRESH_LEAD_CAST_TIME then
        local lead = tonumber(refresh.lead)
        if not lead or lead < 0 then
            error("TopDps: rotation refresh lead for " .. tostring(category) .. " must be non-negative")
        end
    end

    if refresh.isRefreshDue ~= nil and type(refresh.isRefreshDue) ~= "function" then
        error("TopDps: rotation refresh isRefreshDue for " .. tostring(category) .. " must be a function")
    end
end

local function ValidateSwingReset(category, swingReset)
    if swingReset ~= nil and not VALID_SWING_RESETS[swingReset] then
        error("TopDps: rotation swingReset for " .. tostring(category) .. " is invalid")
    end
end

local function ValidateNextSwingCategories(definition)
    local nextSwingCategories = definition.nextSwingCategories
    if nextSwingCategories == nil then
        return
    end

    if type(nextSwingCategories) ~= "table" then
        error("TopDps: nextSwingCategories must be a table")
    end

    local categorySet = {}
    local categories = definition.categories or {}
    local index
    for index = 1, #categories do
        categorySet[categories[index]] = true
    end

    local seen = {}
    for index = 1, #nextSwingCategories do
        local category = nextSwingCategories[index]
        if not categorySet[category] or not (definition.abilities and definition.abilities[category]) then
            error("TopDps: next-swing category " .. tostring(category) .. " is not a provider ability category")
        end

        if seen[category] then
            error("TopDps: duplicate next-swing category " .. tostring(category))
        end

        seen[category] = true
    end
end

local function ValidateExperimentalSetting(setting)
    if not setting or setting.experimentalFeature == nil then
        return
    end

    if setting.experimental ~= true then
        error("TopDps: experimentalFeature requires experimental = true")
    end

    if setting.type ~= "checkbox" then
        error("TopDps: experimentalFeature must be controlled by a checkbox")
    end

    if setting.default ~= false then
        error("TopDps: experimentalFeature checkbox must default to false")
    end
end

function SpecProvider:Create(definition)
    if type(definition) ~= "table" then
        error("TopDps: specialization provider definition must be a table")
    end

    local category, ability
    for category, ability in pairs(definition.abilities or {}) do
        ValidateRefreshDefinition(category, ability and ability.refresh or nil)
        ValidateSwingReset(category, ability and ability.swingReset or nil)
    end

    ValidateNextSwingCategories(definition)

    local settings = definition.settings or {}
    local settingIndex
    for settingIndex = 1, #settings do
        ValidateExperimentalSetting(settings[settingIndex])
    end

    local provider = setmetatable(definition, { __index = self })
    provider:BuildSettingsCatalog()

    return provider
end

function SpecProvider:BuildSettingsCatalog()
    self.settingDefinitionsByKey = {}
    self.categorySettingKeys = {}
    self.experimentalSettingKeysByFeature = {}
    self.effectiveSettings = {
        {
            type = "header",
            labelKey = "ROTATION_ABILITIES",
        },
    }

    local categories = self.categories or {}
    local categoryIndex
    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        table.insert(self.effectiveSettings, {
            type = "checkbox",
            key = "ability_" .. category,
            category = category,
            default = true,
        })
    end

    local customSettings = self.settings or {}
    local stableSettings = {}
    local experimentalSettings = {}
    local customIndex

    if #(self.nextSwingCategories or EMPTY_PRIORITY) > 0 then
        table.insert(stableSettings, {
            type = "checkbox",
            key = NEXT_SWING_CENTER_SETTING_KEY,
            labelKey = "SHOW_NEXT_SWING_CENTER",
            default = true,
        })
    end

    for customIndex = 1, #customSettings do
        local definition = customSettings[customIndex]
        if definition.experimental == true then
            table.insert(experimentalSettings, definition)
        else
            table.insert(stableSettings, definition)
        end
    end

    if #stableSettings > 0 then
        table.insert(self.effectiveSettings, {
            type = "header",
            labelKey = "ROTATION_BEHAVIOR_SETTINGS",
        })
    end

    for customIndex = 1, #stableSettings do
        table.insert(self.effectiveSettings, stableSettings[customIndex])
    end

    if #experimentalSettings > 0 then
        table.insert(self.effectiveSettings, {
            type = "header",
            labelKey = "ROTATION_EXPERIMENTAL_SETTINGS",
            experimental = true,
        })
    end

    for customIndex = 1, #experimentalSettings do
        table.insert(self.effectiveSettings, experimentalSettings[customIndex])
    end

    local index
    for index = 1, #self.effectiveSettings do
        local definition = self.effectiveSettings[index]
        if definition.key then
            self.settingDefinitionsByKey[definition.key] = definition
        end

        if definition.category and definition.key then
            self.categorySettingKeys[definition.category] = definition.key
        end

        if definition.experimentalFeature and definition.key then
            if self.experimentalSettingKeysByFeature[definition.experimentalFeature] then
                error(
                    "TopDps: duplicate experimentalFeature "
                        .. tostring(definition.experimentalFeature)
                        .. " in provider " .. tostring(self.id)
                )
            end

            self.experimentalSettingKeysByFeature[definition.experimentalFeature] = definition.key
        end
    end
end

function SpecProvider:GetSettingsDefinition()
    return self.effectiveSettings or {}
end

function SpecProvider:GetSettingDefinition(key)
    return self.settingDefinitionsByKey and self.settingDefinitionsByKey[key] or nil
end

function SpecProvider:GetExperimentalFeatureSettingKey(feature)
    if not self.experimentalSettingKeysByFeature then
        return nil
    end

    return self.experimentalSettingKeysByFeature[feature]
end

function SpecProvider:GetSetting(key)
    local definition = self:GetSettingDefinition(key)
    if definition
        and definition.experimental == true
        and addon.Settings.IsExperimentalFeaturesEnabled
        and not addon.Settings:IsExperimentalFeaturesEnabled() then
        return definition.default
    end

    return addon.Settings:GetSpecSetting(self, key)
end

function SpecProvider:SetSetting(key, value)
    local definition = self:GetSettingDefinition(key)
    if definition
        and definition.experimental == true
        and addon.Settings.IsExperimentalFeaturesEnabled
        and not addon.Settings:IsExperimentalFeaturesEnabled() then
        return
    end

    addon.Settings:SetSpecSetting(self, key, value)
end

function SpecProvider:GetDisplayName()
    if self.displayNameKey and addon.L[self.displayNameKey] then
        return addon.L[self.displayNameKey]
    end

    local generatedKey = "SPEC_" .. self.id
    if addon.L[generatedKey] then
        return addon.L[generatedKey]
    end

    return self.displayName or self.id
end

function SpecProvider:GetCategoryDisplayName(category)
    local localizationKey = "ABILITY_" .. string.upper(category)
    if addon.L[localizationKey] then
        return addon.L[localizationKey]
    end

    if self.spellNameByCategory and self.spellNameByCategory[category] then
        return self.spellNameByCategory[category]
    end

    local ability = self.abilities and self.abilities[category] or nil
    local spellIds = ability and ability.spellIds or nil
    if spellIds then
        local index
        for index = #spellIds, 1, -1 do
            local spellName = GetSpellInfo(spellIds[index])
            if spellName then
                return spellName
            end
        end
    end

    return category
end

function SpecProvider:IsCategoryEnabled(category)
    local key = self.categorySettingKeys and self.categorySettingKeys[category] or nil
    if not key then
        return true
    end

    return self:GetSetting(key) ~= false
end

function SpecProvider:Initialize()
    if self._initialized then
        return
    end

    self._initialized = true
    self:BuildSpellCatalog()

    if self.OnInitialize then
        self:OnInitialize()
    end
end

function SpecProvider:BuildSpellCatalog()
    self.spellCategoryById = {}
    self.spellCategoryByName = {}
    self.spellNameByCategory = {}

    local categories = self.categories or {}
    local abilities = self.abilities or {}
    local categoryIndex

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local ability = abilities[category]
        local spellIds = ability and ability.spellIds or nil

        if spellIds then
            local spellIndex
            for spellIndex = 1, #spellIds do
                local spellId = spellIds[spellIndex]
                self.spellCategoryById[spellId] = category

                local spellName = GetSpellInfo(spellId)
                if spellName then
                    self.spellCategoryByName[spellName] = category
                    self.spellNameByCategory[category] = self.spellNameByCategory[category] or spellName
                end
            end
        end
    end

    if self.OnSpellCatalogBuilt then
        self:OnSpellCatalogBuilt()
    end
end

function SpecProvider:RefreshSpellData()
    self:BuildSpellCatalog()
end

function SpecProvider:RefreshEquipment()
    if self.OnEquipmentChanged then
        self:OnEquipmentChanged()
    end
end

function SpecProvider:GetSpellCategory(spellId, spellName)
    local category

    if spellId then
        category = self.spellCategoryById[spellId]
    end

    if not category and spellName then
        category = self.spellCategoryByName[spellName]
    end

    return category
end

function SpecProvider:GetRecommendationName(category, entries)
    if entries and entries[1] and entries[1].spellName then
        return entries[1].spellName
    end

    return self.spellNameByCategory[category] or category
end

function SpecProvider:GetAvailability()
    return true
end

function SpecProvider:IsCategoryAllowed()
    return true
end

function SpecProvider:GetNextSwingCategories()
    return self.nextSwingCategories or EMPTY_PRIORITY
end

function SpecProvider:GetNextSwingPriority()
    return EMPTY_PRIORITY
end

function SpecProvider:IsNextSwingCenterEnabled()
    if #self:GetNextSwingCategories() == 0 then
        return false
    end

    return self:GetSetting(NEXT_SWING_CENTER_SETTING_KEY) ~= false
end

function SpecProvider:IsNextSwingCategoryAllowed(category, context)
    return self:IsCategoryAllowed(category, context)
end

function SpecProvider:CanTreatUnusableAsUsable()
    return false
end

function SpecProvider:IsEntryInRange(readiness, entry)
    return readiness:IsSpellInRange(entry)
end

function SpecProvider:GetReadyEntries(readiness, entries, category, context)
    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function SpecProvider:GetDebugState()
    return nil
end
