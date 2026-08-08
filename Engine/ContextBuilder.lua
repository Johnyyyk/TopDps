local addon = TopDps
local ContextBuilder = addon:CreateModule("ContextBuilder")

function ContextBuilder:Build(provider, actionsByCategory)
    return {
        provider = provider,
        actionBar = addon.ActionBarService,
        readiness = addon.ReadinessService,
        actionsByCategory = actionsByCategory,
        enemyCount = addon.CombatTracker:GetEnemyCount(),
        playerLevel = UnitLevel("player"),
        now = GetTime(),
    }
end
