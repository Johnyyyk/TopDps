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

CombatTracker.enemyActivity = CombatTracker.enemyActivity or {}

function CombatTracker:RecordCombatEvent(...)
    local _, eventType, sourceGuid, _, _, destinationGuid = ...
    if not DAMAGE_EVENTS[eventType] then
        return
    end

    local playerGuid = UnitGUID("player")
    local now = GetTime()

    if sourceGuid == playerGuid and destinationGuid and destinationGuid ~= playerGuid then
        self.enemyActivity[destinationGuid] = now
    elseif destinationGuid == playerGuid and sourceGuid and sourceGuid ~= playerGuid then
        self.enemyActivity[sourceGuid] = now
    end
end

function CombatTracker:Clear()
    self.enemyActivity = {}
end

function CombatTracker:GetActiveEnemyCount()
    local now = GetTime()
    local targetGuid = UnitGUID("target")
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

    if targetGuid and not self.enemyActivity[targetGuid] then
        count = count + 1
    end

    return count
end

-- Совместимость со спеками, которые пока используют старое имя.
function CombatTracker:GetEnemyCount()
    return self:GetActiveEnemyCount()
end
