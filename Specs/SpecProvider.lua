local addon = TopDps
local SpecProvider = addon:CreateModule("SpecProvider")

SpecProvider.__index = SpecProvider

function SpecProvider:Create(definition)
    if type(definition) ~= "table" then
        error("TopDps: specialization provider definition must be a table")
    end

    return setmetatable(definition, { __index = self })
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
