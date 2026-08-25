local addon = TopDps
local Rogue = addon:CreateModule("Rogue")

Rogue.CLASS_TOKEN = "ROGUE"
Rogue.TALENT_TABS = {
    ASSASSINATION = 1,
    COMBAT = 2,
    SUBTLETY = 3,
}

Rogue.SPELL_IDS = {
    sliceAndDice = 5171,
    rupture = 1943,
    eviscerate = 2098,
    envenom = 32645,
    mutilate = 1329,
    sinisterStrike = 1752,
    backstab = 53,
    hemorrhage = 16511,
    exposeArmor = 8647,
    fanOfKnives = 51723,
    hungerForBlood = 51662,

    tricksOfTheTrade = 57934,
    vanish = 1856,
    evasion = 5277,
    cloakOfShadows = 31224,
    sprint = 2983,
    kick = 1766,

    coldBlood = 14177,
    overkill = 58426,
    bladeFlurry = 13877,
    adrenalineRush = 13750,
    killingSpree = 51690,
    preparation = 14185,
    shadowDance = 51713,
    premeditation = 14183,
    shadowstep = 36554,

    deadlyPoison = 2823,
}

function Rogue:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Rogue:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function Rogue:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Rogue:GetComboPoints(context)
    return math.max(0, tonumber(context and context.player and context.player.comboPoints) or 0)
end

function Rogue:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Rogue:GetWeaponPoisonState()
    if not GetWeaponEnchantInfo then
        return {
            active = false,
            spellId = self.SPELL_IDS.deadlyPoison,
            statusText = "?",
        }
    end

    local ok, mainHand, _, _, _, offHand = pcall(GetWeaponEnchantInfo)
    if not ok then
        return {
            active = false,
            spellId = self.SPELL_IDS.deadlyPoison,
            statusText = "?",
        }
    end

    local mainActive = mainHand == true or mainHand == 1
    local offActive = offHand == true or offHand == 1
    return {
        active = mainActive and offActive,
        spellId = self.SPELL_IDS.deadlyPoison,
    }
end
