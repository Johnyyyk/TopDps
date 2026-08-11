local addon = TopDps
local CooldownTracker = addon.CooldownTracker

function CooldownTracker:IsPanelAllowedOutsideCombat()
    return addon.Settings:IsPanelEnabled() and addon.db.cooldownPanelLocked == false
end

function CooldownTracker:Update()
    if not addon.CooldownPanel or not addon.db then
        return
    end

    if not addon.Settings:IsPanelEnabled() then
        addon.CooldownPanel:Hide()
        return
    end

    local previewUnlocked = self:IsPanelAllowedOutsideCombat()
    if not addon.Settings:IsModeActive() and not previewUnlocked then
        addon.CooldownPanel:Hide()
        return
    end

    if addon.Settings:IsCooldownPanelCombatOnly() and not UnitAffectingCombat("player") and not previewUnlocked then
        addon.CooldownPanel:Hide()
        return
    end

    if #self.entries == 0 then
        addon.CooldownPanel:Hide()
        return
    end

    self:ScanPlayerAuras()

    local states = {}
    local index
    for index = 1, #self.entries do
        local entry = self.entries[index]
        if entry.type == "spell" then
            states[index] = self:GetSpellState(entry)
        elseif entry.type == "aura" then
            states[index] = self:GetAuraState(entry)
        elseif entry.type == "counter" then
            states[index] = self:GetCounterState(entry)
        elseif entry.type == "trinket" then
            states[index] = self:GetTrinketState(entry)
        end
    end

    addon.CooldownPanel:Update(states)
end
