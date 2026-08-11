local addon = TopDps
local CooldownRegistry = addon:CreateModule("CooldownRegistry")

CooldownRegistry.definitions = CooldownRegistry.definitions or {}
CooldownRegistry.profiles = CooldownRegistry.profiles or {}
CooldownRegistry.profilesByKey = CooldownRegistry.profilesByKey or {}
CooldownRegistry.entriesBySettingId = CooldownRegistry.entriesBySettingId or {}

addon.COOLDOWN_GROUP_OFFENSIVE = "OFFENSIVE"
addon.COOLDOWN_GROUP_DEFENSIVE = "DEFENSIVE"
addon.COOLDOWN_GROUP_UTILITY = "UTILITY"
addon.COOLDOWN_GROUP_STATES = "STATES"
addon.COOLDOWN_GROUP_PROCS = "PROCS"
addon.COOLDOWN_GROUP_RESOURCES = "RESOURCES"
addon.COOLDOWN_GROUP_TRINKETS = "TRINKETS"
addon.COOLDOWN_GROUP_ITEMS = "ITEMS"

addon.COOLDOWN_GROUP_ORDER = {
    [addon.COOLDOWN_GROUP_OFFENSIVE] = 10,
    [addon.COOLDOWN_GROUP_DEFENSIVE] = 20,
    [addon.COOLDOWN_GROUP_UTILITY] = 30,
    [addon.COOLDOWN_GROUP_STATES] = 35,
    [addon.COOLDOWN_GROUP_PROCS] = 40,
    [addon.COOLDOWN_GROUP_RESOURCES] = 50,
    [addon.COOLDOWN_GROUP_TRINKETS] = 60,
    [addon.COOLDOWN_GROUP_ITEMS] = 70,
}

local SUPPORTED_TYPES = {
    spell = true,
    aura = true,
    counter = true,
}

local SUPPORTED_PANEL_CATEGORIES = {
    [addon.PANEL_CATEGORY_BUFFS] = true,
    [addon.PANEL_CATEGORY_PROCS] = true,
    [addon.PANEL_CATEGORY_ABILITIES] = true,
    [addon.PANEL_CATEGORY_COOLDOWNS] = true,
}

local SUPPORTED_PANEL_BEHAVIORS = {
    [addon.PANEL_BEHAVIOR_ALWAYS] = true,
    [addon.PANEL_BEHAVIOR_ACTIVE_ONLY] = true,
    [addon.PANEL_BEHAVIOR_REQUIRED_BUFF] = true,
    [addon.PANEL_BEHAVIOR_SELECTABLE_BUFF] = true,
}

