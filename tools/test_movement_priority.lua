local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function AssertSequence(actual, expected, message)
    AssertEqual(#actual, #expected, (message or "sequence") .. " length")

    local index
    for index = 1, #expected do
        AssertEqual(actual[index], expected[index], (message or "sequence") .. " item " .. tostring(index))
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

TopDps = NewAddon()
TopDps.REFRESH_LEAD_CAST_TIME = "CAST_TIME"
TopDps.SpecProvider = {}
TopDps.SpecRegistry = {
    providers = {},
}

function TopDps.SpecProvider:Create(definition)
    definition.testSettings = {
        curseMode = "auto",
        useMovementPriority = true,
    }

    function definition:GetSetting(key)
        return self.testSettings[key]
    end

    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

dofile("Specs/Warlock/Common.lua")

local Warlock = TopDps.Warlock
Warlock.HasPlayerAura = function()
    return false
end
Warlock.HasSpellCritDebuff = function()
    return false
end
Warlock.HasOwnTargetAura = function()
    return false
end

dofile("Specs/Warlock/Demonology.lua")
dofile("Specs/Warlock/Destruction.lua")

local Demonology = TopDps.SpecRegistry.providers.WARLOCK_DEMONOLOGY
local Destruction = TopDps.SpecRegistry.providers.WARLOCK_DESTRUCTION
local movingContext = {
    player = {
        movement = {
            moving = true,
        },
    },
}
local stationaryContext = {
    player = {
        movement = {
            moving = false,
        },
    },
}

local function FindSetting(provider, key)
    local index
    for index = 1, #(provider.settings or {}) do
        local setting = provider.settings[index]
        if setting.key == key then
            return setting
        end
    end

    return nil
end

local function TestMovementSettingDefaults()
    local demoSetting = FindSetting(Demonology, "useMovementPriority")
    local destroSetting = FindSetting(Destruction, "useMovementPriority")

    AssertEqual(demoSetting ~= nil, true, "demo movement setting")
    AssertEqual(demoSetting.default, true, "demo movement setting default")
    AssertEqual(destroSetting ~= nil, true, "destro movement setting")
    AssertEqual(destroSetting.default, true, "destro movement setting default")
end

local function TestDemonologyMovementPriority()
    AssertSequence(
        Demonology:GetPriority(movingContext),
        { "lifeTap", "curse", "corruption" },
        "demo moving priority"
    )

    Demonology.testSettings.useMovementPriority = false
    local priority = Demonology:GetPriority(movingContext)
    AssertEqual(priority[5], "shadowBolt", "demo disabled movement priority should use regular rotation")
    Demonology.testSettings.useMovementPriority = true
end

local function TestDestructionMovementPriority()
    AssertSequence(
        Destruction:GetPriority(movingContext),
        { "lifeTap", "curse", "conflagrate", "incinerate", "corruption" },
        "destro moving priority"
    )

    AssertEqual(Destruction:IsCategoryAllowed("incinerate", movingContext), false, "destro moving Incinerate without Backlash")
    AssertEqual(Destruction:IsCategoryAllowed("corruption", movingContext), true, "destro moving corruption")
    AssertEqual(Destruction:IsCategoryAllowed("corruption", stationaryContext), false, "destro stationary corruption")

    Destruction.testSettings.useMovementPriority = false
    AssertSequence(
        Destruction:GetPriority(movingContext),
        { "lifeTap", "curse", "immolate", "conflagrate", "chaosBolt", "incinerate" },
        "destro disabled movement priority"
    )
    AssertEqual(
        Destruction:IsCategoryAllowed("corruption", movingContext),
        false,
        "destro disabled movement corruption"
    )
    Destruction.testSettings.useMovementPriority = true
end

TestMovementSettingDefaults()
TestDemonologyMovementPriority()
TestDestructionMovementPriority()

print("movement priority smoke tests passed")
