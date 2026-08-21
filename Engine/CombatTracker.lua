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

function CombatTracker:RecordCombatEvent(...)
    local _, eventType, sourceGuid, _, sourceFlags, destinationGuid, _, destinationFlags = ...
    if not DAMAGE_EVENTS[eventType] then
        return
    end

    local playerGuid = UnitGUID("player")
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
