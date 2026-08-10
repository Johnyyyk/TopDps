local addon = TopDps
local CooldownPanel = addon:CreateModule("CooldownPanel")

local MAX_ICONS_PER_ROW = 8
local GROUP_GAP = 10
local PADDING = 8
CooldownPanel.entries = {}
CooldownPanel.icons = {}
CooldownPanel.lastTextUpdate = 0

local function FormatRemaining(remaining)
    remaining = tonumber(remaining) or 0
    if remaining <= 0 then
        return ""
    end

    if remaining >= 60 then
        return tostring(math.ceil(remaining / 60)) .. "m"
    end

    if remaining >= 10 then
        return tostring(math.ceil(remaining))
    end

    return string.format("%.1f", remaining)
end

function CooldownPanel:SavePosition()
    if not self.frame or not addon.db or addon.db.cooldownPanelLocked then
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

    frame:SetScript("OnDragStart", function(self)
        if not addon.db.cooldownPanelLocked then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        CooldownPanel:SavePosition()
    end)

    self.frame = frame
    self.title = title
    self:ApplyLayout()
    self:ApplyLockState()
    self:Hide()
end

function CooldownPanel:CreateIcon(index)
    local iconFrame = CreateFrame("Frame", "TopDpsCooldownIcon" .. tostring(index), self.frame)
    iconFrame:SetFrameLevel(self.frame:GetFrameLevel() + 2)
    iconFrame:EnableMouse(not (addon.db and addon.db.cooldownPanelLocked))
    iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetScript("OnDragStart", function()
        if not addon.db.cooldownPanelLocked then
            CooldownPanel.frame:StartMoving()
        end
    end)
    iconFrame:SetScript("OnDragStop", function()
        CooldownPanel.frame:StopMovingOrSizing()
        CooldownPanel:SavePosition()
    end)

    local texture = iconFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(iconFrame)

    local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(iconFrame)

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

        GameTooltip:Show()
    end)

    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local icon = {
        frame = iconFrame,
        texture = texture,
        cooldown = cooldown,
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

function CooldownPanel:SetEntries(entries)
    self.entries = entries or {}

    local index
    for index = 1, #self.entries do
        local icon = self.icons[index] or self:CreateIcon(index)
        local entry = self.entries[index]
        icon.frame.entry = entry
        icon.frame.stateSpellId = nil
        icon.frame.stateUnitName = nil
        icon.frame.stateBlockerSpellId = nil
        icon.texture:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        self:ResetIconVisualCache(icon)
        icon.frame:Show()
    end

    for index = #self.entries + 1, #self.icons do
        self.icons[index].frame:Hide()
        self.icons[index].frame.entry = nil
        self.icons[index].frame.stateSpellId = nil
        self.icons[index].frame.stateUnitName = nil
        self.icons[index].frame.stateBlockerSpellId = nil
        self:ResetIconVisualCache(self.icons[index])
    end

    self:ApplyLayout()
    self:ApplyLockState()
end

function CooldownPanel:ApplyLayout()
    if not self.frame or not addon.db then
        return
    end

    local size = addon.db.cooldownPanelIconSize or addon.DEFAULTS.cooldownPanelIconSize
    local x = PADDING
    local y = -PADDING
    local row = 1
    local column = 0
    local maximumWidth = 0
    local previousGroup
    local index

    for index = 1, #self.entries do
        local entry = self.entries[index]
        local icon = self.icons[index] or self:CreateIcon(index)

        if column >= MAX_ICONS_PER_ROW then
            maximumWidth = math.max(maximumWidth, x - PADDING)
            row = row + 1
            column = 0
            x = PADDING
            y = -PADDING - (row - 1) * (size + 4)
            previousGroup = nil
        end

        if previousGroup and previousGroup ~= entry.group then
            x = x + GROUP_GAP
        end

        icon.frame:ClearAllPoints()
        icon.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        icon.frame:SetWidth(size)
        icon.frame:SetHeight(size)

        x = x + size + 4
        column = column + 1
        previousGroup = entry.group
    end

    maximumWidth = math.max(maximumWidth, x - PADDING)
    local width = math.max(size + PADDING * 2, maximumWidth + PADDING)
    local height = math.max(size + PADDING * 2, row * size + (row - 1) * 4 + PADDING * 2)

    self.frame:SetWidth(width)
    self.frame:SetHeight(height)
    self.frame:SetAlpha(addon.db.cooldownPanelOpacity or addon.DEFAULTS.cooldownPanelOpacity)

    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        addon.db.cooldownPanelX or addon.DEFAULTS.cooldownPanelX,
        addon.db.cooldownPanelY or addon.DEFAULTS.cooldownPanelY
    )
end

function CooldownPanel:ApplyLockState()
    if not self.frame or not addon.db then
        return
    end

    local locked = addon.db.cooldownPanelLocked == true
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
end

function CooldownPanel:ResetPosition()
    if not addon.db then
        return
    end

    addon.Settings:SetCooldownPanelPosition(addon.DEFAULTS.cooldownPanelX, addon.DEFAULTS.cooldownPanelY)
end

function CooldownPanel:UpdateIcon(icon, state)
    if not state then
        return
    end

    local isCooldown = state.state == "COOLDOWN"
    local isActive = state.state == "ACTIVE"
    local isInactive = state.state == "INACTIVE"
    local isBlocked = state.state == "BLOCKED"
    local desaturated = isCooldown or isInactive or isBlocked
    local entry = icon.frame.entry
    local texture = state.icon
        or (entry and entry.icon)
        or "Interface\\Icons\\INV_Misc_QuestionMark"

    if icon.lastTexture ~= texture then
        icon.texture:SetTexture(texture)
        icon.lastTexture = texture
    end
    icon.frame.stateSpellId = state.spellId
    icon.frame.stateUnitName = state.unitName
    icon.frame.stateBlockerSpellId = state.blockerSpellId

    if icon.lastDesaturated ~= desaturated then
        icon.texture:SetDesaturated(desaturated)
        icon.lastDesaturated = desaturated
    end

    if icon.lastReverse ~= isActive then
        icon.cooldown:SetReverse(isActive)
        icon.lastReverse = isActive
    end

    local hasSweep = (isCooldown or isActive or isBlocked) and state.duration and state.duration > 0
    local cooldownId = hasSweep and (state.cooldownId or table.concat({
        tostring(state.state),
        tostring(state.start or 0),
        tostring(state.duration or 0),
    }, ":")) or "NONE"

    if icon.lastCooldownId ~= cooldownId then
        if hasSweep then
            icon.cooldown:SetCooldown(state.start or GetTime(), state.duration)
        else
            icon.cooldown:SetCooldown(0, 0)
        end
        icon.lastCooldownId = cooldownId
    end

    local timeText = FormatRemaining(state.remaining)
    if icon.lastTimeText ~= timeText then
        icon.timeText:SetText(timeText)
        icon.lastTimeText = timeText
    end

    local stackText = state.statusText or ""
    if stackText == "" and state.stacks then
        if state.showStacks and state.stacks > 0 then
            stackText = tostring(state.stacks)
        elseif state.stacks > 1 then
            stackText = tostring(state.stacks)
        end
    end

    if icon.lastStackText ~= stackText then
        icon.stackText:SetText(stackText)
        icon.lastStackText = stackText
    end
end

function CooldownPanel:Update(states)
    if not self.frame then
        return
    end

    if not self.frame:IsShown() then
        self.frame:Show()
    end

    local index
    for index = 1, #self.entries do
        self:UpdateIcon(self.icons[index], states[index])
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