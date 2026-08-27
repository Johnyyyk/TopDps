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

local function PackValues(...)
    return {
        count = select("#", ...),
        ...,
    }
end

local function UsesLegacyLayout(values)
    local startTime = tonumber(values[5]) or 0
    local endTime = tonumber(values[6]) or 0
    return startTime > 1000 and endTime > 1000
end

local function BuildCastState(unit, isChannel, values)
    local name = values[1]
    if not name then
        return nil
    end

    local legacy = UsesLegacyLayout(values)
    local icon
    local startTimeMs
    local endTimeMs
    local castId
    local notInterruptible
    local spellId

    if legacy then
        icon = values[4]
        startTimeMs = values[5]
        endTimeMs = values[6]

        if isChannel then
            -- Оригинальный WotLK layout обычно заканчивается
            -- notInterruptible восьмым значением. Некоторые private cores
            -- дополнительно возвращают castId перед ним.
            if values.count >= 9 then
                castId = values[8]
                notInterruptible = values[9]
            else
                notInterruptible = values[8]
            end
        else
            castId = values[8]
            notInterruptible = values[9]
        end
    elseif isChannel then
        icon = values[3]
        startTimeMs = values[4]
        endTimeMs = values[5]

        if values.count >= 8 then
            notInterruptible = values[7]
            spellId = tonumber(values[8])
        else
            -- Некоторые Classic API удаляли notInterruptible полностью,
            -- сдвигая spellId на его позицию.
            spellId = tonumber(values[7])
        end
    else
        icon = values[3]
        startTimeMs = values[4]
        endTimeMs = values[5]
        castId = values[7]

        if values.count >= 9 then
            notInterruptible = values[8]
            spellId = tonumber(values[9])
        else
            spellId = tonumber(values[8])
        end
    end

    local startTime = math.max(0, (tonumber(startTimeMs) or 0) / 1000)
    local endTime = math.max(0, (tonumber(endTimeMs) or 0) / 1000)
    local now = GetTime()

    return {
        unit = unit,
        active = true,
        name = name,
        icon = icon,
        spellId = spellId,
        castId = castId,
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

    return BuildCastState(unit, false, PackValues(UnitCastingInfo(unit)))
end

function CastService:GetChannelState(unit)
    if not UnitChannelInfo then
        return nil
    end

    return BuildCastState(unit, true, PackValues(UnitChannelInfo(unit)))
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

function CastService:GetChannelTickState(state, tickCount)
    local count = math.floor(tonumber(tickCount) or 0)
    if not state or not state.active or not state.isChannel or count <= 0 then
        return nil
    end

    local duration = math.max(0, tonumber(state.duration) or 0)
    if duration <= 0 then
        return nil
    end

    local tickDuration = duration / count
    local now = GetTime()
    local elapsed = math.max(0, math.min(duration, now - (tonumber(state.startTime) or now)))
    local completedTicks = math.floor(elapsed / tickDuration)
    if completedTicks > count then
        completedTicks = count
    end

    local nextTickIndex
    local nextTickAt
    local nextTickRemaining = 0
    if completedTicks < count then
        nextTickIndex = completedTicks + 1
        nextTickAt = state.startTime + nextTickIndex * tickDuration
        nextTickRemaining = math.max(0, nextTickAt - now)
    end

    return {
        tickCount = count,
        tickDuration = tickDuration,
        completedTicks = completedTicks,
        nextTickIndex = nextTickIndex,
        nextTickAt = nextTickAt,
        nextTickRemaining = nextTickRemaining,
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
