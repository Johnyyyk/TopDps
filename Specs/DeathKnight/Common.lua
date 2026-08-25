local addon = TopDps
local DeathKnight = addon:CreateModule("DeathKnight")

DeathKnight.CLASS_TOKEN = "DEATHKNIGHT"
DeathKnight.TALENT_TABS = {
    BLOOD = 1,
    FROST = 2,
    UNHOLY = 3,
}

DeathKnight.SPELL_IDS = {
    icyTouch = 45477,
    plagueStrike = 45462,
    bloodStrike = 45902,
    deathCoil = 47541,
    deathStrike = 49998,
    pestilence = 50842,
    deathAndDecay = 43265,
    bloodBoil = 48721,
    heartStrike = 55050,
    obliterate = 49020,
    frostStrike = 49143,
    howlingBlast = 49184,
    scourgeStrike = 55090,

    frostFever = 55095,
    bloodPlague = 55078,

    bloodPresence = 48266,
    frostPresence = 48263,
    unholyPresence = 48265,
    hornOfWinter = 57330,
    antiMagicShell = 48707,
    iceboundFortitude = 48792,
    mindFreeze = 47528,
    empowerRuneWeapon = 47568,
    armyOfTheDead = 42650,
    raiseDead = 46584,
    masterOfGhouls = 52143,

    dancingRuneWeapon = 49028,
    hysteria = 49016,
    vampiricBlood = 55233,
    runeTap = 48982,

    unbreakableArmor = 51271,
    hungeringCold = 49203,
    killingMachine = 51124,
    freezingFog = 59052,

    summonGargoyle = 49206,
    boneShield = 49222,
    antiMagicZone = 51052,
}

function DeathKnight:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function DeathKnight:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function DeathKnight:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function DeathKnight:HasOwnTargetAura(spellIds)
    return self:FindOwnTargetAura(spellIds) ~= nil
end

function DeathKnight:HasBothDiseases()
    return self:HasOwnTargetAura({ self.SPELL_IDS.frostFever })
        and self:HasOwnTargetAura({ self.SPELL_IDS.bloodPlague })
end

function DeathKnight:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function DeathKnight:GetPermanentGhoulState()
    local alive = UnitExists and UnitExists("pet") and not (UnitIsDead and UnitIsDead("pet")) or false
    return {
        active = alive == true or alive == 1,
        spellId = self.SPELL_IDS.raiseDead,
    }
end
