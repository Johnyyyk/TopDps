local addon = TopDps
local GameApi = addon:CreateModule("GameApi")

local function GetTalentInfoData(tabIndex, talentIndex, talentGroup)
    local ok, name, _, _, _, rank

    if talentGroup then
        ok, name, _, _, _, rank = pcall(GetTalentInfo, tabIndex, talentIndex, false, false, talentGroup)
        if ok and name then
            return name, tonumber(rank) or 0
        end
    end

    ok, name, _, _, _, rank = pcall(GetTalentInfo, tabIndex, talentIndex, false, false)
    if ok and name then
        return name, tonumber(rank) or 0
    end

    ok, name, _, _, _, rank = pcall(GetTalentInfo, tabIndex, talentIndex, false)
    if ok and name then
        return name, tonumber(rank) or 0
    end

    return nil, 0
end

function GameApi:GetInventoryItemId(slot)
    if GetInventoryItemID then
        return GetInventoryItemID("player", slot)
    end

    local link = GetInventoryItemLink("player", slot)
    if not link then
        return nil
    end

    return tonumber(string.match(link, "item:(%d+)"))
end

function GameApi:GetActiveTalentGroup()
    if not GetActiveTalentGroup then
        return nil
    end

    local ok, group = pcall(GetActiveTalentGroup)
    if ok then
        return group
    end

    return nil
end

function GameApi:GetTalentPoints(tabIndex, talentGroup)
    if not GetTalentTabInfo then
        return nil
    end

    local tabPoints

    if talentGroup then
        local ok, _, _, points = pcall(GetTalentTabInfo, tabIndex, false, false, talentGroup)
        if ok and type(points) == "number" then
            tabPoints = points
        end
    end

    if tabPoints == nil then
        local ok, _, _, points = pcall(GetTalentTabInfo, tabIndex, false, false)
        if ok and type(points) == "number" then
            tabPoints = points
        end
    end

    if tabPoints == nil then
        local ok, _, _, points = pcall(GetTalentTabInfo, tabIndex, false)
        if ok and type(points) == "number" then
            tabPoints = points
        end
    end

    if tabPoints and tabPoints > 0 then
        return tabPoints
    end

    if not GetTalentInfo then
        return tabPoints
    end

    local maxTalents = 30
    if GetNumTalents then
        local ok, count = pcall(GetNumTalents, tabIndex, false, false)
        if ok and type(count) == "number" and count > 0 then
            maxTalents = count
        end
    end

    local totalPoints = 0
    local talentIndex
    for talentIndex = 1, maxTalents do
        local name, rank = GetTalentInfoData(tabIndex, talentIndex, talentGroup)
        if name then
            totalPoints = totalPoints + rank
        end
    end

    if totalPoints > 0 then
        return totalPoints
    end

    return tabPoints
end

function GameApi:GetTalentRankByName(tabIndex, talentName)
    if not talentName or not GetTalentInfo then
        return 0
    end

    local talentGroup = self:GetActiveTalentGroup()
    local maxTalents = 30

    if GetNumTalents then
        local ok, count = pcall(GetNumTalents, tabIndex, false, false)
        if ok and type(count) == "number" and count > 0 then
            maxTalents = count
        end
    end

    local index
    for index = 1, maxTalents do
        local name, rank = GetTalentInfoData(tabIndex, index, talentGroup)
        if name == talentName then
            return rank
        end
    end

    return 0
end

function GameApi:GetSpellCastTime(spell)
    if not GetSpellInfo or not spell then
        return 0
    end

    local ok, _, _, _, _, _, _, castTime = pcall(GetSpellInfo, spell)
    if not ok then
        return 0
    end

    return math.max(0, (tonumber(castTime) or 0) / 1000)
end

local function MatchesGlyphSpell(spellIds, ...)
    local valueCount = select("#", ...)
    local valueIndex
    local spellIndex

    for valueIndex = 1, valueCount do
        local value = tonumber((select(valueIndex, ...)))
        if value then
            for spellIndex = 1, #spellIds do
                if value == spellIds[spellIndex] then
                    return true
                end
            end
        end
    end

    return false
end

local function ReadGlyphSocket(slot, talentGroup)
    if talentGroup then
        local ok, first, second, third, fourth, fifth = pcall(GetGlyphSocketInfo, slot, talentGroup)
        if ok then
            return true, first, second, third, fourth, fifth
        end
    end

    local ok, first, second, third, fourth, fifth = pcall(GetGlyphSocketInfo, slot)
    if ok then
        return true, first, second, third, fourth, fifth
    end

    return false
end

function GameApi:HasGlyphSpell(spellIds)
    if not GetGlyphSocketInfo or type(spellIds) ~= "table" or #spellIds == 0 then
        return false
    end

    local socketCount = 6
    if GetNumGlyphSockets then
        local ok, count = pcall(GetNumGlyphSockets)
        if ok and type(count) == "number" and count > 0 then
            socketCount = count
        end
    elseif NUM_GLYPH_SLOTS and NUM_GLYPH_SLOTS > 0 then
        socketCount = NUM_GLYPH_SLOTS
    end

    local talentGroup = self:GetActiveTalentGroup()
    local slot
    for slot = 1, socketCount do
        local ok, first, second, third, fourth, fifth = ReadGlyphSocket(slot, talentGroup)
        if ok and MatchesGlyphSpell(spellIds, first, second, third, fourth, fifth) then
            return true
        end
    end

    return false
end

function GameApi:GetActionSpellData(action)
    -- На 3.3.5 четвёртое значение GetActionInfo содержит global spell ID.
    -- Второе значение на части клиентов является индексом spellbook.
    local actionType, id, _, globalId = GetActionInfo(action)
    if actionType == "spell" then
        local spellId = tonumber(globalId)
        if not spellId or spellId <= 0 then
            spellId = tonumber(id)
        end

        local name
        if spellId then
            name = GetSpellInfo(spellId)
        end

        if not name and id and GetSpellName then
            name = GetSpellName(id, BOOKTYPE_SPELL)
        end

        return spellId, name
    end

    if actionType == "macro" and id and GetMacroSpell then
        local first, second, third = GetMacroSpell(id)
        if type(first) == "number" then
            return first, GetSpellInfo(first)
        end

        if type(third) == "number" then
            return third, GetSpellInfo(third)
        end

        if type(first) == "string" and first ~= "" then
            return nil, first
        end

        if type(second) == "string" and second ~= "" then
            return nil, second
        end
    end

    return nil, nil
end

function GameApi:GetActionSpellName(action)
    local _, spellName = self:GetActionSpellData(action)
    return spellName
end

function GameApi:GetButtonAction(button)
    if ActionButton_CalculateAction then
        local ok, action = pcall(ActionButton_CalculateAction, button)
        if ok and action then
            return action
        end
    end

    if button.action then
        return button.action
    end

    if ActionButton_GetPagedID then
        local ok, action = pcall(ActionButton_GetPagedID, button)
        if ok and action then
            return action
        end
    end

    if button.GetAttribute then
        local action = button:GetAttribute("action")
        if action then
            return action
        end
    end

    return nil
end
