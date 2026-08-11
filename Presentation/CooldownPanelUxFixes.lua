local addon = TopDps
local CooldownPanel = addon.CooldownPanel

local originalIsEntryVisible = CooldownPanel.IsEntryVisible
function CooldownPanel:IsEntryVisible(entry, state, previewUnlocked)
    if not state then
        return false
    end

    return originalIsEntryVisible(self, entry, state, previewUnlocked)
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
            if count > 0 then
                row.width = row.width + iconGap
            end
            row.width = row.width + item.size
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
