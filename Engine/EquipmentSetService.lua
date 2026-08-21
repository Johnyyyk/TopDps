local addon = TopDps
local EquipmentSetService = addon:CreateModule("EquipmentSetService")

local DEFAULT_EQUIPMENT_SLOTS = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19,
}

local function BuildItemSet(itemIds)
    local result = {}
    if type(itemIds) ~= "table" then
        return result
    end

    local key
    local value
    for key, value in pairs(itemIds) do
        if type(key) == "number" and value == true then
            result[key] = true
        elseif type(value) == "number" then
            result[value] = true
        end
    end

    return result
end

function EquipmentSetService:GetEquippedMatches(itemIds, slots)
    local wanted = BuildItemSet(itemIds)
    local checkedSlots = slots or DEFAULT_EQUIPMENT_SLOTS
    local result = {}
    local index

    for index = 1, #checkedSlots do
        local slot = checkedSlots[index]
        local itemId = addon.GameApi:GetInventoryItemId(slot)
        if itemId and wanted[itemId] then
            result[#result + 1] = {
                slot = slot,
                itemId = itemId,
            }
        end
    end

    return result
end

function EquipmentSetService:CountEquipped(itemIds, slots)
    return #self:GetEquippedMatches(itemIds, slots)
end

function EquipmentSetService:HasEquippedCount(itemIds, requiredCount, slots)
    local minimum = math.max(0, tonumber(requiredCount) or 0)
    return self:CountEquipped(itemIds, slots) >= minimum
end
