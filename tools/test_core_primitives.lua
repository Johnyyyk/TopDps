local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function AssertNear(actual, expected, epsilon, message)
    if math.abs(actual - expected) > epsilon then
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

local now = 100
GetTime = function()
    return now
end

UnitExists = function()
    return 1
end

TopDps = NewAddon()

dofile("Engine/CastService.lua")

local CastService = TopDps.CastService

local function TestLegacyCasting()
    UnitCastingInfo = function()
        return "Legacy Cast", "Rank", "Display", "legacy-icon", 100000, 102000, false, 42, true
    end
    UnitChannelInfo = function()
        return nil
    end

    local state = CastService:GetPlayerCastState()
    AssertEqual(state.name, "Legacy Cast", "legacy cast name")
    AssertEqual(state.icon, "legacy-icon", "legacy cast icon")
    AssertEqual(state.castId, 42, "legacy cast id")
    AssertEqual(state.notInterruptible, true, "legacy cast interrupt flag")
    AssertEqual(state.isChannel, false, "legacy cast type")
    AssertNear(state.remaining, 2, 0.0001, "legacy cast remaining")
end

local function TestLegacyChannelEightReturns()
    UnitCastingInfo = function()
        return nil
    end
    UnitChannelInfo = function()
        return "Legacy Channel", "Rank", "Display", "legacy-channel-icon", 100000, 103000, false, true
    end

    local state = CastService:GetPlayerCastState()
    AssertEqual(state.name, "Legacy Channel", "legacy channel name")
    AssertEqual(state.castId, nil, "legacy channel should not invent cast id")
    AssertEqual(state.notInterruptible, true, "legacy channel interrupt flag")
    AssertEqual(state.isChannel, true, "legacy channel type")
end

local function TestLegacyChannelPrivateNineReturns()
    UnitChannelInfo = function()
        return "Private Channel", "Rank", "Display", "private-icon", 100000, 103000, false, 77, true
    end

    local state = CastService:GetPlayerCastState()
    AssertEqual(state.castId, 77, "private legacy channel cast id")
    AssertEqual(state.notInterruptible, true, "private legacy channel interrupt flag")
end

local function TestModernCastingLayouts()
    UnitChannelInfo = function()
        return nil
    end
    UnitCastingInfo = function()
        return "Modern Cast", "Text", "modern-icon", 100000, 102000, false, 55, true, 12345
    end

    local state = CastService:GetPlayerCastState()
    AssertEqual(state.icon, "modern-icon", "modern cast icon")
    AssertEqual(state.castId, 55, "modern cast id")
    AssertEqual(state.spellId, 12345, "modern cast spell id")
    AssertEqual(state.notInterruptible, true, "modern cast interrupt flag")

    UnitCastingInfo = function()
        return "Modern Cast Short", "Text", "modern-icon", 100000, 102000, false, 56, 12346
    end

    state = CastService:GetPlayerCastState()
    AssertEqual(state.castId, 56, "short modern cast id")
    AssertEqual(state.spellId, 12346, "short modern cast spell id")
    AssertEqual(state.notInterruptible, false, "short modern cast absent interrupt flag")
end

local function TestModernChannelLayouts()
    UnitCastingInfo = function()
        return nil
    end
    UnitChannelInfo = function()
        return "Modern Channel", "Text", "modern-channel-icon", 100000, 103000, false, true, 22345
    end

    local state = CastService:GetPlayerCastState()
    AssertEqual(state.spellId, 22345, "modern channel spell id")
    AssertEqual(state.notInterruptible, true, "modern channel interrupt flag")

    UnitChannelInfo = function()
        return "Modern Channel Short", "Text", "modern-channel-icon", 100000, 103000, false, 22346
    end

    state = CastService:GetPlayerCastState()
    AssertEqual(state.spellId, 22346, "short modern channel spell id")
    AssertEqual(state.notInterruptible, false, "short modern channel absent interrupt flag")
end

