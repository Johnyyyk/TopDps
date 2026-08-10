local addon = TopDps
local CooldownRegistry = addon:CreateModule("CooldownRegistry")

CooldownRegistry.definitions = CooldownRegistry.definitions or {}

addon.COOLDOWN_GROUP_OFFENSIVE = "OFFENSIVE"
addon.COOLDOWN_GROUP_DEFENSIVE = "DEFENSIVE"
addon.COOLDOWN_GROUP_UTILITY = "UTILITY"
addon.COOLDOWN_GROUP_PROCS = "PROCS"
addon.COOLDOWN_GROUP_RESOURCES = "RESOURCES"
addon.COOLDOWN_GROUP_TRINKETS = "TRINKETS"
addon.COOLDOWN_GROUP_ITEMS = "ITEMS"

addon.COOLDOWN_GROUP_ORDER = {
    [addon.COOLDOWN_GROUP_OFFENSIVE] = 10,
    [addon.COOLDOWN_GROUP_DEFENSIVE] = 20,
    [addon.COOLDOWN_GROUP_UTILITY] = 30,
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

local function ValidateSpellEntry(entry)
    if type(entry.spellIds) ~= "table" or #entry.spellIds == 0 then
        error("TopDps: spell cooldown entry requires spellIds")
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
    entry.specId = definition.specId
    entry.group = entry.group or addon.COOLDOWN_GROUP_UTILITY
    entry.order = tonumber(entry.order) or 100
    entry.defaultEnabled = entry.defaultEnabled ~= false
    entry.settingId = definition.classToken .. ":" .. (definition.specId or "ALL") .. ":" .. entry.id
end

function CooldownRegistry:Register(definition)
    if type(definition) ~= "table" then
        error("TopDps: panel definition must be a table")
    end

    if type(definition.classToken) ~= "string" or definition.classToken == "" then
        error("TopDps: panel definition requires classToken")
    end

    local entries = definition.entries or {}
    local index
    for index = 1, #entries do
        ValidateEntry(definition, entries[index])
    end

    table.insert(self.definitions, definition)
end

function CooldownRegistry:GetEntries(classToken, specId)
    local result = {}
    local definitionIndex

    for definitionIndex = 1, #self.definitions do
        local definition = self.definitions[definitionIndex]
        if definition.classToken == classToken
            and (not definition.specId or definition.specId == specId) then
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
