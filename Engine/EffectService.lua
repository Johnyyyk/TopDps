local addon = TopDps
local EffectService = addon:CreateModule("EffectService")

addon.EFFECT_QUALITY_PARTIAL = 1
addon.EFFECT_QUALITY_FULL = 2

addon.EFFECT_ATTACK_POWER_FLAT = "ATTACK_POWER_FLAT"
addon.EFFECT_HEALTH_FLAT = "HEALTH_FLAT"
addon.EFFECT_STRENGTH_AGILITY = "STRENGTH_AGILITY"
addon.EFFECT_INTELLECT = "INTELLECT"
addon.EFFECT_SPIRIT = "SPIRIT"
addon.EFFECT_STAMINA = "STAMINA"
addon.EFFECT_STATS_ARMOR_RESISTANCE = "STATS_ARMOR_RESISTANCE"
addon.EFFECT_MAGIC_DAMAGE_TAKEN = "MAGIC_DAMAGE_TAKEN"
addon.EFFECT_SPELL_CRIT_TAKEN = "SPELL_CRIT_TAKEN"
addon.EFFECT_MAJOR_ARMOR_REDUCTION = "MAJOR_ARMOR_REDUCTION"

local EFFECTS = {
    [addon.EFFECT_ATTACK_POWER_FLAT] = {
        { spellIds = { 6673 }, quality = addon.EFFECT_QUALITY_FULL }, -- Battle Shout
        { spellIds = { 19740 }, quality = addon.EFFECT_QUALITY_FULL }, -- Blessing of Might
    },
    [addon.EFFECT_HEALTH_FLAT] = {
        { spellIds = { 469 }, quality = addon.EFFECT_QUALITY_FULL }, -- Commanding Shout
        { spellIds = { 6307 }, quality = addon.EFFECT_QUALITY_PARTIAL }, -- Blood Pact
    },
    [addon.EFFECT_STRENGTH_AGILITY] = {
        { spellIds = { 57330 }, quality = addon.EFFECT_QUALITY_FULL }, -- Horn of Winter
        { spellIds = { 8076 }, quality = addon.EFFECT_QUALITY_FULL }, -- Strength of Earth
    },
    [addon.EFFECT_INTELLECT] = {
        { spellIds = { 1459 }, quality = addon.EFFECT_QUALITY_FULL }, -- Arcane Intellect
        { spellIds = { 23028 }, quality = addon.EFFECT_QUALITY_FULL }, -- Arcane Brilliance
        { spellIds = { 57564 }, quality = addon.EFFECT_QUALITY_PARTIAL }, -- Fel Intelligence
    },
    [addon.EFFECT_SPIRIT] = {
        { spellIds = { 14752 }, quality = addon.EFFECT_QUALITY_FULL }, -- Divine Spirit
        { spellIds = { 27681 }, quality = addon.EFFECT_QUALITY_FULL }, -- Prayer of Spirit
        { spellIds = { 57564 }, quality = addon.EFFECT_QUALITY_PARTIAL }, -- Fel Intelligence
    },
    [addon.EFFECT_STAMINA] = {
        { spellIds = { 1243 }, quality = addon.EFFECT_QUALITY_FULL }, -- Power Word: Fortitude
        { spellIds = { 21562 }, quality = addon.EFFECT_QUALITY_FULL }, -- Prayer of Fortitude
    },
    [addon.EFFECT_STATS_ARMOR_RESISTANCE] = {
        { spellIds = { 1126 }, quality = addon.EFFECT_QUALITY_FULL }, -- Mark of the Wild
        { spellIds = { 21849 }, quality = addon.EFFECT_QUALITY_FULL }, -- Gift of the Wild
    },
    [addon.EFFECT_MAGIC_DAMAGE_TAKEN] = {
        { spellIds = { 47865 }, quality = addon.EFFECT_QUALITY_FULL }, -- Curse of the Elements
        { spellIds = { 60433 }, quality = addon.EFFECT_QUALITY_FULL }, -- Earth and Moon
        { spellIds = { 51735 }, quality = addon.EFFECT_QUALITY_FULL }, -- Ebon Plague
    },
    [addon.EFFECT_SPELL_CRIT_TAKEN] = {
        { spellIds = { 17800 }, quality = addon.EFFECT_QUALITY_FULL }, -- Shadow Mastery
        { spellIds = { 22959 }, quality = addon.EFFECT_QUALITY_FULL }, -- Improved Scorch
        { spellIds = { 12579 }, quality = addon.EFFECT_QUALITY_FULL, minimumStacks = 5 }, -- Winter's Chill
    },
    [addon.EFFECT_MAJOR_ARMOR_REDUCTION] = {
        { spellIds = { 7386 }, quality = addon.EFFECT_QUALITY_FULL, minimumStacks = 5 }, -- Sunder Armor
        { spellIds = { 8647 }, quality = addon.EFFECT_QUALITY_FULL }, -- Expose Armor
        { spellIds = { 55750 }, quality = addon.EFFECT_QUALITY_FULL, minimumStacks = 2 }, -- Acid Spit
    },
}

local function IsOwnAura(aura)
    if not aura or not aura.unitCaster then
        return false
    end

    if aura.unitCaster == "player" then
        return true
    end

    if UnitIsUnit then
        local ok, sameUnit = pcall(UnitIsUnit, aura.unitCaster, "player")
        return ok and sameUnit == true
    end

    return false
end

local function MeetsVariantRequirements(aura, variant, options)
    if options.excludeOwn and IsOwnAura(aura) then
        return false
    end

    local minimumStacks = tonumber(variant.minimumStacks) or 0
    if minimumStacks > 0 and (tonumber(aura.stacks) or 0) < minimumStacks then
        return false
    end

    return true
end

function EffectService:GetSpellIds(effectId, minimumQuality)
    local variants = EFFECTS[effectId] or {}
    local requiredQuality = tonumber(minimumQuality) or addon.EFFECT_QUALITY_PARTIAL
    local result = {}
    local seen = {}
    local variantIndex

    for variantIndex = 1, #variants do
        local variant = variants[variantIndex]
        if (tonumber(variant.quality) or addon.EFFECT_QUALITY_PARTIAL) >= requiredQuality then
            local spellIndex
            for spellIndex = 1, #(variant.spellIds or {}) do
                local spellId = variant.spellIds[spellIndex]
                if not seen[spellId] then
                    seen[spellId] = true
                    result[#result + 1] = spellId
                end
            end
        end
    end

    return result
end

function EffectService:FindAura(effectId, unit, filter, options)
    if not addon.AuraService then
        return nil, nil
    end

    options = options or {}
    local variants = EFFECTS[effectId] or {}
    local requiredQuality = tonumber(options.minimumQuality) or addon.EFFECT_QUALITY_PARTIAL
    local bestAura
    local bestVariant
    local bestQuality = -1
    local variantIndex

    for variantIndex = 1, #variants do
        local variant = variants[variantIndex]
        local quality = tonumber(variant.quality) or addon.EFFECT_QUALITY_PARTIAL
        if quality >= requiredQuality then
            local aura = addon.AuraService:FindAura(
                unit,
                variant.spellIds,
                filter or "HELPFUL",
                false
            )
            if aura and MeetsVariantRequirements(aura, variant, options) and quality > bestQuality then
                bestAura = aura
                bestVariant = variant
                bestQuality = quality
            end
        end
    end

    return bestAura, bestVariant
end

function EffectService:HasEffect(effectId, unit, filter, options)
    return self:FindAura(effectId, unit, filter, options) ~= nil
end