local function TestChannelTicks()
    UnitChannelInfo = function()
        return "Tick Channel", "Rank", "Display", "icon", 100000, 103000, false, false
    end

    now = 101.1
    local state = CastService:GetPlayerCastState()
    local ticks = CastService:GetChannelTickState(state, 3)
    AssertEqual(ticks.completedTicks, 1, "completed channel ticks")
    AssertEqual(ticks.nextTickIndex, 2, "next channel tick")
    AssertNear(ticks.nextTickRemaining, 0.9, 0.0001, "next channel tick remaining")
    now = 100
end

TestLegacyCasting()
TestLegacyChannelEightReturns()
TestLegacyChannelPrivateNineReturns()
TestModernCastingLayouts()
TestModernChannelLayouts()
TestChannelTicks()

TopDps = NewAddon()

local playerGuid = "Player-1"
local mainSpeed = 3
local offSpeed = 2

UnitGUID = function(unit)
    if unit == "player" then
        return playerGuid
    end

    return nil
end

UnitAttackSpeed = function()
    return mainSpeed, offSpeed
end

IsCurrentAction = function(action)
    return action == 7 and 1 or nil
end

TopDps.SpecManager = {
    GetActive = function()
        return {
            abilities = {
                queued = {
                    swingReset = "MAIN_HAND",
                },
            },
            GetSpellCategory = function(_, spellId)
                if spellId == 5000 then
                    return "queued"
                end

                return nil
            end,
        }
    end,
}

dofile("Engine/SwingService.lua")

local SwingService = TopDps.SwingService

local function RecordUnknownSwing()
    SwingService:RecordCombatEvent(
        now,
        "SWING_DAMAGE",
        playerGuid,
        "Player",
        0,
        "Target-1",
        "Target",
        0,
        100,
        0,
        1,
        0,
        0,
        0,
        false,
        false,
        false
    )
end

local function TestDualWieldInference()
    SwingService:Clear()
    now = 0
    RecordUnknownSwing()
    AssertEqual(SwingService.mainHand.lastSwingAt, 0, "first unknown swing should seed main hand")
    AssertEqual(SwingService.offHand.lastSwingAt, nil, "first unknown swing should not seed off hand")

    now = 0.1
    RecordUnknownSwing()
    AssertEqual(SwingService.offHand.lastSwingAt, 0.1, "second unknown swing should seed off hand")
end

local function TestExplicitOffHand()
    SwingService:Clear()
    now = 2
    SwingService:RecordCombatEvent(
        now,
        "SWING_DAMAGE",
        playerGuid,
        "Player",
        0,
        "Target-1",
        "Target",
        0,
        100,
        0,
        1,
        0,
        0,
        0,
        false,
        false,
        false,
        true
    )
    AssertEqual(SwingService.offHand.lastSwingAt, 2, "explicit off-hand swing")
    AssertEqual(SwingService.mainHand.lastSwingAt, nil, "explicit off-hand should not touch main hand")
end

local function TestAttackSpeedRescale()
    SwingService:Clear()
    mainSpeed = 3
    offSpeed = 0
    now = 0
    SwingService:RecordSwing(false)

    now = 1
    mainSpeed = 2
    SwingService:HandleAttackSpeedChanged("player")
    local state = SwingService:GetState()
    AssertNear(state.mainHand.remaining, 4 / 3, 0.0001, "haste should preserve swing progress")
end

local function TestAbilitySwingReset()
    SwingService:Clear()
    mainSpeed = 3
    offSpeed = 0
    now = 5
    SwingService:RecordCombatEvent(
        now,
        "SPELL_DAMAGE",
        playerGuid,
        "Player",
        0,
        "Target-1",
        "Target",
        0,
        5000,
        "Queued Strike",
        1,
        100,
        0,
        1,
        0,
        0,
        0,
        false,
        false,
        false
    )

    AssertEqual(SwingService.mainHand.lastSwingAt, 5, "ability swing reset")
    AssertNear(SwingService.mainHand.nextSwingAt, 8, 0.0001, "ability swing reset next swing")
    AssertEqual(SwingService:IsActionQueued(7), true, "queued action detection")
end

TestDualWieldInference()
TestExplicitOffHand()
TestAttackSpeedRescale()
TestAbilitySwingReset()

print("core primitive smoke tests passed")
