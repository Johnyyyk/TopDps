local addon = TopDps
local Mage = addon:CreateModule("Mage")

Mage.CLASS_TOKEN = "MAGE"
Mage.TALENT_TABS = {
    ARCANE = 1,
    FIRE = 2,
    FROST = 3,
}

Mage.FIRE_FILLER_FIREBALL = "fireball"
Mage.FIRE_FILLER_FROSTFIRE = "frostfire"

Mage.SPELL_IDS = {
    arcaneBlast = 30451,
    arcaneBlastStack = 36032,
    arcaneMissiles = 5143,
    arcaneBarrage = 44425,
    missileBarrage = 44401,
    arcaneExplosion = 1449,
    fireBlast = 2136,
    blizzard = 10,

    livingBomb = 44457,
    scorch = 2948,
    improvedScorch = 22959,
    shadowMastery = 17800,
    wintersChill = 12579,
    pyroblast = 11366,
    hotStreak = 48108,
    fireball = 133,
    frostfireBolt = 44614,
    firestarter = 54741,

    frostbolt = 116,
    iceLance = 30455,
    deepFreeze = 44572,
    fingersOfFrost = 44544,
    brainFreeze = 57761,

    frostArmor = 168,
    iceArmor = 7302,
    mageArmor = 6117,
    moltenArmor = 30482,
    mirrorImage = 55342,
    evocation = 12051,
    iceBlock = 45438,
    manaShield = 1463,
    counterspell = 2139,
    invisibility = 66,
    arcanePower = 12042,
    presenceOfMind = 12043,
    combustion = 11129,
    icyVeins = 12472,
    coldSnap = 11958,
    summonWaterElemental = 31687,
}

function Mage:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Mage:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Mage:GetArcaneBlastStacks()
    local aura = addon.AuraService:FindAura(
        "player",
        { self.SPELL_IDS.arcaneBlastStack },
        "HARMFUL",
        false
    )
    return math.max(0, tonumber(aura and aura.stacks) or 0)
end

function Mage:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Mage:IsMoving(context)
    return context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
        or false
end

function Mage:GetManaFraction(context)
    local power = context and context.player and context.player.power or nil
    return power and tonumber(power.fraction) or 1
end
