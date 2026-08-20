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
    if not aura then
        return true
    end

    local expirationTime = tonumber(aura.expirationTime) or 0
    if expirationTime <= 0 then
        return false
    end

    local now = context and tonumber(context.now) or GetTime()
    local remaining = math.max(0, expirationTime - now)
    return remaining <= self:GetLeadSeconds(definition, category, context)
end