local DEFAULT_PRESENTATION_BY_GROUP = {
    [addon.COOLDOWN_GROUP_OFFENSIVE] = {
        category = addon.PANEL_CATEGORY_COOLDOWNS,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
    [addon.COOLDOWN_GROUP_DEFENSIVE] = {
        category = addon.PANEL_CATEGORY_ABILITIES,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
    [addon.COOLDOWN_GROUP_UTILITY] = {
        category = addon.PANEL_CATEGORY_ABILITIES,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
    [addon.COOLDOWN_GROUP_STATES] = {
        category = addon.PANEL_CATEGORY_ABILITIES,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
    [addon.COOLDOWN_GROUP_PROCS] = {
        category = addon.PANEL_CATEGORY_PROCS,
        behavior = addon.PANEL_BEHAVIOR_ACTIVE_ONLY,
    },
    [addon.COOLDOWN_GROUP_RESOURCES] = {
        category = addon.PANEL_CATEGORY_PROCS,
        behavior = addon.PANEL_BEHAVIOR_ACTIVE_ONLY,
    },
    [addon.COOLDOWN_GROUP_TRINKETS] = {
        category = addon.PANEL_CATEGORY_COOLDOWNS,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
    [addon.COOLDOWN_GROUP_ITEMS] = {
        category = addon.PANEL_CATEGORY_COOLDOWNS,
        behavior = addon.PANEL_BEHAVIOR_ALWAYS,
    },
}

local function GetProfileKey(classToken, talentTab)
    if not classToken or not talentTab then
        return nil
    end

    return tostring(classToken) .. ":" .. tostring(talentTab)
end

local function ValidateSpellEntry(entry)
    if type(entry.spellIds) ~= "table" or #entry.spellIds == 0 then
        error("TopDps: spell panel entry requires spellIds")
    end
end

local function ValidateAuraEntry(entry)
    if type(entry.auraSpellIds) ~= "table" or #entry.auraSpellIds == 0 then
        error("TopDps: aura panel entry requires auraSpellIds")
    end
end

local function ValidateCounterEntry(entry)
    if type(entry.getValue) ~= "function" then
        error("TopDps: counter panel entry requires getValue")
    end
end

local function ResolveDefaultPresentation(group)
    return DEFAULT_PRESENTATION_BY_GROUP[group]
        or {
            category = addon.PANEL_CATEGORY_ABILITIES,
            behavior = addon.PANEL_BEHAVIOR_ALWAYS,
        }
end

local function ValidateEntry(definition, entry)
    if type(entry) ~= "table" then
        error("TopDps: panel entry must be a table")
    end

    if type(entry.id) ~= "string" or entry.id == "" then
        error("TopDps: panel entry id must be a non-empty string")
    end

    if not SUPPORTED_TYPES[entry.type] then
        error("TopDps: unsupported panel entry type: " .. tostring(entry.type))
    end

    if entry.type == "spell" then
        ValidateSpellEntry(entry)
    elseif entry.type == "aura" then
        ValidateAuraEntry(entry)
    elseif entry.type == "counter" then
        ValidateCounterEntry(entry)
    end

    entry.classToken = definition.classToken
    entry.talentTab = definition.talentTab
    entry.group = entry.group or addon.COOLDOWN_GROUP_UTILITY
    entry.order = tonumber(entry.order) or 100
    entry.defaultEnabled = entry.defaultEnabled ~= false
    entry.settingId = definition.classToken .. ":" .. (definition.talentTab or "ALL") .. ":" .. entry.id

    local defaultPresentation = ResolveDefaultPresentation(entry.group)
    entry.panelCategory = entry.panelCategory or defaultPresentation.category
    entry.panelBehavior = entry.panelBehavior or defaultPresentation.behavior

    if not SUPPORTED_PANEL_CATEGORIES[entry.panelCategory] then
        error("TopDps: unsupported panel category: " .. tostring(entry.panelCategory))
    end

    if not SUPPORTED_PANEL_BEHAVIORS[entry.panelBehavior] then
        error("TopDps: unsupported panel behavior: " .. tostring(entry.panelBehavior))
    end
end

function CooldownRegistry:RegisterProfile(profile)
    if type(profile) ~= "table" then
        error("TopDps: panel profile must be a table")
    end

    if type(profile.classToken) ~= "string" or profile.classToken == "" then
        error("TopDps: panel profile requires classToken")
    end

    profile.talentTab = tonumber(profile.talentTab)
    if not profile.talentTab then
        error("TopDps: panel profile requires talentTab")
    end

    profile.key = GetProfileKey(profile.classToken, profile.talentTab)
    if self.profilesByKey[profile.key] then
        error("TopDps: duplicate panel profile: " .. profile.key)
    end

    self.profilesByKey[profile.key] = profile
    table.insert(self.profiles, profile)
end

function CooldownRegistry:GetProfiles()
    local result = {}
    local index

    for index = 1, #self.profiles do
        result[index] = self.profiles[index]
    end

    table.sort(result, function(left, right)
        if left.classToken ~= right.classToken then
            return left.classToken < right.classToken
        end

        return left.talentTab < right.talentTab
    end)

    return result
end

function CooldownRegistry:GetProfile(classToken, talentTab)
    return self.profilesByKey[GetProfileKey(classToken, talentTab)]
end

function CooldownRegistry:GetProfileByKey(key)
    return self.profilesByKey[key]
end

function CooldownRegistry:GetProfileDisplayName(profile)
    if not profile then
        return nil
    end

    if profile.labelKey and addon.L[profile.labelKey] then
        return addon.L[profile.labelKey]
    end

    return profile.label or profile.key
end

function CooldownRegistry:Register(definition)
    if type(definition) ~= "table" then
        error("TopDps: panel definition must be a table")
    end

    if type(definition.classToken) ~= "string" or definition.classToken == "" then
        error("TopDps: panel definition requires classToken")
    end

    if definition.talentTab ~= nil then
        definition.talentTab = tonumber(definition.talentTab)
        if not definition.talentTab then
            error("TopDps: panel definition talentTab must be numeric")
        end
    end

    local entries = definition.entries or {}
    local index
    for index = 1, #entries do
        ValidateEntry(definition, entries[index])

        if self.entriesBySettingId[entries[index].settingId] then
            error("TopDps: duplicate panel entry: " .. entries[index].settingId)
        end

        self.entriesBySettingId[entries[index].settingId] = entries[index]
    end

    table.insert(self.definitions, definition)
end

function CooldownRegistry:GetPanelPresentation(entry)
    if not entry then
        return addon.PANEL_CATEGORY_ABILITIES, addon.PANEL_BEHAVIOR_ALWAYS
    end

    local definition = entry.settingId and self.entriesBySettingId[entry.settingId] or nil
    if definition then
        return definition.panelCategory, definition.panelBehavior
    end

    local defaultPresentation = ResolveDefaultPresentation(entry.group)
    return defaultPresentation.category, defaultPresentation.behavior
end

function CooldownRegistry:GetEntries(classToken, talentTab)
    local result = {}
    local definitionIndex

    for definitionIndex = 1, #self.definitions do
        local definition = self.definitions[definitionIndex]
        if definition.classToken == classToken
            and (not definition.talentTab or definition.talentTab == talentTab) then
            local entryIndex
            for entryIndex = 1, #(definition.entries or {}) do
                table.insert(result, definition.entries[entryIndex])
            end
        end
    end

    table.sort(result, function(left, right)
        local leftGroup = addon.COOLDOWN_GROUP_ORDER[left.group] or 100
        local rightGroup = addon.COOLDOWN_GROUP_ORDER[right.group] or 100
        if leftGroup ~= rightGroup then
            return leftGroup < rightGroup
        end

        if left.order ~= right.order then
            return left.order < right.order
        end

        return left.settingId < right.settingId
    end)

    return result
end
