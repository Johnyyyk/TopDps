local addon = TopDps
local RotationEngine = addon:CreateModule("RotationEngine")

local function IsPrimaryCategoryAllowed(provider, category, context)
    return provider:IsCategoryAllowed(category, context)
end

local function IsNextSwingCategoryAllowed(provider, category, context)
    return provider:IsNextSwingCategoryAllowed(category, context)
end

function RotationEngine:GetAvailability(provider)
    if not addon.Settings:IsRotationEnabled() then
        return false, "rotation_disabled"
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

    local available, reason = provider:GetAvailability()
    if not available then
        return false, reason or "provider_unavailable"
    end

    return true, "active"
end

function RotationEngine:GetReadyRecommendation(provider, priority, abilitiesByCategory, context, isCategoryAllowed)
    local index

    for index = 1, #(priority or {}) do
        local category = priority[index]
        local entries = abilitiesByCategory[category]

        if entries
            and provider:IsCategoryEnabled(category)
            and addon.RefreshService:IsCategoryRefreshDue(provider, category, context)
            and isCategoryAllowed(provider, category, context) then
            local readyEntries = addon.ReadinessService:GetReadyEntries(entries, category, provider, context)
            if #readyEntries > 0 then
                return category, readyEntries
            end
        end
    end

    return nil, nil
end

function RotationEngine:UpdateRecommendation()
    local provider = addon.SpecManager:GetActive()
    local canRun, blockReason = self:GetAvailability(provider)

    if not canRun then
        addon.Logger:SetRotationState("blocked:" .. tostring(blockReason))
        addon.RecommendationPresenter:Clear()
        return
    end

    local abilitiesByCategory = addon.AbilityService:GetAbilities(provider)
    local context = addon.ContextBuilder:Build(provider, abilitiesByCategory)
    local abilitySummary = addon.AbilityService:BuildAbilitySummary(provider, abilitiesByCategory)

    local primaryCategory, primaryEntries = self:GetReadyRecommendation(
        provider,
        provider:GetPriority(context),
        abilitiesByCategory,
        context,
        IsPrimaryCategoryAllowed
    )

    local queuedNextSwingCategory = addon.SwingService:GetQueuedNextSwingCategory(provider)
    local nextSwingCategory
    local nextSwingEntries

    if not queuedNextSwingCategory then
        nextSwingCategory, nextSwingEntries = self:GetReadyRecommendation(
            provider,
            provider:GetNextSwingPriority(context),
            abilitiesByCategory,
            context,
            IsNextSwingCategoryAllowed
        )
    end

    if primaryEntries then
        addon.RecommendationPresenter:Set(provider, primaryCategory, primaryEntries)
    else
        addon.RecommendationPresenter:ClearPrimary()
    end

    if nextSwingEntries then
        addon.RecommendationPresenter:SetNextSwing(provider, nextSwingCategory, nextSwingEntries)
    else
        addon.RecommendationPresenter:ClearNextSwing()
    end

    local primaryState = primaryCategory and ("recommend:" .. primaryCategory) or "no_ready_action"
    local nextSwingState
    if queuedNextSwingCategory then
        nextSwingState = "queued:" .. queuedNextSwingCategory
    elseif nextSwingCategory then
        nextSwingState = "recommend:" .. nextSwingCategory
    else
        nextSwingState = "no_ready_action"
    end

    addon.Logger:SetRotationState(
        "primary=" .. primaryState
            .. "; next_swing=" .. nextSwingState
            .. "; enemies=" .. tostring(context.enemyCount)
            .. "; abilities=" .. abilitySummary
    )
end
