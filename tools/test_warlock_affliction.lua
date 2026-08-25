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

local function AssertBefore(values, left, right, message)
    local leftIndex = IndexOf(values, left)
    local rightIndex = IndexOf(values, right)
    if not leftIndex or not rightIndex or leftIndex >= rightIndex then
        Fail(message or (tostring(left) .. " must be before " .. tostring(right)))
    end
end

TopDps = {
    Modules = {},
    REFRESH_LEAD_CAST_TIME = "CAST_TIME",
    EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE = "targetTimeToDie",
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
    definition.testSettings = {
        curseMode = "auto",
        useMovementPriority = true,
        useTargetTimeToDie = false,
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
dofile("Specs/Warlock/Affliction.lua")

local Warlock = TopDps.Warlock
local Affliction = TopDps.SpecRegistry.providers.WARLOCK_AFFLICTION
local hasCritDebuff = true
local hasMagicVulnerability = true
local hasShadowTrance = false
local activeTargetAuras = {}

Warlock.HasSpellCritDebuff = function()
    return hasCritDebuff
end

Warlock.HasExternalMagicVulnerability = function()
    return hasMagicVulnerability
end

Warlock.HasPlayerAura = function(_, spellIds)
    local index
    for index = 1, #spellIds do
        if spellIds[index] == 17941 then
            return hasShadowTrance
        end
    end

    return false
end

Warlock.HasOwnTargetAura = function(_, spellIds)
    local index
    for index = 1, #spellIds do
        if activeTargetAuras[spellIds[index]] then
            return true
        end
    end

    return false
end

Warlock.GetCommonCategoryAllowed = function()
    return nil
end

local function Context(healthFraction, moving, enemyCount, timeToDie)
    return {
        activeEnemyCount = enemyCount or 1,
        enemyCount = enemyCount or 1,
        player = {
            movement = {
                moving = moving == true,
            },
        },
        target = {
            health = {
                maximum = 100,
                fraction = healthFraction or 1,
            },
            timeToDie = timeToDie,
        },
    }
end

local function FindSetting(key)
    local index
    for index = 1, #(Affliction.settings or {}) do
        local setting = Affliction.settings[index]
        if setting.key == key then
            return setting
        end
    end

    return nil
end

local function TestSettings()
    local movement = FindSetting("useMovementPriority")
    local ttd = FindSetting("useTargetTimeToDie")

    AssertEqual(movement ~= nil, true, "movement setting")
    AssertEqual(movement.default, true, "movement default")
    AssertEqual(ttd ~= nil, true, "TTD setting")
    AssertEqual(ttd.default, false, "TTD default")
    AssertEqual(ttd.experimental, true, "TTD experimental")
    AssertEqual(
        ttd.experimentalFeature,
        TopDps.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE,
        "TTD feature"
    )
end

local function TestMagicVulnerabilityPriority()
    hasMagicVulnerability = false
    local needsElements = Affliction:GetPriority(Context(0.80, false, 1, nil))
    AssertBefore(needsElements, "curse", "shadowBolt", "Curse of Elements before Shadow Bolt")
    hasMagicVulnerability = true
end

local function TestNormalAndExecutePriority()
    hasCritDebuff = true
    local normal = Affliction:GetPriority(Context(0.80, false, 1, nil))
    AssertBefore(normal, "haunt", "unstableAffliction", "normal Haunt")
    AssertBefore(normal, "unstableAffliction", "corruption", "normal UA")
    AssertBefore(normal, "corruption", "shadowBolt", "normal Corruption")

    local execute = Affliction:GetPriority(Context(0.25, false, 1, nil))
    AssertBefore(execute, "haunt", "drainSoul", "execute Haunt")
    AssertBefore(execute, "drainSoul", "shadowBolt", "execute Drain Soul")

    hasCritDebuff = false
    local needsCrit = Affliction:GetPriority(Context(0.80, false, 1, nil))
    AssertBefore(needsCrit, "shadowBolt", "corruption", "crit debuff before Corruption")

    local executeNeedsCrit = Affliction:GetPriority(Context(0.20, false, 1, nil))
    AssertBefore(executeNeedsCrit, "shadowBolt", "drainSoul", "execute restores crit debuff first")
end

local function TestMovementPriority()
    hasCritDebuff = true
    hasShadowTrance = false

    local moving = Affliction:GetPriority(Context(0.80, true, 1, nil))
    AssertEqual(IndexOf(moving, "unstableAffliction"), nil, "UA excluded while moving")
    AssertEqual(IndexOf(moving, "haunt"), nil, "Haunt excluded while moving")
    AssertEqual(IndexOf(moving, "drainSoul"), nil, "Drain Soul excluded while moving")
    AssertEqual(
        Affliction:IsCategoryAllowed("shadowBolt", Context(0.80, true, 1, nil)),
        false,
        "hard-cast Shadow Bolt blocked while moving"
    )

    hasShadowTrance = true
    AssertEqual(
        Affliction:IsCategoryAllowed("shadowBolt", Context(0.80, true, 1, nil)),
        true,
        "Shadow Trance allows moving Shadow Bolt"
    )

    hasShadowTrance = false
end

local function TestExecuteShadowBolt()
    hasCritDebuff = true
    hasShadowTrance = false
    AssertEqual(
        Affliction:IsCategoryAllowed("shadowBolt", Context(0.20, false, 1, nil)),
        false,
        "execute filler is Drain Soul"
    )

    hasShadowTrance = true
    AssertEqual(
        Affliction:IsCategoryAllowed("shadowBolt", Context(0.20, false, 1, nil)),
        true,
        "Nightfall remains usable in execute"
    )

    hasShadowTrance = false
    hasCritDebuff = false
    AssertEqual(
        Affliction:IsCategoryAllowed("shadowBolt", Context(0.20, false, 1, nil)),
        true,
        "missing crit debuff allows execute Shadow Bolt"
    )
end

local function TestDotAndAoeGates()
    hasCritDebuff = true
    activeTargetAuras = {}

    AssertEqual(
        Affliction:IsCategoryAllowed("corruption", Context(0.80, false, 1, 5)),
        false,
        "short-lived target skips Corruption"
    )
    AssertEqual(
        Affliction:IsCategoryAllowed("unstableAffliction", Context(0.80, false, 1, 5)),
        false,
        "short-lived target skips UA"
    )
    AssertEqual(
        Affliction:IsCategoryAllowed("haunt", Context(0.80, false, 1, 3)),
        false,
        "short-lived target skips Haunt"
    )

    activeTargetAuras[Warlock.SPELL_IDS.corruption] = true
    AssertEqual(
        Affliction:IsCategoryAllowed("corruption", Context(0.80, false, 1, nil)),
        false,
        "rolling Corruption is not manually refreshed"
    )
    activeTargetAuras = {}

    local aoe = Affliction:GetPriority(Context(0.80, false, 4, nil))
    AssertEqual(IndexOf(aoe, "seedOfCorruption") ~= nil, true, "AoE priority contains Seed")
    AssertEqual(
        Affliction:IsCategoryAllowed("seedOfCorruption", Context(0.80, false, 4, nil)),
        true,
        "Seed allowed at four targets"
    )
    AssertEqual(
        Affliction:IsCategoryAllowed("seedOfCorruption", Context(0.80, false, 3, nil)),
        false,
        "Seed blocked below four targets"
    )

    activeTargetAuras[27243] = true
    AssertEqual(
        Affliction:IsCategoryAllowed("seedOfCorruption", Context(0.80, false, 4, nil)),
        false,
        "active Seed is not immediately overwritten"
    )
end

TestSettings()
TestMagicVulnerabilityPriority()
TestNormalAndExecutePriority()
TestMovementPriority()
TestExecuteShadowBolt()
TestDotAndAoeGates()

print("affliction warlock smoke tests passed")
