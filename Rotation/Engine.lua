local addon = RpalTopDps
local Engine = addon:CreateModule("RotationEngine")

function Engine:GetAvailability(provider)
    if not addon.db.enabled then
        return false, "addon_disabled"
    end

    if not addon.Settings:IsModeActive() then
        return false, "mode_inactive"
    end

    if not provider then
        return false, "unsupported_specialization"
    end

    if UnitIsDeadOrGhost("player") then
        return false, "player_dead"
    end

    if UnitHasVehicleUI and UnitHasVehicleUI("player") then
        return false, "vehicle_ui"
    end

    if not UnitExists("target") then
        return false, "no_target"
    end

    if UnitIsDead("target") then
        return false, "target_dead"
    end

    if not UnitCanAttack("player", "target") then
        return false, "target_not_attackable"
    end

    if provider.GetAvailability then
        local available, reason = provider:GetAvailability()
        if not available then
            return false, reason or "provider_unavailable"
        end
    end

    return true, "active"
end

function Engine:BuildContext(provider, actionsByCategory)
    return {
        provider = provider,
        actionBar = addon.ActionBarService,
        actionsByCategory = actionsByCategory,
        enemyCount = addon.CombatTracker:GetEnemyCount(),
        playerLevel = UnitLevel("player"),
    }
end

function Engine:UpdateRecommendation()
    local provider = addon.SpecRegistry:GetActiveProvider()
    local canRun, blockReason = self:GetAvailability(provider)

    if not canRun then
        addon.Logger:SetRotationState("blocked:" .. tostring(blockReason))
        addon.RecommendationPresenter:Clear()
        return
    end

    local actionsByCategory = addon.ActionBarService:CollectVisibleActions(provider)
    local context = self:BuildContext(provider, actionsByCategory)
    local priority = provider:GetPriority(context)
    local actionSummary = addon.ActionBarService:BuildActionSummary(provider, actionsByCategory)
    local index

    for index = 1, #priority do
        local category = priority[index]
        local entries = actionsByCategory[category]

        if entries and provider:IsCategoryAllowed(category, context) then
            local readyEntries = addon.ActionBarService:GetReadyEntries(entries, category, provider, context)
            if #readyEntries > 0 then
                addon.Logger:SetRotationState(
                    "recommend:" .. category
                        .. "; enemies=" .. tostring(context.enemyCount)
                        .. "; " .. actionSummary
                )
                addon.RecommendationPresenter:Set(provider, category, readyEntries)
                return
            end
        end
    end

    addon.Logger:SetRotationState(
        "no_ready_action; enemies=" .. tostring(context.enemyCount) .. "; " .. actionSummary
    )
    addon.RecommendationPresenter:Clear()
end
