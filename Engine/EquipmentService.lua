local addon = TopDps
local EquipmentService = addon:CreateModule("EquipmentService")

local TOOLTIP_NAME = "TopDpsEquipmentServiceTooltip"
local MAIN_HAND_SLOT = 16
local OFF_HAND_SLOT = 17
local REFRESH_DELAY_SECONDS = 1
local REFRESH_ATTEMPTS = 2

EquipmentService.tooltipCache = EquipmentService.tooltipCache or {}
EquipmentService.refreshStates = EquipmentService.refreshStates or {}

local function PackValues(...)
    return {
        count = select("#", ...),
        ...,
    }
end

local function NormalizeTooltipText(text)
    if not text or text == "" then
        return nil
    end

    text = string.gsub(text, "\194\160", " ")
    text = string.gsub(text, "\226\128\175", " ")
    text = string.match(text, "^%s*(.-)%s*$")
    if not text or text == "" then
        return nil
    end

    return string.gsub(text, "%s+", " ")
end

local function NormalizeTemporaryEnchantName(name)
    name = NormalizeTooltipText(name)
    if not name then
        return nil
    end

    local withoutRank = string.match(name, "^(.-)%s+%d+$")
    return withoutRank or name
end

local function ExtractTemporaryEnchantName(text)
    text = NormalizeTooltipText(text)
    if not text then
        return nil
    end

    local name = string.match(
        text,
        "^([^%(]+)%s+%(%d+%s+[^%)]+%)%s+%([^%)]+%)$"
    )
    if not name then
        name = string.match(
            text,
            "^([^%(]+)%s+%(%d+%s+[^%)]+%)$"
        )
    end

    return NormalizeTemporaryEnchantName(name)
end

local function BuildExpectedSpellNames(spellIds)
    local names = {}

    if type(spellIds) ~= "table" then
        return names
    end

    local index
    for index = 1, #spellIds do
        local spellName = NormalizeTemporaryEnchantName(GetSpellInfo(spellIds[index]))
        if spellName then
            names[spellName] = true
        end
    end

    return names
end

local function FindExpectedNameInText(text, expectedNames)
    text = NormalizeTooltipText(text)
    if not text then
        return nil
    end

    local expectedName
    for expectedName in pairs(expectedNames or {}) do
        if string.find(text, expectedName, 1, true) then
            return expectedName
        end
    end

    return nil
end

local function FindExpectedNameInTooltip(lines, expectedNames)
    local index
    for index = 1, #(lines or {}) do
        local line = lines[index]
        local expectedName = FindExpectedNameInText(line.left, expectedNames)
            or FindExpectedNameInText(line.right, expectedNames)
        if expectedName then
            return expectedName
        end
    end

    return nil
end

local function ReadSlotValues(rawValues, slot)
    if slot == MAIN_HAND_SLOT then
        return rawValues[1], rawValues[2], rawValues[3]
    end

    if slot == OFF_HAND_SLOT then
        return rawValues[4], rawValues[5], rawValues[6]
    end

    return nil, nil, nil
end

local function IsEnchantActive(value)
    return value == true or value == 1
end

function EquipmentService:GetTooltip()
    if self.tooltip then
        return self.tooltip
    end

    if not CreateFrame or not UIParent then
        return nil
    end

    local tooltip = CreateFrame("GameTooltip", TOOLTIP_NAME, UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    self.tooltip = tooltip

    return tooltip
end

function EquipmentService:ReadTooltipLines(slot)
    local tooltip = self:GetTooltip()
    if not tooltip or not slot then
        return {}
    end

    tooltip:Hide()
    tooltip:ClearLines()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetInventoryItem("player", slot)
    tooltip:Show()

    local lines = {}
    local lineCount = tooltip:NumLines() or 0
    local index
    for index = 2, lineCount do
        local left = _G[TOOLTIP_NAME .. "TextLeft" .. tostring(index)]
        local right = _G[TOOLTIP_NAME .. "TextRight" .. tostring(index)]
        local leftText = left and left:GetText() or nil
        local rightText = right and right:GetText() or nil

        if leftText or rightText then
            lines[#lines + 1] = {
                index = index,
                left = leftText,
                right = rightText,
            }
        end
    end

    tooltip:Hide()
    return lines
end

function EquipmentService:FindTemporaryEnchantName(lines)
    local index
    for index = 1, #(lines or {}) do
        local name = ExtractTemporaryEnchantName(lines[index].left)
        if name then
            return name
        end
    end

    return nil
end

function EquipmentService:ScheduleTemporaryEnchantRefresh()
    local refreshAt = GetTime() + REFRESH_DELAY_SECONDS

    self.tooltipCache[MAIN_HAND_SLOT] = nil
    self.tooltipCache[OFF_HAND_SLOT] = nil
    self.refreshStates[MAIN_HAND_SLOT] = {
        refreshAt = refreshAt,
        attemptsRemaining = REFRESH_ATTEMPTS,
    }
    self.refreshStates[OFF_HAND_SLOT] = {
        refreshAt = refreshAt,
        attemptsRemaining = REFRESH_ATTEMPTS,
    }
end

function EquipmentService:HandleUnitInventoryChanged(unit)
    if unit ~= "player" then
        return
    end

    self:ScheduleTemporaryEnchantRefresh()
end

function EquipmentService:GetTooltipLines(slot, active)
    local state = self.refreshStates[slot]
    if state then
        if GetTime() < state.refreshAt then
            return self.tooltipCache[slot] or {}
        end

        if active then
            self.tooltipCache[slot] = self:ReadTooltipLines(slot)
        else
            self.tooltipCache[slot] = nil
        end

        state.attemptsRemaining = state.attemptsRemaining - 1
        if state.attemptsRemaining > 0 then
            state.refreshAt = GetTime() + REFRESH_DELAY_SECONDS
        else
            self.refreshStates[slot] = nil
        end

        return self.tooltipCache[slot] or {}
    end

    if not active then
        self.tooltipCache[slot] = nil
        return {}
    end

    if not self.tooltipCache[slot] then
        self.tooltipCache[slot] = self:ReadTooltipLines(slot)
    end

    return self.tooltipCache[slot]
end

function EquipmentService:GetTemporaryEnchant(slot)
    if not GetWeaponEnchantInfo then
        return {
            active = false,
            remaining = 0,
            charges = 0,
            rawValues = {
                count = 0,
            },
            tooltipLines = {},
        }
    end

    local rawValues = PackValues(GetWeaponEnchantInfo())
    local activeValue, remaining, charges = ReadSlotValues(rawValues, slot)
    local active = IsEnchantActive(activeValue)
    local tooltipLines = self:GetTooltipLines(slot, active)

    return {
        active = active,
        remaining = active and math.max(0, (tonumber(remaining) or 0) / 1000) or 0,
        charges = active and math.max(0, tonumber(charges) or 0) or 0,
        name = active and self:FindTemporaryEnchantName(tooltipLines) or nil,
        rawValues = rawValues,
        tooltipLines = tooltipLines,
    }
end

function EquipmentService:MatchesTemporaryEnchantSpellIds(slot, spellIds)
    local enchant = self:GetTemporaryEnchant(slot)
    if not enchant.active then
        return false, enchant
    end

    local expectedNames = BuildExpectedSpellNames(spellIds)
    local matchedName = FindExpectedNameInTooltip(enchant.tooltipLines, expectedNames)
    if matchedName then
        enchant.name = matchedName
        return true, enchant
    end

    if enchant.name and expectedNames[enchant.name] then
        return true, enchant
    end

    return false, enchant
end
