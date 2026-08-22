local addon = TopDps
local ContextBuilder = addon:CreateModule("ContextBuilder")

function ContextBuilder:Build(provider, actionsByCategory)
    local activeEnemyCount = addon.CombatTracker:GetActiveEnemyCount()

    return {
        provider = provider,
        actionBar = addon.ActionBarService,
        readiness = addon.ReadinessService,
        unitState = addon.UnitStateService,
        castService = addon.CastService,
        swingService = addon.SwingService,
        actionsByCategory = actionsByCategory,
        activeEnemyCount = activeEnemyCount,
        enemyCount = activeEnemyCount,
        player = addon.UnitStateService:GetPlayerSnapshot(),
        target = addon.UnitStateService:GetTargetSnapshot(),
        cast = addon.CastService:GetPlayerCastState(),
        swing = addon.SwingService:GetState(),
        playerLevel = UnitLevel("player"),
        now = GetTime(),
    }
end
