local addon = TopDps
local Settings = addon.Settings

addon.EXPERIMENTAL_FEATURE_TARGET_TIME_TO_DIE = "targetTimeToDie"

function Settings:IsExperimentalFeaturesEnabled()
    return addon.db and addon.db.experimentalFeaturesEnabled == true
end

function Settings:SetExperimentalFeaturesEnabled(enabled)
    if not addon.db then
        return
    end

    local normalized = enabled and true or false
    if addon.db.experimentalFeaturesEnabled == normalized then
        return
    end

    addon.db.experimentalFeaturesEnabled = normalized

    if addon.TimeToDieService then
        addon.TimeToDieService:Reset()
    end

    if addon.RecommendationPresenter then
        addon.RecommendationPresenter:Clear()
    end

    if addon.OptionsController then
        addon.OptionsController:Refresh()
    end

    addon.Logger:Info("Experimental features enabled: %s", tostring(normalized))
end

function Settings:IsExperimentalFeatureEnabled(provider, feature)
    if not self:IsExperimentalFeaturesEnabled() or not provider or not feature then
        return false
    end

    if not provider.GetExperimentalFeatureSettingKey then
        return false
    end

    local settingKey = provider:GetExperimentalFeatureSettingKey(feature)
    if not settingKey then
        return false
    end

    return provider:GetSetting(settingKey) == true
end
