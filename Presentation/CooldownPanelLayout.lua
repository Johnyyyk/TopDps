local addon = TopDps
local CooldownPanel = addon.CooldownPanel

local function IsRequiredBehavior(behavior)
    return behavior == addon.PANEL_BEHAVIOR_REQUIRED_BUFF
        or behavior == addon.PANEL_BEHAVIOR_REQUIRED_STATE
end

function CooldownPanel:IsEntryVisible(entry, state, previewUnlocked)
    if not state then
        return false
    end

    if addon.CooldownRegistry and not addon.CooldownRegistry:IsEntryApplicable(entry) then
        return false
    end

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

    if IsRequiredBehavior(behavior) then
        return not self:IsActiveState(state)
    end

    return true
end

function CooldownPanel:ResolveVisualGroup(entry, state, previewUnlocked)
    local category, behavior = self:GetPresentation(entry)

    if IsRequiredBehavior(behavior) then
        if previewUnlocked and self:IsActiveState(state) then
            return addon.PANEL_CATEGORY_BUFFS
        end

        return self.WARNING_GROUP
    end

    if behavior == addon.PANEL_BEHAVIOR_SELECTABLE_BUFF then
        if not previewUnlocked and not self:IsActiveState(state) then
            return self.WARNING_GROUP
        end

        return addon.PANEL_CATEGORY_BUFFS
    end

    return category
end

function CooldownPanel:GetIconSize(entry, visualGroup)
    local category = self:GetPresentation(entry)
    local baseSize = addon.db.panel.iconSize or addon.DEFAULTS.cooldownPanelIconSize
    local scale = addon.Settings:GetCooldownPanelCategoryScale(category)

    if visualGroup == self.WARNING_GROUP then
        scale = math.max(1, scale) * addon.COOLDOWN_PANEL_WARNING_SCALE
    end

    return math.max(18, math.floor(baseSize * scale + 0.5))
end

local function CreateBuckets(panel)
    return {
        [panel.WARNING_GROUP] = {},
        [addon.PANEL_CATEGORY_BUFFS] = {},
        [addon.PANEL_CATEGORY_PROCS] = {},
        [addon.PANEL_CATEGORY_ABILITIES] = {},
        [addon.PANEL_CATEGORY_COOLDOWNS] = {},
    }
end

