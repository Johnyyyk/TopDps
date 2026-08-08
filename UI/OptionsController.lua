local addon = RpalTopDps
local OptionsController = addon:CreateModule("OptionsController")

function OptionsController:Initialize()
    addon.GeneralOptions:Create()

    if addon.SHOW_DEBUG_OPTIONS then
        addon.DebugOptions:Create()
    end
end

function OptionsController:Refresh()
    if addon.GeneralOptions then
        addon.GeneralOptions:Refresh()
    end

    if addon.SHOW_DEBUG_OPTIONS and addon.DebugOptions then
        addon.DebugOptions:Refresh()
    end
end

function OptionsController:Open()
    if not addon.GeneralOptions.panel then
        return
    end

    -- Calling twice is required by the 3.3.5 Interface Options implementation
    -- when opening a category directly from outside the options frame.
    InterfaceOptionsFrame_OpenToCategory(addon.GeneralOptions.panel)
    InterfaceOptionsFrame_OpenToCategory(addon.GeneralOptions.panel)
end
