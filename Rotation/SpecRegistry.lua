local addon = RpalTopDps
local SpecRegistry = addon:CreateModule("SpecRegistry")

SpecRegistry.providers = SpecRegistry.providers or {}

function SpecRegistry:Register(provider)
    if type(provider) ~= "table" or not provider.id then
        error("RpalTopDps: invalid specialization provider")
    end

    local index
    for index = 1, #self.providers do
        if self.providers[index].id == provider.id then
            error("RpalTopDps: duplicate specialization provider " .. tostring(provider.id))
        end
    end

    table.insert(self.providers, provider)
end

function SpecRegistry:Initialize()
    local index
    for index = 1, #self.providers do
        local provider = self.providers[index]
        if provider.Initialize then
            provider:Initialize()
        end
    end
end

function SpecRegistry:GetActiveProvider()
    local index
    for index = 1, #self.providers do
        local provider = self.providers[index]
        if provider:IsActive() then
            return provider
        end
    end

    return nil
end

function SpecRegistry:RefreshSpellData()
    local index
    for index = 1, #self.providers do
        local provider = self.providers[index]
        if provider.BuildSpellCatalog then
            provider:BuildSpellCatalog()
        end
    end
end

function SpecRegistry:RefreshEquipment()
    local index
    for index = 1, #self.providers do
        local provider = self.providers[index]
        if provider.RefreshEquipment then
            provider:RefreshEquipment()
        end
    end
end
