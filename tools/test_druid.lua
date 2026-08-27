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

GetTime = function()
    return 100
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
        local aura = active[spellIds[index]]
        if aura then
            return aura
        end
    end

    return nil
end

dofile("Specs/Druid/Common.lua")
dofile("Specs/Druid/Balance.lua")
dofile("Specs/Druid/Feral.lua")

local Druid = TopDps.Druid
local Balance = TopDps.SpecRegistry.providers.DRUID_BALANCE
local Feral = TopDps.SpecRegistry.providers.DRUID_FERAL

local function Context(enemyCount, moving, comboPoints)
    return {
        now = 100,
        enemyCount = enemyCount or 1,
        activeEnemyCount = enemyCount or 1,
        player = {
            comboPoints = comboPoints or 0,
            movement = {
                moving = moving == true,
            },
        },
        target = {},
    }
end

local function Aura(spellId, expirationTime)
    return {
        spellId = spellId,
        expirationTime = expirationTime or 0,
    }
end

local function TestBalanceEclipseCycle()
    TopDps.AuraService.playerAuras = {
        [Druid.SPELL_IDS.lunarEclipse] = Aura(Druid.SPELL_IDS.lunarEclipse),
    }
    local lunar = Balance:GetPriority(Context(1, false, 0))
    AssertEqual(IndexOf(lunar, "starfire") ~= nil, true, "Lunar uses Starfire")

    TopDps.AuraService.playerAuras = {}
    local afterLunar = Balance:GetPriority(Context(1, false, 0))
    AssertEqual(IndexOf(afterLunar, "starfire") ~= nil, true, "after Lunar keeps Starfire")

    TopDps.AuraService.playerAuras = {
        [Druid.SPELL_IDS.solarEclipse] = Aura(Druid.SPELL_IDS.solarEclipse),
    }
    local solar = Balance:GetPriority(Context(1, false, 0))
    AssertEqual(IndexOf(solar, "wrath") ~= nil, true, "Solar uses Wrath")

    TopDps.AuraService.playerAuras = {}
    local afterSolar = Balance:GetPriority(Context(1, false, 0))
    AssertEqual(IndexOf(afterSolar, "wrath") ~= nil, true, "after Solar keeps Wrath")
end

local function TestBalanceMovementAndAoe()
    local moving = Balance:GetPriority(Context(1, true, 0))
    AssertEqual(IndexOf(moving, "wrath"), nil, "moving omits Wrath")
    AssertEqual(IndexOf(moving, "moonfire") ~= nil, true, "moving keeps Moonfire")

    local aoe = Balance:GetPriority(Context(4, false, 0))
    AssertEqual(aoe[1], "hurricane", "AoE uses Hurricane")
end

local function TestFeralFormAndFinishers()
    TopDps.AuraService.playerAuras = {}
    AssertEqual(#Feral:GetPriority(Context(1, false, 5)), 0, "Feral rotation is cat-only")

    TopDps.AuraService.playerAuras = {
        [Druid.SPELL_IDS.catForm] = Aura(Druid.SPELL_IDS.catForm),
        [Druid.SPELL_IDS.savageRoar] = Aura(Druid.SPELL_IDS.savageRoar, 115),
    }
    TopDps.AuraService.targetAuras = {
        [Druid.SPELL_IDS.rip] = Aura(Druid.SPELL_IDS.rip, 115),
    }

    AssertEqual(Feral:IsCategoryAllowed("rip", Context(1, false, 4)), false, "Rip needs five points")
    AssertEqual(Feral:IsCategoryAllowed("rip", Context(1, false, 5)), true, "Rip at five points")
    AssertEqual(Feral:IsCategoryAllowed("ferociousBite", Context(1, false, 5)), true, "safe Bite")

    TopDps.AuraService.targetAuras[Druid.SPELL_IDS.rip].expirationTime = 108
    AssertEqual(Feral:IsCategoryAllowed("ferociousBite", Context(1, false, 5)), false, "unsafe Bite blocked")
end

local function TestFeralClearcastingAndAoe()
    TopDps.AuraService.playerAuras = {
        [Druid.SPELL_IDS.catForm] = Aura(Druid.SPELL_IDS.catForm),
        [Druid.SPELL_IDS.clearcasting] = Aura(Druid.SPELL_IDS.clearcasting),
    }
    TopDps.AuraService.targetAuras = {}

    local proc = Feral:GetPriority(Context(1, false, 0))
    AssertEqual(
        IndexOf(proc, "shred") < IndexOf(proc, "ferociousBite"),
        true,
        "Clearcasting moves Shred ahead of Bite"
    )

    local aoe = Feral:GetPriority(Context(4, false, 1))
    AssertEqual(IndexOf(aoe, "swipeCat") ~= nil, true, "Feral AoE uses Swipe")
end

TestBalanceEclipseCycle()
TestBalanceMovementAndAoe()
TestFeralFormAndFinishers()
TestFeralClearcastingAndAoe()

print("druid smoke tests passed")
