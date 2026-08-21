local addon = TopDps
local SwingService = addon:CreateModule("SwingService")

SwingService.mainHand = SwingService.mainHand or {}
SwingService.offHand = SwingService.offHand or {}

local SWING_EVENTS = {
    SWING_DAMAGE = true,
    SWING_MISSED = true,
}

local function FindLastBoolean(...)
    local index
    for index = select("#", ...), 1, -1 do
        local value = select(index, ...)
        if type(value) == "boolean" then
            return value
        end
    end

    return false
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

function SwingService:GetAttackSpeeds()
    if not UnitAttackSpeed then
        return 0, 0
    end

    local mainHandSpeed, offHandSpeed = UnitAttackSpeed("player")
    return math.max(0, tonumber(mainHandSpeed) or 0), math.max(0, tonumber(offHandSpeed) or 0)
end

function SwingService:RecordSwing(isOffHand)
    local now = GetTime()
    local mainHandSpeed, offHandSpeed = self:GetAttackSpeeds()
    local hand = isOffHand and self.offHand or self.mainHand
    local speed = isOffHand and offHandSpeed or mainHandSpeed

    hand.lastSwingAt = now
    hand.nextSwingAt = speed > 0 and now + speed or nil
end

function SwingService:RecordCombatEvent(...)
    local _, eventType, sourceGuid = ...
    if not SWING_EVENTS[eventType] or sourceGuid ~= UnitGUID("player") then
        return
    end

    self:RecordSwing(FindLastBoolean(...))
end

function SwingService:HandleAttackSpeedChanged(unit)
    if unit ~= "player" then
        return
    end

    local now = GetTime()
    local mainHandSpeed, offHandSpeed = self:GetAttackSpeeds()

    if self.mainHand.lastSwingAt and mainHandSpeed > 0 then
        self.mainHand.nextSwingAt = self.mainHand.lastSwingAt + mainHandSpeed
        if self.mainHand.nextSwingAt < now then
            self.mainHand.nextSwingAt = now
        end
    end

    if self.offHand.lastSwingAt and offHandSpeed > 0 then
        self.offHand.nextSwingAt = self.offHand.lastSwingAt + offHandSpeed
        if self.offHand.nextSwingAt < now then
            self.offHand.nextSwingAt = now
        end
    end
end

function SwingService:IsActionQueued(action)
    if not action or not IsCurrentAction then
        return false
    end

    local ok, current = pcall(IsCurrentAction, action)
    return ok and (current == true or current == 1)
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
