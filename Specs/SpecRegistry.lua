local addon = TopDps
local SpecRegistry = addon:CreateModule("SpecRegistry")

SpecRegistry.providers = SpecRegistry.providers or {}
SpecRegistry.providersById = SpecRegistry.providersById or {}
SpecRegistry.providersByClass = SpecRegistry.providersByClass or {}
SpecRegistry.defaultByClass = SpecRegistry.defaultByClass or {}

local SETTING_TYPES = {
    checkbox = true,
    slider = true,
    dropdown = true,
    header = true,
}

local function IsValueInList(value, list)
    local index
    for index = 1, #list do
        if value == list[index] then
            return true
        end
    end

    return false
end

local function ValidateSettings(provider)
    local settings = provider.settings or {}
    local keys = {}
    local index

    for index = 1, #settings do
        local definition = settings[index]
        if type(definition) ~= "table" or not SETTING_TYPES[definition.type] then
            error("TopDps: invalid setting definition for " .. tostring(provider.id))
        end

        if definition.type ~= "header" then
            if type(definition.key) ~= "string" or definition.key == "" then
                error("TopDps: specialization setting requires key for " .. tostring(provider.id))
            end

            if keys[definition.key] then
                error("TopDps: duplicate specialization setting " .. tostring(definition.key))
            end
            keys[definition.key] = true
        end

        if definition.type == "checkbox" and type(definition.default) ~= "boolean" then
            error("TopDps: checkbox setting requires boolean default")
        end

        if definition.type == "slider" then
            if type(definition.default) ~= "number"
                or type(definition.min) ~= "number"
                or type(definition.max) ~= "number"
                or definition.min > definition.max then
                error("TopDps: slider setting requires numeric default/min/max")
            end
        end

        if definition.type == "dropdown" then
            if type(definition.values) ~= "table" or #definition.values == 0 then
                error("TopDps: dropdown setting requires values")
            end

            if not IsValueInList(definition.default, definition.values) then
                error("TopDps: dropdown setting default must exist in values")
            end
        end
    end
end

local function ValidateProvider(provider)
    if type(provider) ~= "table" then
        error("TopDps: specialization provider must be a table")
    end

    if type(provider.id) ~= "string" or provider.id == "" then
        error("TopDps: specialization provider requires id")
    end

    if type(provider.classToken) ~= "string" or provider.classToken == "" then
        error("TopDps: specialization provider requires classToken")
    end

    if type(provider.talentTab) ~= "number" or provider.talentTab < 1 or provider.talentTab > 3 then
        error("TopDps: specialization provider requires talentTab from 1 to 3")
    end

    if type(provider.categories) ~= "table" then
        error("TopDps: specialization provider requires categories")
    end

    if type(provider.abilities) ~= "table" then
        error("TopDps: specialization provider requires abilities")
    end

    if type(provider.GetPriority) ~= "function" then
        error("TopDps: specialization provider requires GetPriority(context)")
    end

    ValidateSettings(provider)
end

function SpecRegistry:Register(provider)
    ValidateProvider(provider)

    if self.providersById[provider.id] then
        error("TopDps: duplicate specialization provider " .. tostring(provider.id))
    end

    local classProviders = self.providersByClass[provider.classToken]
    if not classProviders then
        classProviders = {}
        self.providersByClass[provider.classToken] = classProviders
    end

    if classProviders[provider.talentTab] then
        error(
            "TopDps: duplicate specialization provider for "
                .. tostring(provider.classToken)
                .. " talent tab "
                .. tostring(provider.talentTab)
        )
    end

    if provider.defaultForClass then
        if self.defaultByClass[provider.classToken] then
            error("TopDps: duplicate default provider for " .. tostring(provider.classToken))
        end

        self.defaultByClass[provider.classToken] = provider
    end

    classProviders[provider.talentTab] = provider
    self.providersById[provider.id] = provider
    table.insert(self.providers, provider)
end

function SpecRegistry:Get(classToken, talentTab)
    local classProviders = self.providersByClass[classToken]
    return classProviders and classProviders[talentTab] or nil
end

function SpecRegistry:GetDefaultForClass(classToken)
    return self.defaultByClass[classToken]
end

function SpecRegistry:GetById(providerId)
    return self.providersById[providerId]
end

function SpecRegistry:GetAll()
    return self.providers
end
