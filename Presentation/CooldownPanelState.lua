local addon = TopDps
local CooldownPanel = addon.CooldownPanel

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

function CooldownPanel:IsMissingRequirement(entry, state)
    local _, behavior = self:GetPresentation(entry)
    if behavior ~= addon.PANEL_BEHAVIOR_REQUIRED_BUFF
        and behavior ~= addon.PANEL_BEHAVIOR_REQUIRED_STATE
        and behavior ~= addon.PANEL_BEHAVIOR_SELECTABLE_BUFF then
        return false
    end

    return not self:IsActiveState(state)
end

function CooldownPanel:UpdateAccent(icon, entry, state)
    local missingRequirement = self:IsMissingRequirement(entry, state)
    local visualGroup = self:ResolveVisualGroup(entry, state, addon.db.panel.locked == false)
    icon.frame.isMissingRequirement = missingRequirement

    if missingRequirement then
        local pulse = 0.55 + 0.35 * math.abs(math.sin(GetTime() * 4))
        icon.accent:SetVertexColor(1, 0.15, 0.08)
        icon.accent:SetAlpha(pulse)
        icon.accent:Show()
        return
    end

    if visualGroup == addon.PANEL_CATEGORY_PROCS and self:IsActiveState(state) then
        icon.accent:SetVertexColor(1, 0.82, 0.2)
        icon.accent:SetAlpha(0.75)
        icon.accent:Show()
        return
    end

    icon.accent:Hide()
end

function CooldownPanel:UpdateIcon(icon, state)
    if not state then
        return
    end

    local entry = icon.frame.entry
    if not entry then
        return
    end

    local isCooldown = state.state == "COOLDOWN"
    local isActive = state.state == "ACTIVE"
    local isInactive = state.state == "INACTIVE"
    local isBlocked = state.state == "BLOCKED"
    local missingRequirement = self:IsMissingRequirement(entry, state)
    local desaturated = (isCooldown or isInactive or isBlocked) and not missingRequirement
    local texture = state.icon
        or entry.icon
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

    local timeText = ""
    if addon.Settings:AreCooldownPanelTimersShown() then
        timeText = FormatRemaining(state.remaining)
    end

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

    if missingRequirement and stackText == "" then
        stackText = "!"
    end

    if icon.lastStackText ~= stackText then
        icon.stackText:SetText(stackText)
        icon.lastStackText = stackText
    end

    self:UpdateAccent(icon, entry, state)
end

function CooldownPanel:RefreshVisuals()
    if not self.frame then
        return
    end

    local index
    for index = 1, #self.entries do
        local state = self.states and self.states[index] or nil
        if state then
            self:UpdateIcon(self.icons[index], state)
        end
    end

    local wasShown = self.frame:IsShown()
    self:InvalidateLayout()
    local visibleCount = self:ApplyLayout(self.states)
    if wasShown and visibleCount == 0 then
        self:Hide()
    end
end

function CooldownPanel:Update(states)
    if not self.frame then
        return
    end

    if addon.ProcSoundAlerts then
        addon.ProcSoundAlerts:Update(self.entries, states)
    end

    self.states = states or {}

    local index
    for index = 1, #self.entries do
        self:UpdateIcon(self.icons[index], self.states[index])
    end

    local visibleCount = self:ApplyLayout(self.states)
    if visibleCount > 0 then
        self:Show()
    else
        self:Hide()
    end
end
