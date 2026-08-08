local addon = TopDps
local SpecRegistry = addon:CreateModule("SpecRegistry")

SpecRegistry.providers = SpecRegistry.providers or {}
SpecRegistry.providersById = SpecRegistry.providersById or {}
SpecRegistry.providersByClass = SpecRegistry.providersByClass or {}
SpecRegistry.defaultByClass = SpecRegistry.defaultByClass or {}

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
