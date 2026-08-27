local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function Contains(values, expected)
    local index
    for index = 1, #values do
        if values[index] == expected then
            return true
        end
    end

    return false
end

TopDps = {
    Modules = {},
}

function TopDps:CreateModule(name)
    local module = self.Modules[name] or {}
    self.Modules[name] = module
    self[name] = module
    return module
end

local spellNames = {
    [6673] = "Battle Shout",
    [19740] = "Blessing of Might",
    [469] = "Commanding Shout",
    [6307] = "Blood Pact",
    [57330] = "Horn of Winter",
    [8076] = "Strength of Earth",
    [1459] = "Arcane Intellect",
    [23028] = "Arcane Brilliance",
    [43002] = "Arcane Brilliance",
    [57564] = "Fel Intelligence",
    [57567] = "Fel Intelligence",
    [14752] = "Divine Spirit",
    [27681] = "Prayer of Spirit",
    [1243] = "Power Word: Fortitude",
    [21562] = "Prayer of Fortitude",
    [1126] = "Mark of the Wild",
    [21849] = "Gift of the Wild",
    [47865] = "Curse of the Elements",
    [60433] = "Earth and Moon",
    [51735] = "Ebon Plague",
    [17800] = "Shadow Mastery",
    [22959] = "Improved Scorch",
    [12579] = "Winter's Chill",
    [7386] = "Sunder Armor",
    [8647] = "Expose Armor",
    [55750] = "Acid Spit",
}

GetSpellInfo = function(spellId)
    return spellNames[spellId]
end

UnitExists = function()
    return true
end

UnitIsUnit = function(left, right)
    return left == right
end

local auras = {
    player = {},
    target = {},
}

local function ReadAura(unit, index)
    local aura = auras[unit] and auras[unit][index] or nil
    if not aura then
        return nil
    end

    return aura.name,
        nil,
        aura.icon,
        aura.stacks or 0,
        nil,
        aura.duration or 0,
        aura.expirationTime or 0,
        aura.unitCaster,
        nil,
        nil,
        aura.spellId
end

UnitBuff = function(unit, index)
    return ReadAura(unit, index)
end

UnitDebuff = function(unit, index)
    return ReadAura(unit, index)
end

dofile("Engine/AuraService.lua")
dofile("Engine/EffectService.lua")

local EffectService = TopDps.EffectService

local function Aura(spellId, unitCaster, stacks)
    return {
        spellId = spellId,
        name = spellNames[spellId],
        unitCaster = unitCaster,
        stacks = stacks or 0,
    }
end

local function TestQualityFiltering()
    local fullIntellect = EffectService:GetSpellIds(
        TopDps.EFFECT_INTELLECT,
        TopDps.EFFECT_QUALITY_FULL
    )

    AssertEqual(Contains(fullIntellect, 1459), true, "full intellect contains Arcane Intellect")
    AssertEqual(Contains(fullIntellect, 23028), true, "full intellect contains Arcane Brilliance")
    AssertEqual(Contains(fullIntellect, 57564), false, "full intellect excludes weaker Fel Intelligence")
end

local function TestEquivalentBuffLookup()
    auras.player = {
        Aura(8076, "party1"),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_STRENGTH_AGILITY,
            "player",
            "HELPFUL",
            { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        true,
        "Strength of Earth satisfies Horn of Winter effect"
    )
end

local function TestExternalMagicVulnerability()
    auras.target = {
        Aura(47865, "player"),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_MAGIC_DAMAGE_TAKEN,
            "target",
            "HARMFUL",
            { excludeOwn = true, minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        false,
        "own Curse of the Elements is not an external equivalent"
    )

    auras.target = {
        Aura(60433, "party1"),
        Aura(47865, "player"),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_MAGIC_DAMAGE_TAKEN,
            "target",
            "HARMFUL",
            { excludeOwn = true, minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        true,
        "Earth and Moon satisfies external magic vulnerability"
    )
end

local function TestRequiredStacks()
    auras.target = {
        Aura(12579, "party1", 4),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_SPELL_CRIT_TAKEN,
            "target",
            "HARMFUL",
            { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        false,
        "four Winter's Chill stacks are insufficient"
    )

    auras.target = {
        Aura(12579, "party1", 5),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_SPELL_CRIT_TAKEN,
            "target",
            "HARMFUL",
            { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        true,
        "five Winter's Chill stacks satisfy spell crit effect"
    )

    auras.target = {
        Aura(55750, "party1", 1),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_MAJOR_ARMOR_REDUCTION,
            "target",
            "HARMFUL",
            { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        false,
        "one Acid Spit stack is not full major armor reduction"
    )

    auras.target = {
        Aura(55750, "party1", 2),
    }

    AssertEqual(
        EffectService:HasEffect(
            TopDps.EFFECT_MAJOR_ARMOR_REDUCTION,
            "target",
            "HARMFUL",
            { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
        ),
        true,
        "two Acid Spit stacks satisfy major armor reduction"
    )
end

local function TestAuraOrderDoesNotChangeQualityResult()
    auras.player = {
        Aura(57567, "party1"),
        Aura(43002, "party2"),
    }

    local aura = EffectService:FindAura(
        TopDps.EFFECT_INTELLECT,
        "player",
        "HELPFUL",
        { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
    )
    AssertEqual(aura and aura.name, "Arcane Brilliance", "full intellect ignores weaker aura first")

    auras.player = {
        Aura(43002, "party2"),
        Aura(57567, "party1"),
    }

    aura = EffectService:FindAura(
        TopDps.EFFECT_INTELLECT,
        "player",
        "HELPFUL",
        { minimumQuality = TopDps.EFFECT_QUALITY_FULL }
    )
    AssertEqual(aura and aura.name, "Arcane Brilliance", "full intellect is independent of aura order")
end

TestQualityFiltering()
TestEquivalentBuffLookup()
TestExternalMagicVulnerability()
TestRequiredStacks()
TestAuraOrderDoesNotChangeQualityResult()

print("effect equivalence regression tests passed")
