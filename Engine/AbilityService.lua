local addon = TopDps
local AbilityService = addon:CreateModule("AbilityService")

AbilityService.catalogByProvider = AbilityService.catalogByProvider or {}

local function AddEntry(entriesByCategory, entryIndexByKey, category, spellId, spellName, spellBookIndex)
    if not category or not spellName then
        return
    end

    local entries = entriesByCategory[category]
    if not entries then
        entries = {}
        entriesByCategory[category] = entries
        entryIndexByKey[category] = {}
    end

    local key = spellName
    local index = entryIndexByKey[category][key]
    local entry = {
        spellId = spellId,
        spellName = spellName,
        spellBookIndex = spellBookIndex,
    }

    if index then
        -- Если клиент показывает несколько рангов одного заклинания,
        -- последний spellbook slot соответствует наиболее актуальному рангу.
        entries[index] = entry
        return
    end

    table.insert(entries, entry)
    entryIndexByKey[category][key] = #entries
end

local function IsKnownSpell(spellId)
    if not IsSpellKnown or not spellId then
        return false
    end

    local ok, known = pcall(IsSpellKnown, spellId)
    return ok and (known == true or known == 1)
end

function AbilityService:BuildCatalog(provider)
    local entriesByCategory = {}
    local entryIndexByKey = {}

    if not provider then
        return entriesByCategory
    end

    local spellbookScanned = false
    if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo and GetSpellInfo then
        local ok, tabCount = pcall(GetNumSpellTabs)
        if ok and type(tabCount) == "number" then
            spellbookScanned = true
            local bookType = BOOKTYPE_SPELL or "spell"
            local tabIndex

            for tabIndex = 1, tabCount do
                local tabOk, _, _, offset, numSlots = pcall(GetSpellTabInfo, tabIndex)
                if tabOk then
                    offset = tonumber(offset) or 0
                    numSlots = tonumber(numSlots) or 0

                    local spellBookIndex
                    for spellBookIndex = offset + 1, offset + numSlots do
                        local itemOk, spellType, spellId = pcall(GetSpellBookItemInfo, spellBookIndex, bookType)
                        if itemOk and spellType == "SPELL" and spellId then
                            local spellName = GetSpellInfo(spellId)
                            local category = provider:GetSpellCategory(spellId, spellName)
                            AddEntry(
                                entriesByCategory,
                                entryIndexByKey,
                                category,
                                spellId,
                                spellName,
                                spellBookIndex
                            )
                        end
                    end
                end
            end
        end
    end

    -- Основной путь для 3.3.5a — spellbook scan: он сразу даёт фактически
    -- изученный rank, даже когда provider хранит только базовый spell ID.
    -- Fallback нужен для нестандартных cores с неполным spellbook API.
    local categories = provider.categories or {}
    local abilities = provider.abilities or {}
    local categoryIndex

    for categoryIndex = 1, #categories do
        local category = categories[categoryIndex]
        if not entriesByCategory[category] then
            local ability = abilities[category]
            local spellIds = ability and ability.spellIds or nil
            local spellIndex

            for spellIndex = 1, #(spellIds or {}) do
                local spellId = spellIds[spellIndex]
                if IsKnownSpell(spellId) then
                    local spellName = GetSpellInfo and GetSpellInfo(spellId) or nil
                    AddEntry(entriesByCategory, entryIndexByKey, category, spellId, spellName, nil)
                end
            end
        end
    end

    -- Не считаем отсутствие spellbook entries ошибкой: на низком уровне
    -- provider вполне может не иметь ни одной изученной ротационной способности.
    self.catalogByProvider[provider] = entriesByCategory
    return entriesByCategory, spellbookScanned
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
