local addon = TopDps
local CooldownPanel = addon:CreateModule("CooldownPanel")

CooldownPanel.MAX_ICONS_PER_ROW = 7
CooldownPanel.PADDING = 8
CooldownPanel.WARNING_GROUP = "WARNING"
CooldownPanel.VISUAL_GROUP_ORDER = {
    CooldownPanel.WARNING_GROUP,
    addon.PANEL_CATEGORY_PROCS,
    addon.PANEL_CATEGORY_ABILITIES,
    addon.PANEL_CATEGORY_COOLDOWNS,
}

CooldownPanel.entries = {}
CooldownPanel.icons = {}
CooldownPanel.states = {}
CooldownPanel.layoutSignature = nil
CooldownPanel.isDragging = false

function CooldownPanel:IsActiveState(state)
    return state and state.state == "ACTIVE"
end

function CooldownPanel:GetPresentation(entry)
    if addon.CooldownRegistry then
        return addon.CooldownRegistry:GetPanelPresentation(entry)
    end

    return addon.PANEL_CATEGORY_ABILITIES, addon.PANEL_BEHAVIOR_ALWAYS
end

function CooldownPanel:GetCategoryOrder(category)
    local index
    for index = 1, #addon.PANEL_CATEGORY_ORDER do
        if addon.PANEL_CATEGORY_ORDER[index] == category then
            return index
        end
    end

    return 100
end

function CooldownPanel:StartDragging()
    if not self.frame or not addon.db or addon.db.panel.locked or self.isDragging then
        return
    end

    self.isDragging = true
    self.frame:StartMoving()
end

function CooldownPanel:StopDragging()
    if not self.frame or not self.isDragging then
        return
    end

    self.frame:StopMovingOrSizing()
    self.isDragging = false
    if not addon.db then
        return
    end

    local x, y = self.frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if x and y and parentX and parentY then
        addon.Settings:SetCooldownPanelPosition(x - parentX, y - parentY)
    end
end

function CooldownPanel:Initialize()
    if self.frame then
        return
    end

    addon.Settings:EnsureCooldownPanelUxDefaults()

    local frame = CreateFrame("Frame", "TopDpsCooldownPanel", UIParent)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.55)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    title:SetText(addon.L.COOLDOWN_PANEL_DRAG_HINT)

    frame:SetScript("OnDragStart", function()
        CooldownPanel:StartDragging()
    end)

    frame:SetScript("OnDragStop", function()
        CooldownPanel:StopDragging()
    end)

    frame:SetScript("OnHide", function()
        CooldownPanel:StopDragging()
    end)

    self.frame = frame
    self.title = title
    self:ApplyLayout(self.states)
    self:ApplyLockState()
    self:Hide()
end

function CooldownPanel:CreateIcon(index)
    local iconFrame = CreateFrame("Frame", "TopDpsCooldownIcon" .. tostring(index), self.frame)
    iconFrame:SetFrameLevel(self.frame:GetFrameLevel() + 2)
    iconFrame:EnableMouse(not (addon.db and addon.db.panel.locked))
    iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetScript("OnDragStart", function()
        CooldownPanel:StartDragging()
    end)
    iconFrame:SetScript("OnDragStop", function()
        CooldownPanel:StopDragging()
    end)

    local texture = iconFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(iconFrame)

    local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(iconFrame)

    local accent = iconFrame:CreateTexture(nil, "OVERLAY")
    accent:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    accent:SetBlendMode("ADD")
    accent:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    accent:Hide()

    local timeText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
    timeText:SetJustifyH("CENTER")

    local stackText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stackText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    stackText:SetJustifyH("RIGHT")

    iconFrame:SetScript("OnEnter", function(self)
        local entry = self.entry
        if not entry then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if entry.type == "trinket" and entry.slot and GameTooltip.SetInventoryItem then
            GameTooltip:SetInventoryItem("player", entry.slot)
        elseif self.stateSpellId and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(self.stateSpellId)
        elseif entry.displaySpellId and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(entry.displaySpellId)
        elseif entry.spellId and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(entry.spellId)
        else
            GameTooltip:SetText(entry.name or addon.NAME)
        end

        if self.stateUnitName then
            GameTooltip:AddLine(string.format(addon.L.COOLDOWN_AURA_TARGET, self.stateUnitName), 1, 1, 1)
        end

        if self.stateBlockerSpellId then
            local blockerName = GetSpellInfo(self.stateBlockerSpellId)
            if blockerName then
                GameTooltip:AddLine(string.format(addon.L.COOLDOWN_BLOCKED_BY, blockerName), 1, 0.35, 0.35)
            end
        end

        if self.isMissingRequirement then
            local _, behavior = CooldownPanel:GetPresentation(entry)
            local message = addon.L.COOLDOWN_REQUIRED_BUFF_MISSING
            if behavior == addon.PANEL_BEHAVIOR_REQUIRED_STATE then
                message = addon.L.COOLDOWN_REQUIRED_STATE_MISSING
            end

            GameTooltip:AddLine(message, 1, 0.25, 0.15)
        end

        GameTooltip:Show()
    end)

    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local icon = {
        frame = iconFrame,
        texture = texture,
        cooldown = cooldown,
        accent = accent,
        timeText = timeText,
        stackText = stackText,
    }

    self.icons[index] = icon
    return icon
