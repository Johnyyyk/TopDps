local addon = TopDps
local Warrior = addon:CreateModule("Warrior")

Warrior.CLASS_TOKEN = "WARRIOR"
Warrior.TALENT_TABS = {
    ARMS = 1,
    FURY = 2,
    PROTECTION = 3,
}

Warrior.SPELL_IDS = {
    rend = 772,
    mortalStrike = 12294,
    overpower = 7384,
    execute = 5308,
    slam = 1464,
    bladestorm = 46924,
    sweepingStrikes = 12328,
    heroicStrike = 78,
    cleave = 845,
    sunderArmor = 7386,
    thunderClap = 6343,

    bloodthirst = 23881,
    whirlwind = 1680,
    deathWish = 12292,
    recklessness = 1719,

    tasteForBlood = 60503,
    suddenDeath = 52437,
    bloodsurge = 46916,

    battleShout = 6673,
    commandingShout = 469,
    battleStance = 2457,
    defensiveStance = 71,
    berserkerStance = 2458,

    berserkerRage = 18499,
    enragedRegeneration = 55694,
    shieldWall = 871,
    lastStand = 12975,
    shieldBlock = 2565,
    spellReflection = 23920,
    pummel = 6552,
    intervene = 3411,
    challengingShout = 1161,
    shieldSlam = 23922,
    vigilance = 50720,
}

function Warrior:FindPlayerAura(spellIds)
    return addon.AuraService:FindAura("player", spellIds, "HELPFUL", false)
end

function Warrior:FindTargetAura(spellIds)
    return addon.AuraService:FindAura("target", spellIds, "HARMFUL", false)
end

function Warrior:HasPlayerAura(spellIds)
    return self:FindPlayerAura(spellIds) ~= nil
end

function Warrior:GetEnemyCount(context)
    return tonumber(context and (context.activeEnemyCount or context.enemyCount)) or 0
end

function Warrior:GetRage(context)
    return math.max(0, tonumber(context and context.player and context.player.power and context.player.power.current) or 0)
end

function Warrior:IsExecuteRange(context)
    local health = context and context.target and context.target.health or nil
    return health and health.maximum > 0 and health.fraction <= 0.20 or false
end

function Warrior:IsCategoryQueued(context, category)
    if not addon.SwingService or not addon.SwingService.IsActionQueued then
        return false
    end

    local entries = context and context.actionsByCategory and context.actionsByCategory[category] or nil
    local index
    for index = 1, #(entries or {}) do
        if addon.SwingService:IsActionQueued(entries[index].action) then
            return true
        end
    end

    return false
end

function Warrior:ShouldMaintainSunder(context)
    local expose = self:FindTargetAura({ 8647, 11197, 11198, 26866, 48669 })
    if expose then
        return false
    end

    local sunder = self:FindTargetAura({ 7386, 7405, 8380, 11596, 11597, 25225, 47467, 58567 })
    if not sunder then
        return true
    end

    if (tonumber(sunder.stacks) or 0) < 5 then
        return true
    end

    local expirationTime = tonumber(sunder.expirationTime) or 0
    if expirationTime > 0 then
        local now = context and tonumber(context.now) or GetTime()
        return expirationTime - now <= 5
    end

    return false
end

function Warrior:GetRequiredStanceState(spellId)
    local expectedName = GetSpellInfo and GetSpellInfo(spellId) or nil
    if not expectedName or not GetShapeshiftFormInfo then
        return {
            active = false,
            spellId = spellId,
            statusText = "?",
        }
    end

    local index
    for index = 1, 3 do
        local ok, _, name, active = pcall(GetShapeshiftFormInfo, index)
        if ok and name == expectedName then
            return {
                active = active == true or active == 1,
                spellId = spellId,
            }
        end
    end

    return {
        active = false,
        spellId = spellId,
    }
end
