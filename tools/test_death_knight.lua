local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function IndexOf(values, expected)
    local index
    for index = 1, #values do
        if values[index] == expected then
            return index
        end
    end

    return nil
end

local now = 100
GetTime = function()
    return now
end

TopDps = {
    Modules = {},
    SpecProvider = {},
    SpecRegistry = { providers = {} },
    GameApi = {},
    CombatTracker = {},
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

function TopDps.SpecProvider:Create(definition)
    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

local hasGlyphDisease = false
function TopDps.GameApi:HasGlyphSpell()
    return hasGlyphDisease
end

local lastCasts = {}
function TopDps.CombatTracker:GetLastPlayerSpellCast(spellIds)
    local latest
    local index
    for index = 1, #spellIds do
        local cast = lastCasts[spellIds[index]]
        if cast and (not latest or cast.time > latest.time) then
            latest = cast
        end
    end
    return latest
end

TopDps.AuraService = {
    playerAuras = {},
    targetAuras = {},
}

function TopDps.AuraService:FindAura(unit, spellIds)
    local active = unit == "player" and self.playerAuras or self.targetAuras
    local index
    for index = 1, #spellIds do
        local aura = active[spellIds[index]]
        if aura then
            if type(aura) == "table" then
                return aura
            end
            return { spellId = spellIds[index] }
        end
    end
    return nil
end

dofile("Specs/DeathKnight/Common.lua")
dofile("Specs/DeathKnight/Blood.lua")
dofile("Specs/DeathKnight/Frost.lua")
dofile("Specs/DeathKnight/Unholy.lua")

local DeathKnight = TopDps.DeathKnight
local Blood = TopDps.SpecRegistry.providers.DEATHKNIGHT_BLOOD
local Frost = TopDps.SpecRegistry.providers.DEATHKNIGHT_FROST
local Unholy = TopDps.SpecRegistry.providers.DEATHKNIGHT_UNHOLY

local function Context(enemyCount)
    return {
        now = now,
        enemyCount = enemyCount,
        activeEnemyCount = enemyCount,
    }
end

local function SetDiseases(remaining)
    local duration = 15
    TopDps.AuraService.targetAuras = {
        [DeathKnight.SPELL_IDS.frostFever] = {
            spellId = DeathKnight.SPELL_IDS.frostFever,
            duration = duration,
            expirationTime = now + (remaining or duration),
        },
        [DeathKnight.SPELL_IDS.bloodPlague] = {
            spellId = DeathKnight.SPELL_IDS.bloodPlague,
            duration = duration,
            expirationTime = now + (remaining or duration),
        },
    }
end

local function SetLastCast(spellId, timestamp)
    lastCasts[spellId] = { spellId = spellId, time = timestamp }
end

local function ResetCastState()
    lastCasts = {}
    hasGlyphDisease = false
end

local function TestProvidersRegistered()
    AssertEqual(Blood ~= nil, true, "Blood provider")
    AssertEqual(Frost ~= nil, true, "Frost provider")
    AssertEqual(Unholy ~= nil, true, "Unholy provider")
    AssertEqual(Blood.talentTab, 1, "Blood tab")
    AssertEqual(Frost.talentTab, 2, "Frost tab")
    AssertEqual(Unholy.talentTab, 3, "Unholy tab")
end

local function TestFrostProcPriorities()
    TopDps.AuraService.playerAuras = { [DeathKnight.SPELL_IDS.killingMachine] = true }
    local killingMachine = Frost:GetPriority(Context(1))
    AssertEqual(IndexOf(killingMachine, "frostStrike") < IndexOf(killingMachine, "obliterate"), true, "Killing Machine prioritizes Frost Strike")

    TopDps.AuraService.playerAuras = { [DeathKnight.SPELL_IDS.freezingFog] = true }
    local rime = Frost:GetPriority(Context(1))
    AssertEqual(IndexOf(rime, "howlingBlast") < IndexOf(rime, "obliterate"), true, "Rime prioritizes Howling Blast")
    TopDps.AuraService.playerAuras = {}
end

local function TestPestilenceSpreadDoesNotSpam()
    ResetCastState()
    SetDiseases()

    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), true, "initial disease spread")
    SetLastCast(DeathKnight.SPELL_IDS.pestilence, 99.5)
    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), false, "Pestilence is not repeated immediately")

    now = 102
    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), false, "Pestilence stays blocked after initial spread")
    SetLastCast(DeathKnight.SPELL_IDS.icyTouch, 101.5)
    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), true, "new disease application can be spread again")
    now = 100
end

local function TestGlyphDiseaseRefresh()
    ResetCastState()
    hasGlyphDisease = true
    SetDiseases(2.5)

    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(1)), true, "Glyph of Disease enables ST refresh")
    AssertEqual(IndexOf(Blood:GetPriority(Context(1)), "pestilence") ~= nil, true, "Blood ST priority contains glyph refresh")
    AssertEqual(IndexOf(Frost:GetPriority(Context(1)), "pestilence") ~= nil, true, "Frost ST priority contains glyph refresh")
    AssertEqual(IndexOf(Unholy:GetPriority(Context(1)), "pestilence") ~= nil, true, "Unholy ST priority contains glyph refresh")
end

local function TestAoeGates()
    ResetCastState()
    SetDiseases()
    AssertEqual(Frost:IsCategoryAllowed("deathAndDecay", Context(2)), false, "Frost DnD threshold")
    AssertEqual(Frost:IsCategoryAllowed("deathAndDecay", Context(3)), true, "Frost DnD AoE")
    AssertEqual(Unholy:IsCategoryAllowed("bloodBoil", Context(2)), true, "Unholy Blood Boil")

    TopDps.AuraService.targetAuras = {}
    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), false, "Pestilence needs diseases")
end

TestProvidersRegistered()
TestFrostProcPriorities()
TestPestilenceSpreadDoesNotSpam()
TestGlyphDiseaseRefresh()
TestAoeGates()

print("death knight smoke tests passed")
