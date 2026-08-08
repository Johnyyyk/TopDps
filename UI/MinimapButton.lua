local addon = RpalTopDps
local MinimapButton = addon:CreateModule("MinimapButton")

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    end

    if x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    end

    if x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    end

    if x == 0 and y > 0 then
        return math.pi / 2
    end

    if x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

local function GetModeText(mode)
    return addon.L["MODE_" .. mode] or mode
end

function MinimapButton:UpdatePosition()
    if not self.button or not addon.db then
        return
    end

    local angle = tonumber(addon.db.minimapAngle) or addon.DEFAULTS.minimapAngle
    local radians = math.rad(angle)
    local x = math.cos(radians) * addon.MINIMAP_BUTTON_RADIUS
    local y = math.sin(radians) * addon.MINIMAP_BUTTON_RADIUS

    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:UpdateAngleFromCursor()
    local minimapX, minimapY = Minimap:GetCenter()
    if not minimapX or not minimapY then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if scale and scale > 0 then
        cursorX = cursorX / scale
        cursorY = cursorY / scale
    end

    local angle = math.deg(Atan2(cursorY - minimapY, cursorX - minimapX))
    if angle < 0 then
        angle = angle + 360
    end

    addon.db.minimapAngle = angle
    self:UpdatePosition()
end

function MinimapButton:ShowMenu(anchor)
    if not self.menu then
        self.menu = CreateFrame("Frame", "RpalTopDpsMinimapMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local menu = {
        {
            text = addon.NAME,
            isTitle = true,
            notCheckable = true,
        },
        {
            text = addon.L.ENABLED,
            checked = addon.db.enabled,
            func = function()
                addon.Settings:SetEnabled(not addon.db.enabled)
            end,
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

function MinimapButton:Initialize()
    local button = CreateFrame("Button", "RpalTopDpsMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local _, _, spellTexture = GetSpellInfo(53385)
    icon:SetTexture(spellTexture or "Interface\\Icons\\Spell_Holy_DivineStorm")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(52)
    border:SetHeight(52)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            MinimapButton:UpdateAngleFromCursor()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        MinimapButton.ignoreClickUntil = GetTime() + 0.25
        addon.Logger:Info("Minimap angle changed: %.1f", tonumber(addon.db.minimapAngle) or 0)
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if MinimapButton.ignoreClickUntil and GetTime() < MinimapButton.ignoreClickUntil then
            return
        end

        if mouseButton == "LeftButton" then
            MinimapButton:ShowMenu(self)
        elseif mouseButton == "RightButton" then
            addon.OptionsController:Open()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(addon.NAME, 1, 0.82, 0)
        GameTooltip:AddLine(
            string.format(addon.L.ADDON_STATE, addon.db.enabled and addon.L.STATE_ENABLED or addon.L.STATE_DISABLED),
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

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.button = button
    self.icon = icon
    self:UpdatePosition()
    self:Refresh()
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

    if addon.db.enabled then
        self.icon:SetVertexColor(1, 1, 1)
    else
        self.icon:SetVertexColor(0.45, 0.45, 0.45)
    end
end
