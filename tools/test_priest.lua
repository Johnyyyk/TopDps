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
        if values[index] == expected then return index end
    end
    return nil
end

TopDps = {
    Modules = {},
    REFRESH_LEAD_CAST_TIME = "CAST_TIME",
    SpecProvider = {},
    SpecRegistry = { providers = {} },
}
function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end
function TopDps.SpecProvider:Create(definition) return definition end
function TopDps.SpecRegistry:Register(provider) self.providers[provider.id] = provider end

TopDps.AuraService = { player = {}, target = {} }
function TopDps.AuraService:FindAura(unit, spellIds)
    local source = unit == "player" and self.player or self.target
    local index
    for index = 1, #spellIds do
        if source[spellIds[index]] then return source[spellIds[index]] end
    end
    return nil
end

dofile("Specs/Priest/Common.lua")
dofile("Specs/Priest/Shadow.lua")

local Priest = TopDps.Priest
local Shadow = TopDps.SpecRegistry.providers.PRIEST_SHADOW
local function Context(enemies, moving, ttd)
    return {
        activeEnemyCount = enemies or 1,
        enemyCount = enemies or 1,
        player = { movement = { moving = moving == true } },
        target = { timeToDie = ttd },
    }
end

TopDps.AuraService.player[Priest.SPELL_IDS.shadowWeaving] = { stacks = 4 }
AssertEqual(Shadow:IsCategoryAllowed("shadowWordPain", Context()), false, "SWP waits for five stacks")
TopDps.AuraService.player[Priest.SPELL_IDS.shadowWeaving].stacks = 5
AssertEqual(Shadow:IsCategoryAllowed("shadowWordPain", Context()), true, "SWP at five stacks")
AssertEqual(Shadow:IsCategoryAllowed("vampiricTouch", Context(1, true)), false, "VT blocked while moving")
AssertEqual(Shadow:IsCategoryAllowed("shadowWordDeath", Context(1, true)), true, "SWD movement filler")
AssertEqual(IndexOf(Shadow:GetPriority(Context(4, false)), "mindSear") ~= nil, true, "AoE Mind Sear")
AssertEqual(Shadow:IsCategoryAllowed("devouringPlague", Context(1, false, 5)), false, "short TTD skips dot")

print("priest smoke tests passed")
