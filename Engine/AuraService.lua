local addon = TopDps
local AuraService = addon:CreateModule("AuraService")

local AURA_SCAN_LIMIT = 40

local function IsOwnAuraCaster(unitCaster)
    if not unitCaster then
        return false
    end

    if unitCaster == "player" then
        return true
    end

    if UnitIsUnit then
        local ok, sameUnit = pcall(UnitIsUnit, unitCaster, "player")
        return ok and sameUnit == true
    end

    return false
end

local function BuildWantedAuras(spellIds)
    local ids = {}
    local names = {}
    local index

    for index = 1, #(spellIds or {}) do
        local spellId = spellIds[index]
        ids[spellId] = true

        local spellName = GetSpellInfo(spellId)
        if spellName then
            names[spellName] = spellId
        end
    end

    return ids, names
end

function AuraService:ReadAura(unit, index, filter)
    local reader = filter == "HARMFUL" and UnitDebuff or UnitBuff
    if not reader then
        return nil
    end

    local name, _, icon, stacks, _, duration, expirationTime, unitCaster, _, _, spellId = reader(unit, index)
    if not name then
        return nil
    end

    return {
        spellId = spellId,
        name = name,
        icon = icon,
        stacks = stacks or 0,
        duration = duration or 0,
        expirationTime = expirationTime or 0,
        unitCaster = unitCaster,
        unit = unit,
    }
end

function AuraService:FindAura(unit, spellIds, filter, ownOnly)
    if not unit or type(spellIds) ~= "table" or #spellIds == 0 or not UnitExists(unit) then
        return nil
    end

    local wantedIds, wantedNames = BuildWantedAuras(spellIds)
    local index

    for index = 1, AURA_SCAN_LIMIT do
        local aura = self:ReadAura(unit, index, filter)
        if not aura then
            break
        end

        local matchedSpellId
        if aura.spellId and wantedIds[aura.spellId] then
            matchedSpellId = aura.spellId
        elseif aura.name then
            matchedSpellId = wantedNames[aura.name]
        end

        if matchedSpellId and (not ownOnly or IsOwnAuraCaster(aura.unitCaster)) then
            return aura, matchedSpellId
        end
    end

    return nil, nil
end

function AuraService:BuildAuraIndex(unit, filter)
    local result = {
        byId = {},
        byName = {},
    }

    if not unit or not UnitExists(unit) then
        return result
    end

    local index
    for index = 1, AURA_SCAN_LIMIT do
        local aura = self:ReadAura(unit, index, filter)
        if not aura then
            break
        end

        if aura.spellId then
            result.byId[aura.spellId] = aura
        end

        if aura.name then
            result.byName[aura.name] = aura
        end
    end

    return result
end

function AuraService:FindAuraInIndex(auraIndex, spellIds)
    if type(auraIndex) ~= "table" or type(spellIds) ~= "table" then
        return nil
    end

    local byId = auraIndex.byId or {}
    local byName = auraIndex.byName or {}
    local index

    for index = 1, #spellIds do
        local spellId = spellIds[index]
        local aura = byId[spellId]
        if aura then
            return aura, spellId
        end

        local spellName = GetSpellInfo(spellId)
        if spellName then
            aura = byName[spellName]
            if aura then
                return aura, spellId
            end
        end
    end

    return nil, nil
end