end

function CooldownPanel:ResetIconVisualCache(icon)
    icon.lastTexture = nil
    icon.lastDesaturated = nil
    icon.lastReverse = nil
    icon.lastCooldownId = nil
    icon.lastTimeText = nil
    icon.lastStackText = nil
end

function CooldownPanel:InvalidateLayout()
    self.layoutSignature = nil
end

function CooldownPanel:SetEntries(entries)
    if addon.ProcSoundAlerts then
        addon.ProcSoundAlerts:Reset()
    end

    self.entries = entries or {}
    self.states = {}

    local index
    for index = 1, #self.entries do
        local icon = self.icons[index] or self:CreateIcon(index)
        local entry = self.entries[index]
        icon.frame.entry = entry
        icon.frame.stateSpellId = nil
        icon.frame.stateUnitName = nil
        icon.frame.stateBlockerSpellId = nil
        icon.frame.isMissingRequirement = false
        icon.texture:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        self:ResetIconVisualCache(icon)
        icon.frame:Show()
    end

    for index = #self.entries + 1, #self.icons do
        local icon = self.icons[index]
        icon.frame:Hide()
        icon.frame.entry = nil
        icon.frame.stateSpellId = nil
        icon.frame.stateUnitName = nil
        icon.frame.stateBlockerSpellId = nil
        icon.frame.isMissingRequirement = false
        icon.accent:Hide()
        self:ResetIconVisualCache(icon)
    end

    self:InvalidateLayout()
    self:ApplyLayout(self.states)
    self:ApplyLockState()
end

function CooldownPanel:ApplyLockState()
    if not self.frame or not addon.db then
        return
    end

    local locked = addon.db.panel.locked == true
    if locked then
        self:StopDragging()
    end
    self.frame:EnableMouse(not locked)

    local index
    for index = 1, #self.icons do
        self.icons[index].frame:EnableMouse(not locked)
    end

    if locked then
        self.frame:SetBackdropColor(0, 0, 0, 0)
        self.frame:SetBackdropBorderColor(1, 1, 1, 0)
        self.title:Hide()
    else
        self.frame:SetBackdropColor(0, 0, 0, 0.55)
        self.frame:SetBackdropBorderColor(1, 1, 1, 0.45)
        self.title:Show()
    end

    self:InvalidateLayout()
    self:ApplyLayout(self.states)
end

function CooldownPanel:ResetPosition()
    if addon.db then
        addon.Settings:SetCooldownPanelPosition(addon.DEFAULTS.cooldownPanelX, addon.DEFAULTS.cooldownPanelY)
    end
end

function CooldownPanel:Show()
    if self.frame and not self.frame:IsShown() then
        self.frame:Show()
    end
end

function CooldownPanel:Hide()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
    end
end
