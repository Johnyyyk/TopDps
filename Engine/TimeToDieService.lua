local addon = TopDps
local TimeToDieService = addon:CreateModule("TimeToDieService")

local SAMPLE_INTERVAL = 0.5
local MAX_SAMPLE_GAP = 1.5
local WINDOW_SECONDS = 6
local MIN_SAMPLES = 5
local MIN_SPAN = 2
local HEAL_RESET_FRACTION = 0.02
local MIN_LOSS_FRACTION_PER_SECOND = 0.001

local function IsApiTrue(value)
    return value == true or value == 1
end

local function ReadTime()
    if not GetTime then
        return nil
    end

    local ok, value = pcall(GetTime)
    if not ok then
        return nil
    end

    return tonumber(value)
end

local function ReadUnit(unit)
    if not unit or not UnitExists or not UnitGUID or not UnitHealth or not UnitHealthMax then
        return nil
    end

    local okExists, exists = pcall(UnitExists, unit)
    if not okExists or not IsApiTrue(exists) then
        return nil
    end

    local okGuid, guid = pcall(UnitGUID, unit)
    if not okGuid or not guid then
        return nil
    end

    local okHealth, health = pcall(UnitHealth, unit)
    local okMaximum, maximum = pcall(UnitHealthMax, unit)
    if not okHealth or not okMaximum then
        return nil
    end

    health = math.max(0, tonumber(health) or 0)
    maximum = math.max(0, tonumber(maximum) or 0)
    if maximum <= 0 then
        return nil
    end

    local deadOrGhost = health <= 0
    if UnitIsDeadOrGhost then
        local okDead, result = pcall(UnitIsDeadOrGhost, unit)
        if okDead then
            deadOrGhost = deadOrGhost or IsApiTrue(result)
        end
    end

    return {
        guid = guid,
        health = health,
        maximum = maximum,
        deadOrGhost = deadOrGhost,
    }
end

local function CreateState(guid, maximum, now, health)
    return {
        guid = guid,
        maximum = maximum,
        samples = {
            {
                time = now,
                health = health,
            },
        },
        lastSampleAt = now,
        estimate = nil,
    }
end

local function TrimSamples(samples, now)
    while #samples > 1 and now - samples[1].time > WINDOW_SECONDS do
        table.remove(samples, 1)
    end
end

local function CalculateEstimate(samples, maximum, currentHealth)
    if #samples < MIN_SAMPLES then
        return nil, false
    end

    local firstTime = samples[1].time
    local lastTime = samples[#samples].time
    if lastTime - firstTime < MIN_SPAN then
        return nil, false
    end

    local count = #samples
    local sumX = 0
    local sumY = 0
    local index

    for index = 1, count do
        sumX = sumX + (samples[index].time - firstTime)
        sumY = sumY + samples[index].health
    end

    local meanX = sumX / count
    local meanY = sumY / count
    local numerator = 0
    local denominator = 0

    for index = 1, count do
        local x = (samples[index].time - firstTime) - meanX
        local y = samples[index].health - meanY
        numerator = numerator + x * y
        denominator = denominator + x * x
    end

    if denominator <= 0 then
        return nil, false
    end

    local slope = numerator / denominator
    if slope >= 0 then
        return nil, true
    end

    local lossFractionPerSecond = (-slope) / maximum
    if lossFractionPerSecond < MIN_LOSS_FRACTION_PER_SECOND then
        return nil, false
    end

    return currentHealth / (-slope), false
end

function TimeToDieService:Reset()
    self.state = nil
end

function TimeToDieService:GetEstimate(unit)
    local snapshot = ReadUnit(unit)
    if not snapshot then
        self:Reset()
        return nil
    end

    if snapshot.deadOrGhost or snapshot.health <= 0 then
        self:Reset()
        return 0
    end

    local now = ReadTime()
    if not now then
        self:Reset()
        return nil
    end

    local state = self.state
    if not state
        or state.guid ~= snapshot.guid
        or state.maximum ~= snapshot.maximum
        or now < state.lastSampleAt
        or now - state.lastSampleAt > MAX_SAMPLE_GAP then
        self.state = CreateState(snapshot.guid, snapshot.maximum, now, snapshot.health)
        return nil
    end

    if now - state.lastSampleAt < SAMPLE_INTERVAL then
        return state.estimate
    end

    local lastSample = state.samples[#state.samples]
    local healing = snapshot.health - lastSample.health
    if healing >= snapshot.maximum * HEAL_RESET_FRACTION then
        self.state = CreateState(snapshot.guid, snapshot.maximum, now, snapshot.health)
        return nil
    end

    table.insert(state.samples, {
        time = now,
        health = snapshot.health,
    })
    state.lastSampleAt = now
    TrimSamples(state.samples, now)

    local estimate, resetTrend = CalculateEstimate(
        state.samples,
        snapshot.maximum,
        snapshot.health
    )

    if resetTrend then
        self.state = CreateState(snapshot.guid, snapshot.maximum, now, snapshot.health)
        return nil
    end

    state.estimate = estimate
    return estimate
end
