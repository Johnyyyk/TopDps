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

function UnitStateService:GetPowerState(unit, requestedPowerType)
    if not HasUnit(unit) then
        local state = BuildValueState(0, 0)
        state.type = requestedPowerType
        state.activeType = nil
        state.token = nil
        return state
    end

    local activePowerType, powerToken = self:GetPowerType(unit)
    local powerType = requestedPowerType
    if powerType == nil then
        powerType = activePowerType
    end

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
    state.activeType = activePowerType
    state.token = powerType == activePowerType and powerToken or nil

    return state
end

function UnitStateService:GetPlayerPowerRegen()
    if not GetPowerRegen then
        return {
            base = 0,
            casting = 0,
        }
    end

    local ok, base, casting = pcall(GetPowerRegen)
    if not ok then
        return {
            base = 0,
            casting = 0,
        }
    end

    return {
        base = tonumber(base) or 0,
        casting = tonumber(casting) or 0,
    }
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
    local isPlayer = exists and UnitIsPlayer and IsApiTrue(UnitIsPlayer(unit)) or false
    local connected = exists
    local className
    local classToken

    if isPlayer and UnitIsConnected then
        connected = IsApiTrue(UnitIsConnected(unit))
    end

    if exists and UnitClass then
        className, classToken = UnitClass(unit)
    end

    local dead = exists and IsApiTrue(UnitIsDead(unit)) or false
    local deadOrGhost = dead
    if exists and UnitIsDeadOrGhost then
        deadOrGhost = IsApiTrue(UnitIsDeadOrGhost(unit))
    end

    return {
        unit = unit,
        exists = exists,
        connected = connected,
        guid = exists and UnitGUID(unit) or nil,
        level = exists and UnitLevel(unit) or nil,
        className = className,
        classToken = classToken,
        classification = exists and UnitClassification(unit) or nil,
        creatureType = exists and UnitCreatureType(unit) or nil,
        health = health,
        power = power,
        dead = dead,
        deadOrGhost = deadOrGhost,
        inCombat = exists and UnitAffectingCombat and IsApiTrue(UnitAffectingCombat(unit)) or false,
        isPlayer = isPlayer,
        attackable = exists and UnitCanAttack and IsApiTrue(UnitCanAttack("player", unit)) or false,
        assistable = exists and UnitCanAssist and IsApiTrue(UnitCanAssist("player", unit)) or false,
        bossLike = exists and self:IsBossLike(unit) or false,
    }
end

function UnitStateService:GetPlayerSnapshot()
    local snapshot = self:GetUnitSnapshot("player")
    snapshot.comboPoints = self:GetComboPoints("player", "target")
    snapshot.power.regen = self:GetPlayerPowerRegen()

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
