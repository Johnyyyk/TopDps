local addon = TopDps
local ContextBuilder = addon:CreateModule("ContextBuilder")

function ContextBuilder:Build(provider, actionsByCategory)
    local activeEnemyCount = addon.CombatTracker:GetActiveEnemyCount()
    local target = addon.UnitStateService:GetTargetSnapshot()

    if addon.Settings:IsExperimentalFeatureEnabled(
        provider,
        addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE
    ) then
        target.timeToDie = addon.TimeToDieService:GetEstimate("target")
    else
        target.timeToDie = nil
        addon.TimeToDieService:Reset()
    end

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
        target = target,
        cast = addon.CastService:GetPlayerCastState(),
        swing = addon.SwingService:GetState(),
        playerLevel = UnitLevel("player"),
        now = GetTime(),
    }
end
