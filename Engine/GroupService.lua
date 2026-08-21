local addon = TopDps
local GroupService = addon:CreateModule("GroupService")

function GroupService:GetUnits()
    local units = {}
    local raidCount = GetNumRaidMembers and GetNumRaidMembers() or 0
    local partyCount = GetNumPartyMembers and GetNumPartyMembers() or 0
    local index

    if raidCount > 0 then
        for index = 1, raidCount do
            units[#units + 1] = "raid" .. tostring(index)
        end

        return units
    end

    units[#units + 1] = "player"
    for index = 1, partyCount do
        units[#units + 1] = "party" .. tostring(index)
    end

    return units
end

function GroupService:GetSnapshots()
    local units = self:GetUnits()
    local result = {}
    local index

    for index = 1, #units do
        local unit = units[index]
        result[#result + 1] = addon.UnitStateService:GetUnitSnapshot(unit)
    end

    return result
end

function GroupService:FindAura(unit, spellIds, filter, ownOnly)
    return addon.AuraService:FindAura(unit, spellIds, filter, ownOnly)
end

function GroupService:CountAura(spellIds, filter, ownOnly)
    local units = self:GetUnits()
    local count = 0
    local index

    for index = 1, #units do
        if self:FindAura(units[index], spellIds, filter, ownOnly) then
            count = count + 1
        end
    end

    return count, #units
end

function GroupService:GetUnitsMissingAura(spellIds, filter, ownOnly)
    local units = self:GetUnits()
    local result = {}
    local index

    for index = 1, #units do
        local unit = units[index]
        if not self:FindAura(unit, spellIds, filter, ownOnly) then
            result[#result + 1] = unit
        end
    end

    return result
end

function GroupService:IsActiveHealthUnit(unit)
    local snapshot = addon.UnitStateService:GetUnitSnapshot(unit)
    return snapshot.exists
        and snapshot.connected
        and not snapshot.dead
        and snapshot.health.maximum > 0,
        snapshot
end

function GroupService:CountHealthAtOrBelow(fraction)
    local units = self:GetUnits()
    local count = 0
    local eligibleCount = 0
    local index

    for index = 1, #units do
        local eligible, snapshot = self:IsActiveHealthUnit(units[index])
        if eligible then
            eligibleCount = eligibleCount + 1
            if snapshot.health.fraction <= fraction then
                count = count + 1
            end
        end
    end

    return count, eligibleCount
end

function GroupService:FindLowestHealthUnit()
    local units = self:GetUnits()
    local lowestUnit
    local lowestHealth
    local index

    for index = 1, #units do
        local unit = units[index]
        local eligible, snapshot = self:IsActiveHealthUnit(unit)
        if eligible and (not lowestHealth or snapshot.health.fraction < lowestHealth.fraction) then
            lowestUnit = unit
            lowestHealth = snapshot.health
        end
    end

    return lowestUnit, lowestHealth
end
