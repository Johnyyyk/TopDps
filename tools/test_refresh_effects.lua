local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local now = 100
GetTime = function()
    return now
end

TopDps = {
    Modules = {},
    AuraService = {},
    EffectService = {},
    GameApi = {},
    REFRESH_LEAD_CAST_TIME = "CAST_TIME",
    EFFECT_SPELL_CRIT_TAKEN = "SPELL_CRIT_TAKEN",
    EFFECT_QUALITY_FULL = 2,
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

function TopDps.GameApi:GetSpellCastTime()
    return 0
end

local semanticAura
local directAura
local lastEffectOptions

function TopDps.EffectService:FindAura(effectId, unit, filter, options)
    AssertEqual(effectId, TopDps.EFFECT_SPELL_CRIT_TAKEN, "refresh effect id")
    AssertEqual(unit, "target", "refresh effect unit")
    AssertEqual(filter, "HARMFUL", "refresh effect filter")
    lastEffectOptions = options
    return semanticAura
end

function TopDps.AuraService:FindAura(unit, spellIds, filter, ownOnly)
    AssertEqual(unit, "target", "direct refresh unit")
    AssertEqual(spellIds[1], 12345, "direct refresh aura id")
    AssertEqual(filter, "HARMFUL", "direct refresh filter")
    AssertEqual(ownOnly, true, "direct refresh ownOnly")
    return directAura
end

dofile("Engine/RefreshService.lua")

local RefreshService = TopDps.RefreshService
local semanticProvider = {
    abilities = {
        scorch = {
            refresh = {
                auraSpellIds = { 17800, 22959, 12579 },
                effectId = TopDps.EFFECT_SPELL_CRIT_TAKEN,
                effectMinimumQuality = TopDps.EFFECT_QUALITY_FULL,
                unit = "target",
                filter = "HARMFUL",
                lead = 3,
            },
        },
    },
}

semanticAura = { expirationTime = 110 }
AssertEqual(
    RefreshService:IsCategoryRefreshDue(semanticProvider, "scorch", { now = now }),
    false,
    "full semantic effect with enough time suppresses refresh"
)
AssertEqual(
    lastEffectOptions.minimumQuality,
    TopDps.EFFECT_QUALITY_FULL,
    "refresh forwards required semantic effect quality"
)

semanticAura = { expirationTime = 102 }
AssertEqual(
    RefreshService:IsCategoryRefreshDue(semanticProvider, "scorch", { now = now }),
    true,
    "semantic effect inside lead window allows refresh"
)

semanticAura = nil
AssertEqual(
    RefreshService:IsCategoryRefreshDue(semanticProvider, "scorch", { now = now }),
    true,
    "missing semantic effect allows refresh"
)

local directProvider = {
    abilities = {
        dot = {
            refresh = {
                auraSpellIds = { 12345 },
                unit = "target",
                filter = "HARMFUL",
                ownOnly = true,
                lead = 2,
            },
        },
    },
}

directAura = { expirationTime = 110 }
AssertEqual(
    RefreshService:IsCategoryRefreshDue(directProvider, "dot", { now = now }),
    false,
    "legacy direct aura refresh path remains unchanged"
)

directAura = { expirationTime = 101 }
AssertEqual(
    RefreshService:IsCategoryRefreshDue(directProvider, "dot", { now = now }),
    true,
    "legacy direct aura lead still applies"
)

print("refresh semantic effect regression tests passed")
