local addon = TopDps
local SpecProvider = addon:CreateModule("SpecProvider")

SpecProvider.__index = SpecProvider

function SpecProvider:Create(definition)
    if type(definition) ~= "table" then
        error("TopDps: specialization provider definition must be a table")
    end

    local provider = setmetatable(definition, { __index = self })
    provider:BuildSettingsCatalog()

    return provider
end

function SpecProvider:BuildSettingsCatalog()
    self.settingDefinitionsByKey = {}
    self.categorySettingKeys = {}
    self.effectiveSettings = {
        {
            type = "checkbox",
            key = "enabled",
            labelKey = "ROTATION_ENABLED",
            default = true,
        },
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
    local customIndex
    for customIndex = 1, #customSettings do
        table.insert(self.effectiveSettings, customSettings[customIndex])
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
    end
end

function SpecProvider:GetSettingsDefinition()
    return self.effectiveSettings or {}
end

function SpecProvider:GetSettingDefinition(key)
    return self.settingDefinitionsByKey and self.settingDefinitionsByKey[key] or nil
end

function SpecProvider:GetSetting(key)
    return addon.Settings:GetSpecSetting(self, key)
end

function SpecProvider:SetSetting(key, value)
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

function SpecProvider:CanTreatUnusableAsUsable()
    return false
end

function SpecProvider:IsEntryInRange(readiness, entry)
    return readiness:IsActionInRange(entry.action)
end

function SpecProvider:GetReadyEntries(readiness, entries, category, context)
    return readiness:GetDefaultReadyEntries(entries, category, self, context)
end

function SpecProvider:GetDebugState()
    return nil
end
