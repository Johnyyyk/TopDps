TopDps = TopDps or {}

local addon = TopDps

addon.NAME = "TopDps"
addon.VERSION = "2.0.0"

-- Установите false, чтобы полностью скрыть страницу отладки из настроек интерфейса.
addon.SHOW_DEBUG_OPTIONS = true

addon.Modules = addon.Modules or {}

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
