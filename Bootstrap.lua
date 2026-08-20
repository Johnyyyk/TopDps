local addon = TopDps

local Bootstrap = addon:CreateModule("Bootstrap")
local eventFrame = CreateFrame("Frame")
local SPEC_RETRY_DELAY = 0.5
local SPEC_RETRY_MAX_ATTEMPTS = 10

Bootstrap.eventFrame = eventFrame
Bootstrap.initialized = false
Bootstrap.updateElapsed = 0
Bootstrap.specRetryRemaining = nil
Bootstrap.specRetryAttempts = 0
Bootstrap.specRetryReason = nil

function Bootstrap:RegisterSlashCommands()
    SLASH_TOPDPS1 = "/topdps"
    SLASH_TOPDPS2 = "/td"
    SlashCmdList.TOPDPS = function()
        addon.OptionsController:Open()
    end
end

function Bootstrap:CancelSpecializationRetry()
    self.specRetryRemaining = nil
    self.specRetryAttempts = 0
    self.specRetryReason = nil
end

function Bootstrap:ScheduleSpecializationRetry(reason)
    if self.specRetryAttempts >= SPEC_RETRY_MAX_ATTEMPTS then
        addon.Logger:Info(
            "Specialization detection retry limit reached: reason=%s",
            tostring(self.specRetryReason or reason or "unknown")
        )
        self:CancelSpecializationRetry()
        return
    end

    self.specRetryRemaining = SPEC_RETRY_DELAY
    self.specRetryReason = self.specRetryReason or reason
end

function Bootstrap:HandleSpecializationChanged(event, isRetry)
    if not isRetry then
        self.specRetryAttempts = 0
        self.specRetryReason = event
    end

    local changed, resolution = addon.SpecManager:Refresh(event)
    if resolution == addon.SpecManager.RESOLUTION_NOT_READY then
        self:ScheduleSpecializationRetry(event)
        return
    end

    self:CancelSpecializationRetry()
    addon.SpecManager:RefreshSpellData()

    if changed then
        addon.RecommendationPresenter:Clear()
    end

    if addon.CooldownTracker and addon.CooldownTracker.initialized then
        addon.CooldownTracker:RefreshConfiguration()
    end
end

function Bootstrap:RetrySpecializationDetection()
    self.specRetryRemaining = nil
    self.specRetryAttempts = self.specRetryAttempts + 1

    local reason = "retry:" .. tostring(self.specRetryReason or "unknown")
    self:HandleSpecializationChanged(reason, true)
end

function Bootstrap:Initialize()
    if self.initialized then
        return
    end

    self.initialized = true

    self:HandleSpecializationChanged("initialize")
    addon.ActionBarService:CollectButtons()
    addon.CenterIcons:Initialize()
    addon.CooldownPanel:Initialize()
    addon.CooldownTracker:Initialize()
    addon.MinimapButton:Initialize()
    addon.OptionsController:Initialize()
    self:RegisterSlashCommands()

    addon.Logger:Info("Addon initialized, version %s", addon.VERSION)
    addon.Logger:WriteDiagnosticSnapshot()
end

function Bootstrap:HandleEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addon.NAME then
            addon.Database:ApplyDefaults()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if not addon.db then
            addon.Database:ApplyDefaults()
        end

        self:Initialize()
        return
    end

    if not self.initialized then
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if addon.EquipmentService then
            addon.EquipmentService:ScheduleTemporaryEnchantRefresh()
        end

        addon.SpecManager:RefreshEquipment()
        addon.CooldownTracker:RefreshConfiguration()

        local provider = addon.SpecManager:GetActive()
        local providerState = provider and provider:GetDebugState() or nil
        addon.Logger:Info(
            "Equipment state updated: provider=%s%s",
            tostring(provider and provider.id or "none"),
            providerState and ("; " .. tostring(providerState)) or ""
        )
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if addon.EquipmentService then
            addon.EquipmentService:HandleUnitInventoryChanged(unit)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon.CombatTracker:Clear()
        addon.RecommendationPresenter:Clear()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        addon.CombatTracker:RecordCombatEvent(...)
    elseif event == "UNIT_AURA" then
        local unit = ...
        addon.CooldownTracker:HandleUnitAura(unit)
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        addon.CooldownTracker:HandleGroupChanged()
    elseif event == "LEARNED_SPELL_IN_TAB" then
        addon.SpecManager:RefreshSpellData()
        addon.CooldownTracker:RefreshConfiguration()
        addon.Logger:Info("Specialization spell catalog rebuilt")
    elseif event == "PLAYER_LEVEL_UP"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "CHARACTER_POINTS_CHANGED" then
        self:HandleSpecializationChanged(event)
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:HandleSpecializationChanged(event)
        addon.CooldownTracker:HandleGroupChanged()
        addon.ActionBarService:CollectButtons()
        addon.Logger:Info("Action buttons collected: %s", #addon.ActionBarService.buttons)
    elseif event == "ACTIONBAR_PAGE_CHANGED"
        or event == "ACTIONBAR_SLOT_CHANGED"
        or event == "UPDATE_BONUS_ACTIONBAR"
        or event == "UPDATE_SHAPESHIFT_FORM" then
        addon.ActionBarService:CollectButtons()
        addon.Logger:Info("Action buttons collected: %s", #addon.ActionBarService.buttons)
    end
end

local EVENTS = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_TARGET_CHANGED",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_LEVEL_UP",
    "LEARNED_SPELL_IN_TAB",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "CHARACTER_POINTS_CHANGED",
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIONBAR_PAGE_CHANGED",
    "ACTIONBAR_UPDATE_USABLE",
    "ACTIONBAR_UPDATE_COOLDOWN",
    "UPDATE_BONUS_ACTIONBAR",
    "UPDATE_SHAPESHIFT_FORM",
    "UNIT_AURA",
    "UNIT_FLAGS",
    "UNIT_INVENTORY_CHANGED",
    "PARTY_MEMBERS_CHANGED",
    "RAID_ROSTER_UPDATE",
    "PLAYER_REGEN_ENABLED",
    "COMBAT_LOG_EVENT_UNFILTERED",
}

local index
for index = 1, #EVENTS do
    eventFrame:RegisterEvent(EVENTS[index])
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if addon.db and addon.db.debug.logging then
        addon.Logger:SafeCall("event " .. tostring(event), function(...)
            Bootstrap:HandleEvent(...)
        end, event, ...)
    else
        Bootstrap:HandleEvent(event, ...)
    end
end)

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if not Bootstrap.initialized then
        return
    end

    if Bootstrap.specRetryRemaining then
        Bootstrap.specRetryRemaining = Bootstrap.specRetryRemaining - elapsed
        if Bootstrap.specRetryRemaining <= 0 then
            Bootstrap:RetrySpecializationDetection()
        end
    end

    Bootstrap.updateElapsed = Bootstrap.updateElapsed + elapsed
    if Bootstrap.updateElapsed < 0.08 then
        return
    end

    Bootstrap.updateElapsed = 0

    if addon.db and addon.db.debug.logging then
        addon.Logger:SafeCall("UpdateRecommendation", function()
            addon.RotationEngine:UpdateRecommendation()
        end)
        addon.Logger:SafeCall("UpdateCooldownPanel", function()
            addon.CooldownTracker:Update()
        end)
    else
        addon.RotationEngine:UpdateRecommendation()
        addon.CooldownTracker:Update()
    end
end)
