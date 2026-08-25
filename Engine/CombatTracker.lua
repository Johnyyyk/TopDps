local addon = TopDps
local CombatTracker = addon:CreateModule("CombatTracker")

local DAMAGE_EVENTS = {
    SWING_DAMAGE = true,
    SWING_MISSED = true,
    RANGE_DAMAGE = true,
    RANGE_MISSED = true,
    SPELL_DAMAGE = true,
    SPELL_MISSED = true,
    SPELL_PERIODIC_DAMAGE = true,
    SPELL_PERIODIC_MISSED = true,
    DAMAGE_SHIELD = true,
    DAMAGE_SHIELD_MISSED = true,
}

local ENEMY_ACTIVITY_TIMEOUT = 6
local bitBand = bit and bit.band or nil

CombatTracker.enemyActivity = CombatTracker.enemyActivity or {}
CombatTracker.lastPlayerSpellCastsById = CombatTracker.lastPlayerSpellCastsById or {}
CombatTracker.lastPlayerSpellCastsByName = CombatTracker.lastPlayerSpellCastsByName or {}

local function IsApiTrue(value)
    return value == true or value == 1
end

local function HasMineAffiliation(flags)
    if not bitBand or not COMBATLOG_OBJECT_AFFILIATION_MINE or not flags then
        return false
    end

    return bitBand(flags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0
end

local function IsOwnedUnit(guid, flags, playerGuid, petGuid)
    if not guid then
        return false
    end

    if guid == playerGuid or (petGuid and guid == petGuid) then
        return true
    end

    return HasMineAffiliation(flags)
end

function CombatTracker:RecordPlayerSpellCast(spellId, spellName)
    spellId = tonumber(spellId)
    local state = {
        spellId = spellId,
        spellName = spellName,
        time = GetTime(),
    }

    if spellId then
        self.lastPlayerSpellCastsById[spellId] = state
    end

    if spellName and spellName ~= "" then
        self.lastPlayerSpellCastsByName[spellName] = state
    end
end

function CombatTracker:GetLastPlayerSpellCast(spellIds)
    local latest
    local index

    for index = 1, #(spellIds or {}) do
        local spellId = tonumber(spellIds[index])
        local candidate = spellId and self.lastPlayerSpellCastsById[spellId] or nil
        if candidate and (not latest or candidate.time > latest.time) then
            latest = candidate
        end

        if spellId and GetSpellInfo then
            local spellName = GetSpellInfo(spellId)
            candidate = spellName and self.lastPlayerSpellCastsByName[spellName] or nil
            if candidate and (not latest or candidate.time > latest.time) then
                latest = candidate
            end
        end
    end

    return latest
end

function CombatTracker:RecordCombatEvent(...)
    local _, eventType, sourceGuid, _, sourceFlags, destinationGuid, _, destinationFlags = ...
    local playerGuid = UnitGUID("player")

    if eventType == "SPELL_CAST_SUCCESS" and sourceGuid == playerGuid then
        self:RecordPlayerSpellCast(select(9, ...), select(10, ...))
    end

    if not DAMAGE_EVENTS[eventType] then
        return
    end

    local petGuid = UnitGUID("pet")
    local sourceOwned = IsOwnedUnit(sourceGuid, sourceFlags, playerGuid, petGuid)
    local destinationOwned = IsOwnedUnit(destinationGuid, destinationFlags, playerGuid, petGuid)
    local now = GetTime()

    if sourceOwned and destinationGuid and not destinationOwned then
        self.enemyActivity[destinationGuid] = now
    elseif destinationOwned and sourceGuid and not sourceOwned then
        self.enemyActivity[sourceGuid] = now
    end
end

function CombatTracker:Clear()
    self.enemyActivity = {}
    self.lastPlayerSpellCastsById = {}
    self.lastPlayerSpellCastsByName = {}
end

function CombatTracker:GetActiveEnemyCount()
    local now = GetTime()
    local targetGuid = UnitGUID("target")
    local targetAttackable = targetGuid
        and UnitCanAttack
        and IsApiTrue(UnitCanAttack("player", "target"))
    local count = 0
    local guid
    local timestamp

    for guid, timestamp in pairs(self.enemyActivity) do
        if now - timestamp <= ENEMY_ACTIVITY_TIMEOUT then
            count = count + 1
        else
            self.enemyActivity[guid] = nil
        end
    end

    if targetAttackable and not self.enemyActivity[targetGuid] then
        count = count + 1
    end

    return count
end

-- Совместимость со спеками, которые пока используют старое имя.
function CombatTracker:GetEnemyCount()
    return self:GetActiveEnemyCount()
end
