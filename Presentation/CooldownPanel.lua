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
    iconFrame:EnableMouse(true)
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
        else
            GameTooltip:SetText(entry.name or addon.NAME)
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

function CooldownPanel:SetEntries(entries)
    self.entries = entries or {}

    local index
    for index = 1, #self.entries do
        local icon = self.icons[index] or self:CreateIcon(index)
        local entry = self.entries[index]
        icon.frame.entry = entry
        icon.texture:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        icon.frame:Show()
    end

    for index = #self.entries + 1, #self.icons do
        self.icons[index].frame:Hide()
        self.icons[index].frame.entry = nil
    end

    self:ApplyLayout()
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

    icon.texture:SetDesaturated(isCooldown)
    icon.cooldown:SetReverse(isActive)

    if (isCooldown or isActive) and state.duration and state.duration > 0 then
        icon.cooldown:SetCooldown(state.start or GetTime(), state.duration)
    else
        icon.cooldown:SetCooldown(0, 0)
    end

    icon.timeText:SetText(FormatRemaining(state.remaining))

    if state.stacks and state.stacks > 1 then
        icon.stackText:SetText(tostring(state.stacks))
    else
        icon.stackText:SetText("")
    end
end

function CooldownPanel:Update(states)
    if not self.frame then
        return
    end

    self.frame:Show()

    local index
    for index = 1, #self.entries do
        self:UpdateIcon(self.icons[index], states[index])
    end
end

function CooldownPanel:Show()
    if self.frame then
        self.frame:Show()
    end
end

function CooldownPanel:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
