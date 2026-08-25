local addon = TopDps
local SwingService = addon:CreateModule("SwingService")

SwingService.mainHand = SwingService.mainHand or {}
SwingService.offHand = SwingService.offHand or {}

local SWING_EVENTS = {
    SWING_DAMAGE = true,
    SWING_MISSED = true,
}

local SWING_RESET_EVENTS = {
    SPELL_DAMAGE = true,
    SPELL_MISSED = true,
}

local function IsApiTrue(value)
    return value == true or value == 1
end

local function GetExplicitOffHandFlag(eventType, ...)
    local argumentCount = select("#", ...)

    if eventType == "SWING_DAMAGE" then
        if argumentCount < 18 then
            return nil
        end

        local value = select(18, ...)
        if type(value) == "boolean" or value == 0 or value == 1 then
            return IsApiTrue(value)
        end

        return nil
    end

    if eventType == "SWING_MISSED" then
        if argumentCount < 10 then
            return nil
        end

        local value = select(10, ...)
        if type(value) == "boolean" then
            return value
        end

        -- На части ядер numeric 0/1 можно отличить от amountMissed
        -- только когда после него присутствует ещё один swing-аргумент.
        if argumentCount >= 11 and (value == 0 or value == 1) then
            return IsApiTrue(value)
        end
    end

    return nil
end

local function BuildHandState(hand, speed, now)
    local nextSwingAt = tonumber(hand.nextSwingAt)
    local remaining = 0
    if nextSwingAt then
        remaining = math.max(0, nextSwingAt - now)
    end

    return {
        speed = math.max(0, tonumber(speed) or 0),
        lastSwingAt = hand.lastSwingAt,
        nextSwingAt = nextSwingAt,
        remaining = remaining,
    }
end

local function RescaleSwingTimer(hand, newSpeed, now)
    local oldSpeed = math.max(0, tonumber(hand.speed) or 0)
    newSpeed = math.max(0, tonumber(newSpeed) or 0)

    if not hand.lastSwingAt or not hand.nextSwingAt or oldSpeed <= 0 or newSpeed <= 0 then
        hand.speed = newSpeed
        return
    end

    local oldRemaining = math.max(0, hand.nextSwingAt - now)
    local remainingFraction = math.min(1, oldRemaining / oldSpeed)
    hand.nextSwingAt = now + remainingFraction * newSpeed
    hand.speed = newSpeed
end

function SwingService:GetAttackSpeeds()
    if not UnitAttackSpeed then
        return 0, 0
    end

    local mainHandSpeed, offHandSpeed = UnitAttackSpeed("player")
    return math.max(0, tonumber(mainHandSpeed) or 0), math.max(0, tonumber(offHandSpeed) or 0)
end

function SwingService:ResolveOffHand(explicitOffHand)
    if explicitOffHand ~= nil then
        return explicitOffHand == true
    end

    local _, offHandSpeed = self:GetAttackSpeeds()
    if offHandSpeed <= 0 then
        return false
    end

    if not self.mainHand.lastSwingAt then
        return false
    end

    if not self.offHand.lastSwingAt then
        return true
    end

    local mainNext = tonumber(self.mainHand.nextSwingAt) or math.huge
    local offNext = tonumber(self.offHand.nextSwingAt) or math.huge
    return offNext < mainNext
end

function SwingService:GetAbilitySwingReset(spellId, spellName)
    local provider = addon.SpecManager and addon.SpecManager:GetActive() or nil
    if not provider then
        return nil
    end

    local category = provider:GetSpellCategory(spellId, spellName)
    local ability = category and provider.abilities and provider.abilities[category] or nil
    return ability and ability.swingReset or nil
end

function SwingService:RecordSwing(isOffHand)
    local now = GetTime()
    local mainHandSpeed, offHandSpeed = self:GetAttackSpeeds()
    local hand = isOffHand and self.offHand or self.mainHand
    local speed = isOffHand and offHandSpeed or mainHandSpeed

    hand.speed = speed
    hand.lastSwingAt = now
    hand.nextSwingAt = speed > 0 and now + speed or nil
end

function SwingService:RecordAbilitySwingReset(spellId, spellName)
    local reset = self:GetAbilitySwingReset(spellId, spellName)
    if reset == "MAIN_HAND" then
        self:RecordSwing(false)
    elseif reset == "OFF_HAND" then
        self:RecordSwing(true)
    elseif reset == "BOTH" then
        self:RecordSwing(false)
        self:RecordSwing(true)
    end
end

function SwingService:RecordCombatEvent(...)
    local _, eventType, sourceGuid = ...
    if sourceGuid ~= UnitGUID("player") then
        return
    end

    if SWING_EVENTS[eventType] then
        local explicitOffHand = GetExplicitOffHandFlag(eventType, ...)
        self:RecordSwing(self:ResolveOffHand(explicitOffHand))
        return
    end

    if SWING_RESET_EVENTS[eventType] then
        local spellId = tonumber((select(9, ...)))
        local spellName = select(10, ...)
        self:RecordAbilitySwingReset(spellId, spellName)
    end
end

function SwingService:HandleAttackSpeedChanged(unit)
    if unit ~= "player" then
        return
    end

    local now = GetTime()
    local mainHandSpeed, offHandSpeed = self:GetAttackSpeeds()
    RescaleSwingTimer(self.mainHand, mainHandSpeed, now)
    RescaleSwingTimer(self.offHand, offHandSpeed, now)
end

function SwingService:IsActionQueued(action)
    if not action or not IsCurrentAction then
        return false
    end

    local ok, current = pcall(IsCurrentAction, action)
    return ok and IsApiTrue(current)
end

function SwingService:GetQueuedNextSwingCategory(provider, actionsByCategory)
    local categories = provider and provider:GetNextSwingCategories() or nil
    local categoryIndex

    for categoryIndex = 1, #(categories or {}) do
        local category = categories[categoryIndex]
        local entries = actionsByCategory and actionsByCategory[category] or nil
        local entryIndex

        for entryIndex = 1, #(entries or {}) do
            if self:IsActionQueued(entries[entryIndex].action) then
                return category
            end
        end
    end

    return nil
end

function SwingService:IsNextSwingQueued(provider, actionsByCategory)
    return self:GetQueuedNextSwingCategory(provider, actionsByCategory) ~= nil
end

function SwingService:GetState()
    local now = GetTime()
    local mainHandSpeed, offHandSpeed = self:GetAttackSpeeds()

    return {
        mainHand = BuildHandState(self.mainHand, mainHandSpeed, now),
        offHand = BuildHandState(self.offHand, offHandSpeed, now),
    }
end

function SwingService:Clear()
    self.mainHand = {}
    self.offHand = {}
end
