local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function AssertNear(actual, expected, epsilon, message)
    if actual == nil or math.abs(actual - expected) > epsilon then
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

local now = 0
local guid = "Target-A"
local health = 1000
local maximum = 1000
local dead = false
local exists = true

GetTime = function()
    return now
end
UnitExists = function()
    return exists and 1 or nil
end
UnitGUID = function()
    return guid
end
UnitHealth = function()
    return health
end
UnitHealthMax = function()
    return maximum
end
UnitIsDeadOrGhost = function()
    return dead and 1 or nil
end

TopDps = NewAddon()
dofile("Engine/TimeToDieService.lua")

local service = TopDps.TimeToDieService

local function ResetTarget()
    now = 0
    guid = "Target-A"
    health = 1000
    maximum = 1000
    dead = false
    exists = true
    service:Reset()
end

local function Sample(nextHealth, advance)
    now = now + (advance or 0.5)
    health = nextHealth
    return service:GetEstimate("target")
end

ResetTarget()
AssertEqual(service:GetEstimate("target"), nil, "first sample")
AssertEqual(Sample(950), nil, "second sample")
AssertEqual(Sample(900), nil, "third sample")
AssertEqual(Sample(850), nil, "fourth sample")
AssertNear(Sample(800), 8, 0.01, "stable decline estimate")

ResetTarget()
service:GetEstimate("target")
Sample(975)
Sample(950)
AssertEqual(Sample(925), nil, "insufficient sample span")

ResetTarget()
service:GetEstimate("target")
Sample(950)
Sample(900)
Sample(850)
AssertNear(Sample(800), 8, 0.01, "estimate before target switch")
guid = "Target-B"
health = 700
AssertEqual(Sample(700), nil, "target switch resets history")

ResetTarget()
service:GetEstimate("target")
Sample(950)
Sample(900)
Sample(850)
AssertNear(Sample(800), 8, 0.01, "estimate before healing")
AssertEqual(Sample(850), nil, "significant healing resets history")
AssertEqual(Sample(840), nil, "history restarts after healing")

ResetTarget()
health = 850
service:GetEstimate("target")
Sample(860)
Sample(870)
Sample(880)
AssertEqual(Sample(890), nil, "non-negative trend has no estimate")
AssertEqual(Sample(880), nil, "non-negative trend resets history")

ResetTarget()
maximum = 1200
service:GetEstimate("target")
Sample(1140)
maximum = 1000
health = 900
AssertEqual(Sample(900), nil, "maximum health change resets history")

ResetTarget()
service:GetEstimate("target")
Sample(950)
Sample(900)
Sample(850)
AssertNear(Sample(800), 8, 0.01, "estimate before observation gap")
AssertEqual(Sample(600, 2), nil, "observation gap resets history")
AssertEqual(Sample(550), nil, "history restarts after observation gap")

ResetTarget()
dead = true
health = 0
AssertEqual(service:GetEstimate("target"), 0, "dead target time-to-die")

ResetTarget()
exists = false
AssertEqual(service:GetEstimate("target"), nil, "invalid unit")

ResetTarget()
UnitExists = nil
AssertEqual(service:GetEstimate("target"), nil, "unavailable unit API")

print("time-to-die smoke tests passed")
