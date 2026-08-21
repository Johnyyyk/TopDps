local addon = TopDps
local UnitStateService = addon:CreateModule("UnitStateService")

local function IsApiTrue(value)
    return value == true or value == 1
end

local function HasUnit(unit)
    if not unit or not UnitExists then
        return false
    end

    return IsApiTrue(UnitExists(unit))
end

local function ClampFraction(value)
    if value < 0 then
        return 0
    end

    if value > 1 then
        return 1
    end

    return value
end

local function BuildValueState(current, maximum)
    current = math.max(0, tonumber(current) or 0)
    maximum = math.max(0, tonumber(maximum) or 0)

    local fraction = 0
    if maximum > 0 then
        fraction = ClampFraction(current / maximum)
    end

    return {
        current = current,
        maximum = maximum,
        missing = math.max(0, maximum - current),
        fraction = fraction,
        percent = fraction * 100,
    }
end

function UnitStateService:GetHealthState(unit)
    if not HasUnit(unit) then
        return BuildValueState(0, 0)
    end

    return BuildValueState(UnitHealth(unit), UnitHealthMax(unit))
end

function UnitStateService:GetPowerType(unit)
    if not HasUnit(unit) or not UnitPowerType then
        return nil, nil
    end

    local powerType, powerToken = UnitPowerType(unit)
    return tonumber(powerType), powerToken
end

function UnitStateService:GetPowerState(unit)
    if not HasUnit(unit) then
        local state = BuildValueState(0, 0)
        state.type = nil
        state.token = nil
        return state
    end

    local powerType, powerToken = self:GetPowerType(unit)
    local current
    local maximum

    if UnitPower and UnitPowerMax then
        if powerType ~= nil then
            current = UnitPower(unit, powerType)
            maximum = UnitPowerMax(unit, powerType)
        else
            current = UnitPower(unit)
            maximum = UnitPowerMax(unit)
        end
    elseif UnitMana and UnitManaMax then
        current = UnitMana(unit)
        maximum = UnitManaMax(unit)
    else
        current = 0
        maximum = 0
    end

    local state = BuildValueState(current, maximum)
    state.type = powerType
    state.token = powerToken

    return state
end

function UnitStateService:GetComboPoints(sourceUnit, targetUnit)
    if not GetComboPoints then
        return 0
    end

    local source = sourceUnit or "player"
    local target = targetUnit or "target"
    local ok, points = pcall(GetComboPoints, source, target)
    if not ok then
        return 0
    end

    return math.max(0, tonumber(points) or 0)
end

function UnitStateService:IsBossLike(unit)
    if not HasUnit(unit) then
        return false
    end

    if UnitLevel(unit) == -1 then
        return true
    end

    return UnitClassification(unit) == "worldboss"
end

function UnitStateService:GetUnitSnapshot(unit)
    local exists = HasUnit(unit)
    local health = self:GetHealthState(unit)
    local power = self:GetPowerState(unit)

    return {
        unit = unit,
        exists = exists,
        guid = exists and UnitGUID(unit) or nil,
        level = exists and UnitLevel(unit) or nil,
        classification = exists and UnitClassification(unit) or nil,
        creatureType = exists and UnitCreatureType(unit) or nil,
        health = health,
        power = power,
        dead = exists and IsApiTrue(UnitIsDead(unit)) or false,
        attackable = exists and IsApiTrue(UnitCanAttack("player", unit)) or false,
        bossLike = exists and self:IsBossLike(unit) or false,
    }
end

function UnitStateService:GetPlayerSnapshot()
    local snapshot = self:GetUnitSnapshot("player")
    snapshot.comboPoints = self:GetComboPoints("player", "target")

    return snapshot
end

function UnitStateService:GetTargetSnapshot()
    return self:GetUnitSnapshot("target")
end

function UnitStateService:IsHealthAtOrBelow(unit, fraction)
    local threshold = ClampFraction(tonumber(fraction) or 0)
    local health = self:GetHealthState(unit)
    return health.maximum > 0 and health.fraction <= threshold
end
