local addon = TopDps
local CenterIcons = addon:CreateModule("CenterIcons")

local function CreateIconFrame(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    frame.elapsed = 0

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(0, 0, 0, 0.82)
    frame.background = background

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.icon = icon

    local overlay = frame:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints(frame)
    overlay:SetTexture("Interface\\AddOns\\TopDps\\Textures\\CenterFrame")
    overlay:SetBlendMode("ADD")
    frame.overlay = overlay

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        local pulse = (math.sin(self.elapsed * 3.2) + 1) * 0.5
        self.overlay:SetAlpha(0.72 + pulse * 0.28)
    end)

    frame:EnableMouse(false)
    frame:Hide()

    return frame
end

function CenterIcons:Initialize()
    self.frames = {
        CreateIconFrame("TopDpsCenterIconLeft"),
        CreateIconFrame("TopDpsCenterIconRight"),
    }

    self:ApplyLayout()
    self:SetOpacity(addon.db.centerIconsOpacity)
end

function CenterIcons:ApplyLayout()
    if not self.frames then
        return
    end

    local size = tonumber(addon.db.centerIconsSize) or addon.DEFAULTS.centerIconsSize
    size = math.max(addon.CENTER_ICON_SIZE_MIN, math.min(addon.CENTER_ICON_SIZE_MAX, size))

    local index
    for index = 1, #self.frames do
        local frame = self.frames[index]
        local direction = index == 1 and -1 or 1

        frame:SetWidth(size)
        frame:SetHeight(size)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", direction * addon.CENTER_ICON_OFFSET, 0)

        local inset = math.max(4, math.floor(size * 0.09 + 0.5))
        frame.background:ClearAllPoints()
        frame.background:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
        frame.background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
        frame.icon:ClearAllPoints()
        frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
        frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
    end
end

function CenterIcons:SetOpacity(opacity)
    if not self.frames then
        return
    end

    local index
    for index = 1, #self.frames do
        self.frames[index]:SetAlpha(opacity)
    end
end

function CenterIcons:Show(entries)
    self.currentEntries = entries

    if not entries
        or not entries[1]
        or not addon.Settings:IsRotationEnabled()
        or not addon.Settings:IsModeActive()
        or not addon.db.showCenterIcons then
        self:Hide()
        return
    end

    local texture = GetActionTexture(entries[1].action)
    if not texture then
        self:Hide()
        return
    end

    local index
    for index = 1, #self.frames do
        local frame = self.frames[index]
        frame.icon:SetTexture(texture)
        frame.elapsed = index == 1 and 0 or 0.65
        frame:SetAlpha(addon.db.centerIconsOpacity)
        frame:Show()
    end
end

function CenterIcons:Hide()
    if not self.frames then
        return
    end

    local index
    for index = 1, #self.frames do
        self.frames[index]:Hide()
    end
end

function CenterIcons:Refresh()
    if self.currentEntries then
        self:Show(self.currentEntries)
    else
        self:Hide()
    end
end
