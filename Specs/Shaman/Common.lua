local addon = TopDps
local Shaman = addon:CreateModule("Shaman")

Shaman.CLASS_TOKEN = "SHAMAN"
Shaman.TALENT_TABS = {
    ELEMENTAL = 1,
    ENHANCEMENT = 2,
    RESTORATION = 3,
}

Shaman.SPELL_IDS = {
    lightningBolt = 403,
    chainLightning = 421,
    earthShock = 8042,
    flameShock = 8050,
    lavaBurst = 51505,
    fireNova = 1535,

    stormstrike = 17364,
    lavaLash = 60103,
    maelstromWeapon = 53817,

    lightningShield = 49281,
    waterShield = 57960,
    elementalFocus = 16246,
    elementalMastery = 16166,
    thunderstorm = 51490,
    feralSpirit = 51533,
    shamanisticRage = 30823,

    natureSwiftness = 16188,
    manaTide = 16190,
    tidalForce = 55198,
    tidalWaves = 53390,
    earthShield = 974,
    riptide = 61295,

    flametongueWeapon = 58790,
    windfuryWeapon = 58804,
    earthlivingWeapon = 51994,

    bloodlust = 2825,
    heroism = 32182,
    windShear = 57994,
    tremorTotem = 8143,
    groundingTotem = 8177,
    callOfTheElements = 66842,
}

Shaman.WEAPON_ENCHANT_SPELL_IDS = {
    flametongue = { 8024, 8027, 8030, 16339, 16341, 16342, 25489, 58785, 58789, 58790 },
    windfury = { 8232, 8235, 10486, 16362, 25505, 58801, 58803, 58804 },
    earthliving = { 51730, 51988, 51991, 51992, 51993, 51994 },
}

function Shaman:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Shaman:FindOwnTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", true)
end

function Shaman:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Shaman:HasOwnTargetAura(spellIds)
    return self:FindOwnTargetAura(spellIds) ~= nil
end

function Shaman:GetAuraStacks(spellIds)
    local aura = self:FindPlayerAura(spellIds)
    return aura and math.max(0, tonumber(aura.stacks) or 0) or 0
end

function Shaman:GetMaelstromReadyState()
    local stacks = self:GetAuraStacks({ self.SPELL_IDS.maelstromWeapon })
    return {
        active = stacks >= 5,
        spellId = self.SPELL_IDS.maelstromWeapon,
        stacks = stacks,
        showStacks = true,
    }
end

function Shaman:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Shaman:IsMoving(context)
    return context
        and context.player
        and context.player.movement
        and context.player.movement.moving == true
        or false
end

function Shaman:GetWeaponImbueState(slot, displaySpellId, enchantSpellIds)
    if not addon.EquipmentService then
        return {
            active = false,
            spellId = displaySpellId,
            statusText = "?",
        }
    end

    local active, enchant = addon.EquipmentService:MatchesTemporaryEnchantSpellIds(slot, enchantSpellIds)
    return {
        active = active,
        spellId = displaySpellId,
        statusText = enchant and enchant.active and not enchant.name and "?" or nil,
    }
end

function Shaman:GetFireTotemState()
    if not GetTotemInfo then
        return {
            active = false,
            spellId = self.SPELL_IDS.callOfTheElements,
            statusText = "?",
        }
    end

    local slot = FIRE_TOTEM_SLOT or 1
    local ok, haveTotem, name, startTime, duration, icon = pcall(GetTotemInfo, slot)
    if not ok then
        return {
            active = false,
            spellId = self.SPELL_IDS.callOfTheElements,
            statusText = "?",
        }
    end

    local active = haveTotem == true or haveTotem == 1
    return {
        active = active,
        spellId = self.SPELL_IDS.callOfTheElements,
        icon = icon,
        statusText = active and nil or "—",
        name = name,
        start = startTime,
        duration = duration,
    }
end
