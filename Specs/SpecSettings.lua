local addon = TopDps
local SpecProvider = addon.SpecProvider

function SpecProvider:BuildSettingsCatalog()
    self.settingDefinitionsByKey = {}
    self.categorySettingKeys = {}
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
