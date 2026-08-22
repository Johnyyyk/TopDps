local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = {
        Modules = {},
    }

    function addon:CreateModule(name)
        local module = self.Modules[name]
        if module then
            return module
        end

        module = {}
        self.Modules[name] = module
        self[name] = module
        return module
    end

    return addon
end

local function InstallUnitStateStubs()
    UnitExists = function()
        return 1
    end
    UnitHealth = function()
        return 100
    end
    UnitHealthMax = function()
        return 100
    end
    UnitPowerType = function()
        return 0, "MANA"
    end
    UnitPower = function()
        return 100
    end
    UnitPowerMax = function()
        return 100
    end
    GetPowerRegen = function()
        return 1, 0.5
    end
    GetComboPoints = function()
        return 0
    end
    UnitIsPlayer = function()
        return 1
    end
    UnitIsConnected = function()
        return 1
    end
    UnitClass = function()
        return "Warlock", "WARLOCK"
    end
    UnitIsDead = function()
        return nil
    end
    UnitIsDeadOrGhost = function()
        return nil
    end
    UnitGUID = function()
        return "Player-1"
    end
    UnitLevel = function()
        return 80
    end
    UnitClassification = function()
        return "normal"
    end
    UnitCreatureType = function()
        return "Humanoid"
    end
    UnitAffectingCombat = function()
        return 1
    end
    UnitCanAttack = function()
        return 1
    end
end

InstallUnitStateStubs()
TopDps = NewAddon()
dofile("Engine/UnitStateService.lua")

local UnitStateService = TopDps.UnitStateService

local function TestStationaryMovement()
    GetUnitSpeed = function()
        return 0
    end
    IsFalling = function()
        return false
    end

    local snapshot = UnitStateService:GetPlayerSnapshot()
    AssertEqual(snapshot.movement.speed, 0, "stationary speed")
    AssertEqual(snapshot.movement.moving, false, "stationary movement")
    AssertEqual(snapshot.movement.falling, false, "stationary falling")
end

local function TestMovingMovement()
    GetUnitSpeed = function()
        return 7
    end
    IsFalling = function()
        return false
    end

    local movement = UnitStateService:GetMovementState("player")
    AssertEqual(movement.speed, 7, "moving speed")
    AssertEqual(movement.moving, true, "moving state")
    AssertEqual(movement.falling, false, "moving falling")
end

local function TestFallingMovement()
    GetUnitSpeed = function()
        return 0
    end
    IsFalling = function()
        return true
    end

    local movement = UnitStateService:GetMovementState("player")
    AssertEqual(movement.moving, true, "falling should count as moving")
    AssertEqual(movement.falling, true, "falling state")
end

local function TestLegacyIsFallingFallback()
    GetUnitSpeed = function()
        return 0
    end
    IsFalling = function(...)
        if select("#", ...) > 0 then
            error("Usage: IsFalling()")
        end

        return true
    end

    local movement = UnitStateService:GetMovementState("player")
    AssertEqual(movement.moving, true, "legacy falling should count as moving")
    AssertEqual(movement.falling, true, "legacy falling fallback")
end

local function TestMovementApiUnavailable()
    GetUnitSpeed = nil
    IsFalling = nil

    local movement = UnitStateService:GetMovementState("player")
    AssertEqual(movement.speed, 0, "missing speed API fallback")
    AssertEqual(movement.moving, false, "missing movement API fallback")
    AssertEqual(movement.falling, false, "missing falling API fallback")
end

TestStationaryMovement()
TestMovingMovement()
TestFallingMovement()
TestLegacyIsFallingFallback()
TestMovementApiUnavailable()

print("movement priority smoke tests passed")
