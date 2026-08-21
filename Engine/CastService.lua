local addon = TopDps
local CastService = addon:CreateModule("CastService")

local function IsApiTrue(value)
    return value == true or value == 1
end

local function HasUnit(unit)
    if not unit or not UnitExists then
        return false
    end

    return IsApiTrue(UnitExists(unit))
end

local function BuildCastState(unit, isChannel, name, icon, startTimeMs, endTimeMs, notInterruptible)
    local startTime = math.max(0, (tonumber(startTimeMs) or 0) / 1000)
    local endTime = math.max(0, (tonumber(endTimeMs) or 0) / 1000)
    local now = GetTime()

    return {
        unit = unit,
        active = name ~= nil,
        name = name,
        icon = icon,
        isChannel = isChannel == true,
        startTime = startTime,
        endTime = endTime,
        duration = math.max(0, endTime - startTime),
        remaining = math.max(0, endTime - now),
        notInterruptible = IsApiTrue(notInterruptible),
    }
end

function CastService:GetCastingState(unit)
    if not UnitCastingInfo then
        return nil
    end

    local name, _, _, icon, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    if not name then
        return nil
    end

    return BuildCastState(unit, false, name, icon, startTime, endTime, notInterruptible)
end

function CastService:GetChannelState(unit)
    if not UnitChannelInfo then
        return nil
    end

    local name, _, _, icon, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
    if not name then
        return nil
    end

    return BuildCastState(unit, true, name, icon, startTime, endTime, notInterruptible)
end

function CastService:GetUnitCastState(unit)
    if not HasUnit(unit) then
        return {
            unit = unit,
            active = false,
            isChannel = false,
            remaining = 0,
            duration = 0,
        }
    end

    local cast = self:GetCastingState(unit)
    if cast then
        return cast
    end

    local channel = self:GetChannelState(unit)
    if channel then
        return channel
    end

    return {
        unit = unit,
        active = false,
        isChannel = false,
        remaining = 0,
        duration = 0,
    }
end

function CastService:GetPlayerCastState()
    return self:GetUnitCastState("player")
end

function CastService:IsPlayerCasting()
    local state = self:GetPlayerCastState()
    return state.active and not state.isChannel
end

function CastService:IsPlayerChanneling()
    local state = self:GetPlayerCastState()
    return state.active and state.isChannel
end
