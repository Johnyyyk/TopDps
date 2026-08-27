local addon = TopDps
local ReadinessService = addon:CreateModule("ReadinessService")

local GLOBAL_COOLDOWN_SPELL_ID = 61304

local function GetEntrySpell(entry)
    if not entry then
        return nil
    end

    -- Имена намеренно предпочтительнее ID: spell API WotLK стабильно работает
    -- с известным заклинанием по имени независимо от конкретного изученного rank.
    return entry.spellName or entry.spellId
end

function ReadinessService:IsSpellInRange(entry)
    local spell = GetEntrySpell(entry)
    if not spell or not IsSpellInRange then
        return true
    end

    local ok, inRange = pcall(IsSpellInRange, spell, "target")
    if not ok then
        return true
    end

    -- nil означает, что range check для этого заклинания неприменим.
    return inRange ~= 0
end

function ReadinessService:GetSpellCooldownRemaining(entry)
    local spell = GetEntrySpell(entry)
    if not spell or not GetSpellCooldown then
        return math.huge, 0, 0
    end

    local ok, start, duration, enabled = pcall(GetSpellCooldown, spell)
    if not ok then
        return math.huge, 0, 0
    end

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

function ReadinessService:IsCooldownReady(remaining, duration, enabled)
    if enabled == 0 then
        return false
    end

    local lookahead = addon.db
        and addon.db.rotation
        and addon.db.rotation.cooldownLookahead
        or addon.DEFAULTS.cooldownLookahead
    if remaining <= lookahead then
        return true
    end

    -- Cooldown длительностью GCD не блокирует рекомендацию.
    return duration <= 1.6
end

function ReadinessService:IsSpellCooldownReady(entry)
    local remaining, duration, enabled = self:GetSpellCooldownRemaining(entry)
    return self:IsCooldownReady(remaining, duration, enabled)
end

function ReadinessService:IsEntryInRange(entry, category, provider, context)
    return provider:IsEntryInRange(self, entry, category, context)
end

function ReadinessService:IsEntryUsable(entry)
    local spell = GetEntrySpell(entry)
    if not spell or not IsUsableSpell then
        return false, false
    end

    local ok, usable, notEnoughPower = pcall(IsUsableSpell, spell)
    if not ok then
        return false, false
    end

    return usable, notEnoughPower
end

function ReadinessService:IsEntryReady(entry, category, provider, context)
    local usable, notEnoughPower = self:IsEntryUsable(entry)
    if not usable then
        if notEnoughPower then
            return false
        end

        if not provider:CanTreatUnusableAsUsable(category, entry, context) then
            return false
        end
    end

    if not self:IsEntryInRange(entry, category, provider, context) then
        return false
    end

    return self:IsSpellCooldownReady(entry)
end

function ReadinessService:GetDefaultReadyEntries(entries, category, provider, context)
    local readyEntries = {}
    local index

    for index = 1, #entries do
        local entry = entries[index]
        if self:IsEntryReady(entry, category, provider, context) then
            table.insert(readyEntries, entry)
        end
    end

    return readyEntries
end

function ReadinessService:GetReadyEntries(entries, category, provider, context)
    return provider:GetReadyEntries(self, entries, category, context)
end
