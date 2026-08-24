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

TopDps = {
    Modules = {},
    SpecProvider = {},
    SpecRegistry = {
        providers = {},
    },
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

TopDps.AuraService = {
    playerAuras = {},
    targetAuras = {},
}

function TopDps.AuraService:FindAura(unit, spellIds)
    local active = unit == "player" and self.playerAuras or self.targetAuras
    local index
    for index = 1, #spellIds do
        if active[spellIds[index]] then
            return {
                spellId = spellIds[index],
            }
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
        enemyCount = enemyCount,
        activeEnemyCount = enemyCount,
    }
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
    TopDps.AuraService.playerAuras = {
        [DeathKnight.SPELL_IDS.killingMachine] = true,
    }
    local killingMachine = Frost:GetPriority(Context(1))
    AssertEqual(
        IndexOf(killingMachine, "frostStrike") < IndexOf(killingMachine, "obliterate"),
        true,
        "Killing Machine prioritizes Frost Strike"
    )

    TopDps.AuraService.playerAuras = {
        [DeathKnight.SPELL_IDS.freezingFog] = true,
    }
    local rime = Frost:GetPriority(Context(1))
    AssertEqual(
        IndexOf(rime, "howlingBlast") < IndexOf(rime, "obliterate"),
        true,
        "Rime prioritizes Howling Blast"
    )

    TopDps.AuraService.playerAuras = {}
end

local function TestAoeGates()
    TopDps.AuraService.targetAuras = {
        [DeathKnight.SPELL_IDS.frostFever] = true,
        [DeathKnight.SPELL_IDS.bloodPlague] = true,
    }

    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), true, "Blood Pestilence")
    AssertEqual(Frost:IsCategoryAllowed("deathAndDecay", Context(2)), false, "Frost DnD threshold")
    AssertEqual(Frost:IsCategoryAllowed("deathAndDecay", Context(3)), true, "Frost DnD AoE")
    AssertEqual(Unholy:IsCategoryAllowed("bloodBoil", Context(2)), true, "Unholy Blood Boil")

    TopDps.AuraService.targetAuras = {}
    AssertEqual(Blood:IsCategoryAllowed("pestilence", Context(2)), false, "Pestilence needs diseases")
end

TestProvidersRegistered()
TestFrostProcPriorities()
TestAoeGates()

print("death knight smoke tests passed")
