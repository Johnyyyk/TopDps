local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

TopDps = {
    CooldownPanel = {
        WARNING_GROUP = "WARNING",
    },
    Settings = {},
    CooldownRegistry = {},
    db = {
        panel = {
            locked = true,
        },
    },
}

function TopDps.Settings:IsCooldownPanelCategoryEnabled()
    return true
end

function TopDps.CooldownRegistry:IsEntryApplicable()
    return true
end

dofile("Core/Constants.lua")

function TopDps.CooldownPanel:GetPresentation(entry)
    return entry.panelCategory, entry.panelBehavior
end

function TopDps.CooldownPanel:IsActiveState(state)
    return state and state.state == "ACTIVE"
end

dofile("Presentation/CooldownPanelLayout.lua")
dofile("Presentation/CooldownPanelState.lua")

local panel = TopDps.CooldownPanel
local inactive = { state = "INACTIVE" }
local active = { state = "ACTIVE" }

local optionalRaidBuff = {
    panelCategory = TopDps.PANEL_CATEGORY_BUFFS,
    panelBehavior = TopDps.PANEL_BEHAVIOR_ACTIVE_ONLY,
}

AssertEqual(
    panel:IsMissingRequirement(optionalRaidBuff, inactive),
    false,
    "inactive optional raid buff is not a missing requirement"
)
AssertEqual(
    panel:IsEntryVisible(optionalRaidBuff, inactive, false),
    false,
    "inactive optional raid buff is hidden"
)
AssertEqual(
    panel:IsEntryVisible(optionalRaidBuff, active, false),
    true,
    "active optional raid buff is visible"
)

local selectableRequiredBuff = {
    panelCategory = TopDps.PANEL_CATEGORY_BUFFS,
    panelBehavior = TopDps.PANEL_BEHAVIOR_SELECTABLE_BUFF,
}

AssertEqual(
    panel:IsMissingRequirement(selectableRequiredBuff, inactive),
    true,
    "missing selectable buff remains a requirement"
)
AssertEqual(
    panel:IsEntryVisible(selectableRequiredBuff, inactive, false),
    true,
    "missing selectable buff remains visible as warning"
)
AssertEqual(
    panel:ResolveVisualGroup(selectableRequiredBuff, inactive, false),
    panel.WARNING_GROUP,
    "missing selectable buff uses warning group"
)

local requiredBuff = {
    panelCategory = TopDps.PANEL_CATEGORY_BUFFS,
    panelBehavior = TopDps.PANEL_BEHAVIOR_REQUIRED_BUFF,
}

AssertEqual(
    panel:IsMissingRequirement(requiredBuff, inactive),
    true,
    "missing required buff remains a requirement"
)
AssertEqual(
    panel:IsEntryVisible(requiredBuff, active, false),
    false,
    "satisfied required buff stays hidden in locked mode"
)

print("panel buff semantics regression tests passed")
