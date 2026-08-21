local addon = TopDps
local RefreshService = addon:CreateModule("RefreshService")

local function GetRefreshDefinition(provider, category)
    local ability = provider and provider.abilities and provider.abilities[category] or nil
    return ability and ability.refresh or nil
end

function RefreshService:GetCastLeadSeconds(category, context)
    local entries = context and context.actionsByCategory and context.actionsByCategory[category] or nil
    if type(entries) ~= "table" then
        return 0
    end

    local index
    for index = 1, #entries do
        local entry = entries[index]
        local castTime = addon.GameApi:GetSpellCastTime(entry.spellId or entry.spellName)
        if castTime > 0 then
            return castTime
        end
    end

    return 0
end

function RefreshService:GetLeadSeconds(definition, category, context)
    if definition.lead == addon.REFRESH_LEAD_CAST_TIME then
        return self:GetCastLeadSeconds(category, context)
    end

    return math.max(0, tonumber(definition.lead) or 0)
end

function RefreshService:IsCategoryRefreshDue(provider, category, context)
    local definition = GetRefreshDefinition(provider, category)
    if not definition then
        return true
    end

    local unit = definition.unit or "target"
    local filter = definition.filter or "HARMFUL"
    local aura = addon.AuraService:FindAura(
        unit,
        definition.auraSpellIds,
        filter,
        definition.ownOnly == true
    )
    local now = context and tonumber(context.now) or GetTime()
    local expirationTime = aura and tonumber(aura.expirationTime) or 0
    local remaining
    if aura and expirationTime > 0 then
        remaining = math.max(0, expirationTime - now)
    end

    local lead = self:GetLeadSeconds(definition, category, context)
    if definition.isRefreshDue ~= nil then
        if type(definition.isRefreshDue) ~= "function" then
            error("TopDps: rotation refresh isRefreshDue for " .. tostring(category) .. " must be a function")
        end

        local decision = definition.isRefreshDue(context, aura, remaining, lead)
        if decision ~= nil then
            return decision == true
        end
    end

    if not aura then
        return true
    end

    if expirationTime <= 0 then
        return false
    end

    return remaining <= lead
end
