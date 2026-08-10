local addon = TopDps
local OptionsController = addon:CreateModule("OptionsController")

function OptionsController:Initialize()
    addon.GeneralOptions:Create()
    addon.RotationOptions:Create()
    addon.CooldownOptions:Create()

    if addon.SHOW_DEBUG_OPTIONS then
        addon.DebugOptions:Create()
    end
end

function OptionsController:Refresh()
    if addon.GeneralOptions then
        addon.GeneralOptions:Refresh()
    end

    if addon.RotationOptions then
        addon.RotationOptions:Refresh()
    end

    if addon.CooldownOptions then
        addon.CooldownOptions:Refresh()
    end

    if addon.SHOW_DEBUG_OPTIONS and addon.DebugOptions then
        addon.DebugOptions:Refresh()
    end
end

function OptionsController:Open()
    if not addon.GeneralOptions.panel then
        return
    end

    -- Реализации Interface Options в 3.3.5 требуется два вызова при открытии
    -- категории извне окна настроек.
    InterfaceOptionsFrame_OpenToCategory(addon.GeneralOptions.panel)
    InterfaceOptionsFrame_OpenToCategory(addon.GeneralOptions.panel)
end
