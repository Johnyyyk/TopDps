local addon = TopDps
local CooldownPanel = addon.CooldownPanel

function CooldownPanel:IsEntryVisible(entry, state, previewUnlocked)
    local category, behavior = self:GetPresentation(entry)
    if not addon.Settings:IsCooldownPanelCategoryEnabled(category) then
        return false
    end

    if previewUnlocked then
        return true
    end

    if behavior == addon.PANEL_BEHAVIOR_ACTIVE_ONLY then
        return self:IsActiveState(state)
    end

    if behavior == addon.PANEL_BEHAVIOR_REQUIRED_BUFF then
        return not self:IsActiveState(state)
    end

    return true
end

function CooldownPanel:ResolveVisualGroup(entry, state, previewUnlocked)
    local category, behavior = self:GetPresentation(entry)

    if behavior == addon.PANEL_BEHAVIOR_REQUIRED_BUFF then
        return self.WARNING_GROUP
    end

    if behavior == addon.PANEL_BEHAVIOR_SELECTABLE_BUFF then
        if not previewUnlocked and not self:IsActiveState(state) then
            return self.WARNING_GROUP
        end

        return addon.PANEL_CATEGORY_ABILITIES
    end

    if entry.type == "trinket" and entry.procData and self:IsActiveState(state) then
        return addon.PANEL_CATEGORY_PROCS
    end

    if category == addon.PANEL_CATEGORY_BUFFS then
        return addon.PANEL_CATEGORY_ABILITIES
    end

    return category
end

function CooldownPanel:GetIconSize(entry, visualGroup)
    local category = self:GetPresentation(entry)
    local scaleCategory = category

    if entry.type == "trinket"
        and entry.procData
        and visualGroup == addon.PANEL_CATEGORY_PROCS then
        scaleCategory = addon.PANEL_CATEGORY_PROCS
    end

    local baseSize = addon.db.cooldownPanelIconSize or addon.DEFAULTS.cooldownPanelIconSize
    local scale = addon.Settings:GetCooldownPanelCategoryScale(scaleCategory)

    if visualGroup == self.WARNING_GROUP then
        scale = math.max(1, scale) * addon.COOLDOWN_PANEL_WARNING_SCALE
    end

    return math.max(18, math.floor(baseSize * scale + 0.5))
end

function CooldownPanel:BuildLayoutRows(states)
    local buckets = {}
    local groupIndex
    for groupIndex = 1, #self.VISUAL_GROUP_ORDER do
        buckets[self.VISUAL_GROUP_ORDER[groupIndex]] = {}
    end

    local previewUnlocked = addon.db.cooldownPanelLocked == false
    local signatureParts = { previewUnlocked and "preview" or "locked" }
    local visibleCount = 0
    local index

    for index = 1, #self.entries do
        local entry = self.entries[index]
        local state = states and states[index] or nil
        if self:IsEntryVisible(entry, state, previewUnlocked) then
            local category = self:GetPresentation(entry)
            local visualGroup = self:ResolveVisualGroup(entry, state, previewUnlocked)
            local size = self:GetIconSize(entry, visualGroup)
            local item = {
                index = index,
                entry = entry,
                state = state,
                category = category,
                visualGroup = visualGroup,
                size = size,
            }

            if not buckets[visualGroup] then
                buckets[visualGroup] = {}
            end

            table.insert(buckets[visualGroup], item)
            signatureParts[#signatureParts + 1] = table.concat({ index, visualGroup, size }, ":")
            visibleCount = visibleCount + 1
        end
    end

    local abilities = buckets[addon.PANEL_CATEGORY_ABILITIES]
    table.sort(abilities, function(left, right)
        local leftOrder = self:GetCategoryOrder(left.category)
        local rightOrder = self:GetCategoryOrder(right.category)
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end

        return left.index < right.index
    end)

    local rows = {}
    local iconGap = addon.db.cooldownPanelIconGap or addon.DEFAULTS.cooldownPanelIconGap
    local groupGap = addon.db.cooldownPanelGroupGap or addon.DEFAULTS.cooldownPanelGroupGap
    local previousVisualGroup

    for groupIndex = 1, #self.VISUAL_GROUP_ORDER do
        local visualGroup = self.VISUAL_GROUP_ORDER[groupIndex]
        local items = buckets[visualGroup]
        local itemIndex = 1

        while itemIndex <= #items do
            local row = {
                visualGroup = visualGroup,
                items = {},
                width = 0,
                height = 0,
                gapBefore = 0,
            }

            local count = 0
            while itemIndex <= #items and count < self.MAX_ICONS_PER_ROW do
                local item = items[itemIndex]
                row.items[#row.items + 1] = item
                if count > 0 then
                    row.width = row.width + iconGap
                end
                row.width = row.width + item.size
                row.height = math.max(row.height, item.size)

                itemIndex = itemIndex + 1
                count = count + 1
            end

            if #rows > 0 then
                if previousVisualGroup == visualGroup then
                    row.gapBefore = iconGap
                else
                    row.gapBefore = groupGap
                end
            end

            rows[#rows + 1] = row
            previousVisualGroup = visualGroup
        end
    end

    return rows, visibleCount, table.concat(signatureParts, "|")
end

function CooldownPanel:ApplyLayout(states)
    if not self.frame or not addon.db then
        return 0
    end

    states = states or self.states or {}
    local rows, visibleCount, signature = self:BuildLayoutRows(states)
    local maximumWidth = 0
    local contentHeight = 0
    local rowIndex

    for rowIndex = 1, #rows do
        local row = rows[rowIndex]
        maximumWidth = math.max(maximumWidth, row.width)
        contentHeight = contentHeight + row.gapBefore + row.height
    end

    local baseSize = addon.db.cooldownPanelIconSize or addon.DEFAULTS.cooldownPanelIconSize
    local width = math.max(baseSize + self.PADDING * 2, maximumWidth + self.PADDING * 2)
    local height = math.max(baseSize + self.PADDING * 2, contentHeight + self.PADDING * 2)

    if self.layoutSignature ~= signature then
        local iconIndex
        for iconIndex = 1, #self.entries do
            self.icons[iconIndex].frame:Hide()
        end

        local currentY = -self.PADDING
        for rowIndex = 1, #rows do
            local row = rows[rowIndex]
            currentY = currentY - row.gapBefore
            local x = self.PADDING + (maximumWidth - row.width) / 2
            local itemIndex

            for itemIndex = 1, #row.items do
                local item = row.items[itemIndex]
                local icon = self.icons[item.index] or self:CreateIcon(item.index)
                local y = currentY - (row.height - item.size) / 2

                icon.frame:ClearAllPoints()
                icon.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
                icon.frame:SetWidth(item.size)
                icon.frame:SetHeight(item.size)
                icon.frame:Show()

                local accentSize = math.floor(item.size * 1.45 + 0.5)
                icon.accent:SetWidth(accentSize)
                icon.accent:SetHeight(accentSize)

                x = x + item.size + (addon.db.cooldownPanelIconGap or addon.DEFAULTS.cooldownPanelIconGap)
            end

            currentY = currentY - row.height
        end

        self.layoutSignature = signature
    end

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

    return visibleCount
end
