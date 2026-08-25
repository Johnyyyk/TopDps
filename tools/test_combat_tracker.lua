local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = { Modules = {} }
    function addon:CreateModule(name)
        local module = self.Modules[name] or {}
        self.Modules[name] = module
        self[name] = module
        return module
    end
    return addon
end

local now = 20
local playerGuid = "Player-1"

GetTime = function()
    return now
end

UnitGUID = function(unit)
    if unit == "player" then
        return playerGuid
    end
    return nil
end

GetSpellInfo = function(spellId)
    if spellId == 50842 then
        return "Pestilence"
    end
    return "Spell " .. tostring(spellId)
end

TopDps = NewAddon()
dofile("Engine/CombatTracker.lua")

local CombatTracker = TopDps.CombatTracker

CombatTracker:RecordCombatEvent(
    now,
    "SPELL_CAST_SUCCESS",
    playerGuid,
    "Player",
    0,
    "Target-1",
    "Target",
    0,
    50842,
    "Pestilence",
    1
)

local cast = CombatTracker:GetLastPlayerSpellCast({ 50842 })
AssertEqual(cast ~= nil, true, "successful player spell is tracked")
AssertEqual(cast.spellId, 50842, "tracked spell id")
AssertEqual(cast.time, 20, "tracked spell time")

now = 21
CombatTracker:RecordCombatEvent(
    now,
    "SPELL_CAST_SUCCESS",
    playerGuid,
    "Player",
    0,
    "Target-1",
    "Target",
    0,
    99999,
    "Pestilence",
    1
)

cast = CombatTracker:GetLastPlayerSpellCast({ 50842 })
AssertEqual(cast.spellId, 99999, "spell-name fallback tracks alternate rank/id")
AssertEqual(cast.time, 21, "newest matching cast wins")

CombatTracker:Clear()
AssertEqual(CombatTracker:GetLastPlayerSpellCast({ 50842 }), nil, "cast history clears after combat")

print("combat tracker smoke tests passed")
