local addon = TopDps
local AbilityService = addon:CreateModule("AbilityService")

AbilityService.catalogByProvider = AbilityService.catalogByProvider or {}

local function GetSpellIdFromLink(link)
    if type(link) ~= "string" then
        return nil
    end

    return tonumber(string.match(link, "Hspell:(%d+)"))
end

local function ResolveKnownSpell(spellId)
    if not spellId or not GetSpellInfo then
        return nil, nil
    end

    local ok, spellName = pcall(GetSpellInfo, spellId)
    if not ok or not spellName then
        return nil, nil
    end

    -- В 3.3.5a GetSpellBookItemInfo ещё нет. GetSpellLink(name), напротив,
    -- существует с TBC и по имени возвращает ссылку только для заклинания,
    -- которое находится в spellbook. Из ссылки заодно получаем фактически
    -- изученный rank, даже когда provider хранит только базовый spell ID.
    if GetSpellLink then
        local linkOk, link, linkedSpellId = pcall(GetSpellLink, spellName)
        if linkOk and link then
            return tonumber(linkedSpellId) or GetSpellIdFromLink(link) or spellId, spellName
        end
    end

    -- Fallback для нестандартных 3.3.5 cores. Проверка по имени важнее
    -- IsSpellKnown(baseRank): provider часто хранит только ID первого ранга.
    local knownOk, knownName = pcall(GetSpellInfo, spellName)
    if knownOk and knownName then
        return spellId, spellName
    end

    if IsSpellKnown then
        local isKnownOk, known = pcall(IsSpellKnown, spellId)
        if isKnownOk and (known == true or known == 1) then
            return spellId, spellName
        end
    end

    return nil, nil
end

local function AddEntry(entriesByCategory, entryIndexByKey, category, spellId, spellName)
    if not category or not spellName then
        return
    end

    local entries = entriesByCategory[category]
    if not entries then
        entries = {}
        entriesByCategory[category] = entries
        entryIndexByKey[category] = {}
    end

    local index = entryIndexByKey[category][spellName]
    local entry = {
        spellId = spellId,
        spellName = spellName,
    }

    if index then
        entries[index] = entry
        return
    end

    table.insert(entries, entry)
    entryIndexByKey[category][spellName] = #entries
end

function AbilityService:BuildCatalog(provider)
    local entriesByCategory = {}
    local entryIndexByKey = {}

    if not provider then
        return entriesByCategory
    end

    local categories = provider.categories or {}
    local abilities = provider.abilities or {}
    local categoryIndex

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        local ability = abilities[category]
        local spellIds = ability and ability.spellIds or nil
        local spellIndex

        for spellIndex = 1, #(spellIds or {}) do
            local spellId, spellName = ResolveKnownSpell(spellIds[spellIndex])
            AddEntry(entriesByCategory, entryIndexByKey, category, spellId, spellName)
        end
    end

    self.catalogByProvider[provider] = entriesByCategory
    return entriesByCategory
end

function AbilityService:Refresh(provider)
    if not provider then
        return {}
    end

    return self:BuildCatalog(provider)
end

function AbilityService:GetAbilities(provider)
    if not provider then
        return {}
    end

    local catalog = self.catalogByProvider[provider]
    if not catalog then
        catalog = self:BuildCatalog(provider)
    end

    return catalog
end

function AbilityService:BuildAbilitySummary(provider, abilitiesByCategory)
    local parts = {}
    local categories = provider and (provider.debugCategories or provider.categories) or {}
    local index

    for index = 1, #categories do
        local category = categories[index]
        local entries = abilitiesByCategory and abilitiesByCategory[category] or nil
        local count = entries and #entries or 0
        local first = entries and entries[1]
        local suffix = ""

        if first then
            suffix = "(" .. tostring(first.spellId or first.spellName or "?") .. ")"
        end

        table.insert(parts, category .. "=" .. tostring(count) .. suffix)
    end

    return table.concat(parts, ", ")
end
