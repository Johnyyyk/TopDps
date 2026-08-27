local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected=" .. tostring(expected) .. ", actual=" .. tostring(actual))
    end
end

local function NewAddon()
    local addon = {
        Modules = {},
    }

    function addon:CreateModule(name)
        local module = self.Modules[name]
        if module then
            return module
        end

        module = {}
        self.Modules[name] = module
        self[name] = module
        return module
    end

    return addon
end

TopDps = NewAddon()
TopDps.REFRESH_LEAD_CAST_TIME = "CAST_TIME"
TopDps.SpecProvider = {}
TopDps.SpecRegistry = {
    providers = {},
}

function TopDps.SpecProvider:Create(definition)
    definition.testSettings = {
        curseMode = "auto",
        useMovementPriority = true,
    }

    function definition:GetSetting(key)
        return self.testSettings[key]
    end

    return definition
end

function TopDps.SpecRegistry:Register(provider)
    self.providers[provider.id] = provider
end

dofile("Specs/Warlock/Common.lua")

local Warlock = TopDps.Warlock
local backlashActive = false

Warlock.HasPlayerAura = function(_, spellIds)
    return spellIds and spellIds[1] == 34936 and backlashActive
end
Warlock.HasOwnTargetAura = function()
    return false
end
Warlock.GetCommonCategoryAllowed = function()
    return nil
end

dofile("Specs/Warlock/Destruction.lua")

local Destruction = TopDps.SpecRegistry.providers.WARLOCK_DESTRUCTION
local movingContext = {
    player = {
        movement = {
            moving = true,
        },
    },
}

local priority = Destruction:GetPriority(movingContext)
AssertEqual(priority[4], "incinerate", "Backlash-capable Incinerate must be present in movement priority")

backlashActive = false
AssertEqual(
    Destruction:IsCategoryAllowed("incinerate", movingContext),
    false,
    "moving Incinerate must be blocked without Backlash"
)

backlashActive = true
AssertEqual(
    Destruction:IsCategoryAllowed("incinerate", movingContext),
    true,
    "moving Incinerate must be allowed with Backlash"
)

Destruction.testSettings.useMovementPriority = false
backlashActive = false
AssertEqual(
    Destruction:IsCategoryAllowed("incinerate", movingContext),
    true,
    "disabled movement priority must preserve normal Incinerate behavior"
)

print("movement Backlash smoke tests passed")
