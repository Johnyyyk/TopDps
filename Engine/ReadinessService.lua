local addon = TopDps
local ReadinessService = addon:CreateModule("ReadinessService")

local GLOBAL_COOLDOWN_SPELL_ID = 61304

function ReadinessService:IsActionInRange(action)
    local inRange = IsActionInRange(action)
    return inRange ~= 0
end

function ReadinessService:GetActionCooldownRemaining(action)
    local start, duration, enabled = GetActionCooldown(action)
    duration = tonumber(duration) or 0

    if enabled == 0 then
        return math.huge, duration, enabled
    end

    if not start or start == 0 or duration == 0 then
        return 0, duration, enabled
    end

    local remaining = start + duration - GetTime()
    if remaining < 0 then
        remaining = 0
    end

    return remaining, duration, enabled
end

function ReadinessService:GetGlobalCooldownRemaining()
    if not GetSpellCooldown then
        return 0
    end

    local ok, start, duration, enabled = pcall(GetSpellCooldown, GLOBAL_COOLDOWN_SPELL_ID)
    if not ok or enabled == 0 or not start or not duration or start == 0 or duration == 0 then
        return 0
    end

    local remaining = start + duration - GetTime()
    return math.max(0, remaining)
end

function ReadinessService:IsActionCooldownReady(action)
    local remaining, duration, enabled = self:GetActionCooldownRemaining(action)
    if enabled == 0 then
        return false
    end

    if remaining <= 0.15 then
        return true
    end

    -- Сохраняем текущее поведение: cooldown длительностью GCD не блокирует рекомендацию.
    return duration <= 1.6
end

function ReadinessService:IsEntryInRange(entry, category, provider, context)
    return provider:IsEntryInRange(self, entry, category, context)
end

function ReadinessService:IsActionReady(entry, category, provider, context)
    local usable, notEnoughMana = IsUsableAction(entry.action)
    if not usable then
        if notEnoughMana then
            return false
        end

        if not provider:CanTreatUnusableAsUsable(category, entry, context) then
            return false
        end
    end

    if not self:IsEntryInRange(entry, category, provider, context) then
        return false
    end

    return self:IsActionCooldownReady(entry.action)
end

function ReadinessService:GetDefaultReadyEntries(entries, category, provider, context)
    local readyEntries = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if self:IsActionReady(entry, category, provider, context) then
            table.insert(readyEntries, entry)
        end
    end

    return readyEntries
end

function ReadinessService:GetReadyEntries(entries, category, provider, context)
    return provider:GetReadyEntries(self, entries, category, context)
end
