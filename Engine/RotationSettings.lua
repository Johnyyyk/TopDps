local addon = TopDps
local RotationEngine = addon.RotationEngine

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
