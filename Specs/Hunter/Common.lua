local addon = TopDps
local Hunter = addon:CreateModule("Hunter")

Hunter.CLASS_TOKEN = "HUNTER"
Hunter.TALENT_TABS = {
    BEAST_MASTERY = 1,
    MARKSMANSHIP = 2,
    SURVIVAL = 3,
}

Hunter.SPELL_IDS = {
    huntersMark = 1130,
    serpentSting = 1978,
    arcaneShot = 3044,
    steadyShot = 56641,
    multiShot = 2643,
    aimedShot = 19434,
    chimeraShot = 53209,
    killShot = 53351,
    explosiveShot = 53301,
    blackArrow = 3674,
    volley = 1510,

    aspectHawk = 13165,
    aspectDragonhawk = 61846,
    aspectViper = 34074,
    aspectMonkey = 13163,
    aspectCheetah = 5118,
    aspectPack = 13159,
    aspectWild = 20043,
    aspectBeast = 13161,

    rapidFire = 3045,
    killCommand = 34026,
    bestialWrath = 19574,
    beastWithin = 34471,
    readiness = 23989,
    lockAndLoad = 56453,
    silencingShot = 34490,
    deterrence = 19263,
    disengage = 781,
    feignDeath = 5384,
    misdirection = 34477,
    callPet = 883,
}

local ARCANE_SHOT_DROP_ARMOR_PENETRATION_RATING = 430

function Hunter:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Hunter:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function Hunter:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Hunter:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Hunter:IsExecute(context)
    local health = context and context.target and context.target.health or nil
    return health and health.maximum > 0 and health.fraction <= 0.20 or false
end

function Hunter:IsMoving(context)
    return context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
        or false
end

function Hunter:IsPetAlive()
    return UnitExists("pet") and not UnitIsDead("pet") or false
end

function Hunter:GetArmorPenetrationRating()
    if not GetCombatRating or type(CR_ARMOR_PENETRATION) ~= "number" then
        return nil
    end

    local ok, rating = pcall(GetCombatRating, CR_ARMOR_PENETRATION)
    if not ok then
        return nil
    end

    rating = tonumber(rating)
    if not rating or rating < 0 then
        return nil
    end

    return rating
end

function Hunter:ShouldUseArcaneShot()
    local rating = self:GetArmorPenetrationRating()
    return rating == nil or rating < ARCANE_SHOT_DROP_ARMOR_PENETRATION_RATING
end
