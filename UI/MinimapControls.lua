local addon = TopDps
local MinimapButton = addon.MinimapButton

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

local function GetStateText(enabled)
    return enabled and addon.L.STATE_ENABLED or addon.L.STATE_DISABLED
end

function MinimapButton:ShowMenu(anchor)
    if not self.menu then
        self.menu = CreateFrame("Frame", "TopDpsMinimapMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = {
        {
            text = addon.NAME,
            isTitle = true,
            notCheckable = true,
        },
        {
            text = addon.L.ROTATION_PAGE,
            checked = addon.Settings:IsRotationEnabled(),
            func = function()
                addon.Settings:SetRotationEnabled(not addon.Settings:IsRotationEnabled())
            end,
        },
        {
            text = addon.L.COOLDOWN_PAGE,
            checked = addon.Settings:IsPanelEnabled(),
            func = function()
                addon.Settings:SetCooldownPanelEnabled(not addon.Settings:IsPanelEnabled())
            end,
        },
        {
            text = addon.L.MODE,
            isTitle = true,
            notCheckable = true,
        },
    }

    local index
    for index = 1, #addon.MODE_ORDER do
        local selectedMode = addon.MODE_ORDER[index]
        table.insert(menu, {
            text = GetModeText(selectedMode),
            checked = addon.db.mode == selectedMode,
            func = function()
                addon.Settings:SetMode(selectedMode)
            end,
        })
    end

    EasyMenu(menu, self.menu, anchor, 0, 0, "MENU")
end

function MinimapButton:Refresh()
    if not self.button then
        return
    end

    if addon.db.showMinimap then
        self.button:Show()
    else
        self.button:Hide()
    end

    self.icon:SetVertexColor(1, 1, 1)
end

local originalInitialize = MinimapButton.Initialize

function MinimapButton:Initialize()
    originalInitialize(self)

    if not self.button then
        return
    end

    self.button:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:AddLine(addon.NAME, 1, 0.82, 0)
        GameTooltip:AddLine(
            string.format("%s: %s", addon.L.ROTATION_PAGE, GetStateText(addon.Settings:IsRotationEnabled())),
            1,
            1,
            1
        )
        GameTooltip:AddLine(
            string.format("%s: %s", addon.L.COOLDOWN_PAGE, GetStateText(addon.Settings:IsPanelEnabled())),
            1,
            1,
            1
        )
        GameTooltip:AddLine(string.format(addon.L.CURRENT_MODE, GetModeText(addon.db.mode)), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(addon.L.MINIMAP_LEFT_CLICK, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(addon.L.MINIMAP_RIGHT_CLICK, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(addon.L.MINIMAP_DRAG, 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
end