function CooldownPanel:BuildBlock(items, visualGroup, iconGap)
    local category = visualGroup
    if visualGroup == self.WARNING_GROUP then
        category = addon.PANEL_CATEGORY_BUFFS
    end

    local maximumIcons = addon.Settings:GetCooldownPanelIconsPerRow(category)
    local block = {
        visualGroup = visualGroup,
        rows = {},
        width = 0,
        height = 0,
    }
    local itemIndex = 1

    while itemIndex <= #items do
        local row = {
            items = {},
            width = 0,
            height = 0,
        }
        local count = 0

        while itemIndex <= #items and count < maximumIcons do
            local item = items[itemIndex]
            row.items[#row.items + 1] = item
            if item.visible then
                if row.width > 0 then
                    row.width = row.width + iconGap
                end
                row.width = row.width + item.size
            end
            row.height = math.max(row.height, item.size)

            itemIndex = itemIndex + 1
            count = count + 1
        end

        if #block.rows > 0 then
            block.height = block.height + iconGap
        end
        block.rows[#block.rows + 1] = row
        block.width = math.max(block.width, row.width)
        block.height = block.height + row.height
    end

    return block
end

function CooldownPanel:BuildLayoutSections(states)
    local buckets = CreateBuckets(self)
    local previewUnlocked = addon.db.panel.locked == false
    local iconGap = addon.Settings:GetCooldownPanelIconGap()
    local groupGap = addon.Settings:GetCooldownPanelGroupGap()
    local buffSide = addon.Settings:GetCooldownPanelBuffSide()
    local groupOrder = addon.Settings:GetCooldownPanelGroupOrder()
    local signatureParts = {
        previewUnlocked and "preview" or "locked",
        tostring(iconGap),
        tostring(groupGap),
        tostring(buffSide),
        table.concat(groupOrder, ","),
    }
    local visibleCount = 0
    local index

    for index = 1, #self.entries do
        local entry = self.entries[index]
        local state = states and states[index] or nil
        local visible = self:IsEntryVisible(entry, state, previewUnlocked)
        if visible or self:IsEntryVisible(entry, state or {}, true) then
            local category, behavior = self:GetPresentation(entry)
            local visualGroup = self:ResolveVisualGroup(entry, state, previewUnlocked)
            local layoutGroups = { category }

            -- Резервируем высоту строк; по горизонтали учитываем только видимые иконки.
            if IsRequiredBehavior(behavior) or behavior == addon.PANEL_BEHAVIOR_SELECTABLE_BUFF then
                layoutGroups = { self.WARNING_GROUP, addon.PANEL_CATEGORY_BUFFS }
            end

            local layoutGroupIndex
            for layoutGroupIndex = 1, #layoutGroups do
                local layoutGroup = layoutGroups[layoutGroupIndex]
                local size = self:GetIconSize(entry, layoutGroup)
                local item = {
                    index = index,
                    entry = entry,
                    state = state,
                    category = category,
                    visualGroup = layoutGroup,
                    size = size,
                    visible = visible and visualGroup == layoutGroup,
                }

                if not buckets[layoutGroup] then
                    buckets[layoutGroup] = {}
                end
                buckets[layoutGroup][#buckets[layoutGroup] + 1] = item
                signatureParts[#signatureParts + 1] = table.concat({
                    index, layoutGroup, size, item.visible and 1 or 0,
                }, ":")
            end

            if visible then
                visibleCount = visibleCount + 1
            end
        end
    end

    local sections = {}
    local warningBlock = self:BuildBlock(buckets[self.WARNING_GROUP], self.WARNING_GROUP, iconGap)
    if #warningBlock.rows > 0 then
        sections[#sections + 1] = {
            kind = "block",
            block = warningBlock,
            width = warningBlock.width,
            height = warningBlock.height,
            gapBefore = 0,
        }
    end

    local groupIndex
    for groupIndex = 1, #groupOrder do
        local category = groupOrder[groupIndex]
        if category == addon.PANEL_CATEGORY_ABILITIES then
            local abilitiesBlock = self:BuildBlock(
                buckets[addon.PANEL_CATEGORY_ABILITIES],
                addon.PANEL_CATEGORY_ABILITIES,
                iconGap
            )
            local buffsBlock = self:BuildBlock(
                buckets[addon.PANEL_CATEGORY_BUFFS],
                addon.PANEL_CATEGORY_BUFFS,
                iconGap
            )
            local hasAbilities = abilitiesBlock.width > 0
            local hasBuffs = buffsBlock.width > 0

            if #abilitiesBlock.rows > 0 or #buffsBlock.rows > 0 then
                local width = abilitiesBlock.width + buffsBlock.width
                if hasAbilities and hasBuffs then
                    width = width + groupGap
                end

                sections[#sections + 1] = {
                    kind = "abilityWithBuffs",
                    abilities = abilitiesBlock,
                    buffs = buffsBlock,
                    buffSide = buffSide,
                    width = width,
                    height = math.max(abilitiesBlock.height, buffsBlock.height),
                    gapBefore = #sections > 0 and groupGap or 0,
                }
            end
        else
            local block = self:BuildBlock(buckets[category] or {}, category, iconGap)
            if #block.rows > 0 then
                sections[#sections + 1] = {
                    kind = "block",
                    block = block,
                    width = block.width,
                    height = block.height,
                    gapBefore = #sections > 0 and groupGap or 0,
                }
            end
        end
    end

    return sections, visibleCount, table.concat(signatureParts, "|")
end

function CooldownPanel:PlaceBlock(block, startX, topY, iconGap)
    local currentY = topY
    local rowIndex

    for rowIndex = 1, #block.rows do
        local row = block.rows[rowIndex]
        if rowIndex > 1 then
            currentY = currentY - iconGap
        end

        local x = startX + (block.width - row.width) / 2
        local itemIndex
        for itemIndex = 1, #row.items do
            local item = row.items[itemIndex]
            if item.visible then
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

                x = x + item.size + iconGap
            end
        end

        currentY = currentY - row.height
    end
end

function CooldownPanel:ApplyLayout(states)
    if not self.frame or not addon.db then
        return 0
    end

    states = states or self.states or {}
    local sections, visibleCount, signature = self:BuildLayoutSections(states)
    if self.isDragging then
        return visibleCount
    end

    local iconGap = addon.Settings:GetCooldownPanelIconGap()
    local groupGap = addon.Settings:GetCooldownPanelGroupGap()
    local maximumWidth = 0
    local contentHeight = 0
    local sectionIndex

    for sectionIndex = 1, #sections do
        local section = sections[sectionIndex]
        maximumWidth = math.max(maximumWidth, section.width)
        contentHeight = contentHeight + section.gapBefore + section.height
    end

    local baseSize = addon.db.panel.iconSize or addon.DEFAULTS.cooldownPanelIconSize
    local width = math.max(baseSize + self.PADDING * 2, maximumWidth + self.PADDING * 2)
    local height = math.max(baseSize + self.PADDING * 2, contentHeight + self.PADDING * 2)

    if self.layoutSignature ~= signature then
        local iconIndex
        for iconIndex = 1, #self.entries do
            self.icons[iconIndex].frame:Hide()
        end

        local currentY = -self.PADDING
        for sectionIndex = 1, #sections do
            local section = sections[sectionIndex]
            currentY = currentY - section.gapBefore
            local sectionX = (width - section.width) / 2

            if section.kind == "abilityWithBuffs" then
                local abilities = section.abilities
                local buffs = section.buffs
                local hasAbilities = abilities.width > 0
                local hasBuffs = buffs.width > 0
                local abilitiesY = currentY - (section.height - abilities.height) / 2
                local buffsY = currentY - (section.height - buffs.height) / 2

                if hasAbilities and hasBuffs then
                    if section.buffSide == addon.PANEL_BUFF_SIDE_RIGHT then
                        self:PlaceBlock(abilities, sectionX, abilitiesY, iconGap)
                        self:PlaceBlock(buffs, sectionX + abilities.width + groupGap, buffsY, iconGap)
                    else
                        self:PlaceBlock(buffs, sectionX, buffsY, iconGap)
                        self:PlaceBlock(abilities, sectionX + buffs.width + groupGap, abilitiesY, iconGap)
                    end
                elseif hasBuffs then
                    self:PlaceBlock(buffs, sectionX, buffsY, iconGap)
                else
                    self:PlaceBlock(abilities, sectionX, abilitiesY, iconGap)
                end
            else
                local block = section.block
                local blockY = currentY - (section.height - block.height) / 2
                self:PlaceBlock(block, sectionX, blockY, iconGap)
            end

            currentY = currentY - section.height
        end

        self.layoutSignature = signature
    end

    self.frame:SetWidth(width)
    self.frame:SetHeight(height)
    self.frame:SetAlpha(addon.db.panel.opacity or addon.DEFAULTS.cooldownPanelOpacity)

    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        addon.db.panel.position.x or addon.DEFAULTS.cooldownPanelX,
        addon.db.panel.position.y or addon.DEFAULTS.cooldownPanelY
    )

    return visibleCount
end
